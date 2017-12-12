package AnyEvent::Filesys::Notify;

# ABSTRACT: An AnyEvent compatible module to monitor files/directories for changes

use Moo;
use Moo::Role ();
use MooX::late;
use namespace::autoclean;
use AnyEvent;
use Path::Iterator::Rule;
use Cwd qw/abs_path/;
use AnyEvent::Filesys::Notify::Event;
use Carp;
use Try::Tiny;

our $VERSION = '1.23';
my $AEFN = 'AnyEvent::Filesys::Notify';

has dirs         => ( is => 'ro', isa => 'ArrayRef[Str]', required => 1 );
has cb           => ( is => 'rw', isa => 'CodeRef',       required => 1 );
has interval     => ( is => 'ro', isa => 'Num',           default  => 2 );
has no_external  => ( is => 'ro', isa => 'Bool',          default  => 0 );
has backend      => ( is => 'ro', isa => 'Str',           default  => '' );
has filter       => ( is => 'rw', isa => 'RegexpRef|CodeRef' );
has parse_events => ( is => 'rw', isa => 'Bool',          default  => 0 );
has skip_subdirs => ( is => 'ro', isa => 'Bool',          default  => 0 );
has _fs_monitor  => ( is => 'rw', );
has _old_fs => ( is => 'rw', isa => 'HashRef' );
has _watcher => ( is => 'rw', );

sub BUILD {
    my $self = shift;

    $self->_old_fs( $self->_scan_fs( $self->dirs ) );

    $self->_load_backend;
    return $self->_init;    # initialize the backend
}

sub _process_events {
    my ( $self, @raw_events ) = @_;

    # Some implementations provided enough information to parse the raw events,
    # other require rescanning the file system (ie, Mac::FSEvents).
    # The original behavior was to rescan in all implementations, so we
    # have added a flag to avoid breaking old code.

    my @events;

    if ( $self->parse_events and $self->can('_parse_events') ) {
        @events =
          $self->_parse_events( sub { $self->_apply_filter(@_) }, @raw_events );
    } else {
        my $new_fs = $self->_scan_fs( $self->dirs );
        @events =
          $self->_apply_filter( $self->_diff_fs( $self->_old_fs, $new_fs ) );
        $self->_old_fs($new_fs);

        # Some backends (when not using parse_events) need to add files
        # (KQueue) or directories (Inotify2) to the watch list after they are
        # created. Give them a chance to do that here.
        $self->_post_process_events(@events)
          if $self->can('_post_process_events');
    }

    $self->cb->(@events) if @events;

    return \@events;
}

sub _apply_filter {
    my ( $self, @events ) = @_;

    if ( ref $self->filter eq 'CODE' ) {
        my $cb = $self->filter;
        @events = grep { $cb->( $_->path ) } @events;
    } elsif ( ref $self->filter eq 'Regexp' ) {
        my $re = $self->filter;
        @events = grep { $_->path =~ $re } @events;
    }

    return @events;
}

# Return a hash ref representing all the files and stats in @path.
# Keys are absolute path and values are path/mtime/size/is_dir
# Takes either array or arrayref
sub _scan_fs {
    my ( $self, @args ) = @_;

    # Accept either an array of dirs or a array ref of dirs
    my @paths = ref $args[0] eq 'ARRAY' ? @{ $args[0] } : @args;

    my $fs_stats = {};

    my $rule = Path::Iterator::Rule->new;
    $rule->skip_subdirs(qr/./)
        if (ref $self) =~ /^AnyEvent::Filesys::Notify/
        && $self->skip_subdirs;
    my $next = $rule->iter(@paths);
    while ( my $file = $next->() ) {
        my $stat = $self->_stat($file)
          or next; # Skip files that we can't stat (ie, broken symlinks on ext4)
        $fs_stats->{ abs_path($file) } = $stat;
    }

    return $fs_stats;
}

sub _diff_fs {
    my ( $self, $old_fs, $new_fs ) = @_;
    my @events = ();

    for my $path ( keys %$old_fs ) {
        if ( not exists $new_fs->{$path} ) {
            push @events,
              AnyEvent::Filesys::Notify::Event->new(
                path   => $path,
                type   => 'deleted',
                is_dir => $old_fs->{$path}->{is_dir},
              );
        } elsif (
            $self->_is_path_modified( $old_fs->{$path}, $new_fs->{$path} ) )
        {
            push @events,
              AnyEvent::Filesys::Notify::Event->new(
                path   => $path,
                type   => 'modified',
                is_dir => $old_fs->{$path}->{is_dir},
              );
        }
    }

    for my $path ( keys %$new_fs ) {
        if ( not exists $old_fs->{$path} ) {
            push @events,
              AnyEvent::Filesys::Notify::Event->new(
                path   => $path,
                type   => 'created',
                is_dir => $new_fs->{$path}->{is_dir},
              );
        }
    }

    return @events;
}

sub _is_path_modified {
    my ( $self, $old_path, $new_path ) = @_;

    return 1 if $new_path->{mode} != $old_path->{mode};
    return   if $new_path->{is_dir};
    return 1 if $new_path->{mtime} != $old_path->{mtime};
    return 1 if $new_path->{size} != $old_path->{size};
    return;
}

# Originally taken from Filesys::Notify::Simple --Thanks Miyagawa
sub _stat {
    my ( $self, $path ) = @_;

    my @stat = stat $path;

    # Return undefined if no stats can be retrieved, as it happens with broken
    # symlinks (at least under ext4).
    return unless @stat;

    return {
        path   => $path,
        mtime  => $stat[9],
        size   => $stat[7],
        mode   => $stat[2],
        is_dir => -d _,
    };

}

# Figure out which backend to use:
# I would prefer this to be done at compile time not object build, but I also
# want the user to be able to force the Fallback role. Something like an
# import flag would be great, but Moose creates an import sub for us and
# I'm not sure how to cleanly do it. Maybe need to use traits, but the
# documentation suggests traits are for application of roles by object.
# This will work for now.
sub _load_backend {
    my $self = shift;

    if ( $self->backend ) {

        # Use the AEFN::Role prefix unless the backend starts with a +
        my $prefix  = "${AEFN}::Role::";
        my $backend = $self->backend;
        $backend = $prefix . $backend unless $backend =~ s{^\+}{};

        try { Moo::Role->apply_roles_to_object( $self, $backend ); }
        catch {
            croak "Unable to load the specified backend ($backend). You may "
              . "need to install Linux::INotify2, Mac::FSEvents or IO::KQueue:"
              . "\n$_";
        }
    } elsif ( $self->no_external ) {
        Moo::Role->apply_roles_to_object( $self, "${AEFN}::Role::Fallback" );
    } elsif ( $^O eq 'linux' ) {
        try {
            Moo::Role->apply_roles_to_object( $self,
                "${AEFN}::Role::Inotify2" );
        }
        catch {
            croak "Unable to load the Linux plugin. You may want to install "
              . "Linux::INotify2 or specify 'no_external' (but that is very "
              . "inefficient):\n$_";
        }
    } elsif ( $^O eq 'darwin' ) {
        try {
            Moo::Role->apply_roles_to_object( $self,
                "${AEFN}::Role::FSEvents" );
        }
        catch {
            croak "Unable to load the Mac plugin. You may want to install "
              . "Mac::FSEvents or specify 'no_external' (but that is very "
              . "inefficient):\n$_";
        }
    } elsif ( $^O =~ /bsd/ ) {
        try {
            Moo::Role->apply_roles_to_object( $self, "${AEFN}::Role::KQueue" );
        }
        catch {
            croak "Unable to load the BSD plugin. You may want to install "
              . "IO::KQueue or specify 'no_external' (but that is very "
              . "inefficient):\n$_";
        }
    } else {
        Moo::Role->apply_roles_to_object( $self, "${AEFN}::Role::Fallback" );
    }

    return 1;
}

1;

__END__

=pod

=head1 NAME

AnyEvent::Filesys::Notify - An AnyEvent compatible module to monitor files/directories for changes

=head1 VERSION

version 1.23

=head1 STATUS

=for html <img src="https://travis-ci.org/mvgrimes/AnyEvent-Filesys-Notify.svg?branch=master" alt="Build Status">
<a href="https://metacpan.org/pod/AnyEvent::Filesys::Notify"><img alt="CPAN version" src="https://badge.fury.io/pl/AnyEvent-Filesys-Notify.svg" /></a>

=head1 SYNOPSIS

    use AnyEvent::Filesys::Notify;

    my $notifier = AnyEvent::Filesys::Notify->new(
        dirs     => [ qw( this_dir that_dir ) ],
        interval => 2.0,             # Optional depending on underlying watcher
        filter   => sub { shift !~ /\.(swp|tmp)$/ },
        cb       => sub {
            my (@events) = @_;
            # ... process @events ...
        },
        parse_events => 1,  # Improves efficiency on certain platforms
    );

    # enter an event loop, see AnyEvent documentation
    Event::loop();

=head1 DESCRIPTION

This module provides a cross platform interface to monitor files and
directories within an L<AnyEvent> event loop. The heavy lifting is done by
L<Linux::INotify2> or L<Mac::FSEvents> on their respective O/S. A fallback
which scans the directories at regular intervals is include for other systems.
See L</WATCHER IMPLEMENTATIONS> for more on the backends.

Events are passed to the callback (specified as a CodeRef to C<cb> in the
constructor) in the form of L<AnyEvent::Filesys::Notify::Event>s.

=head1 METHODS

=head2 new()

A constructor for a new AnyEvent watcher that will monitor the files in the
given directories and execute a callback when a modification is detected. 
No action is take until a event loop is entered.

Arguments for new are:

=over 4

=item dirs 

    dirs => [ '/var/log', '/etc' ],

An ArrayRef of directories to watch. Required.

=item interval

    interval => 1.5,   # seconds

Specifies the time in fractional seconds between file system checks for
the L<AnyEvent::Filesys::Notify::Role::Fallback> implementation.

Specifies the latency for L<Mac::FSEvents> for the
C<AnyEvent::Filesys::Notify::Role::FSEvents> implementation.

Ignored for the C<AnyEvent::Filesys::Notify::Role::Inotify2> implementation.

=item filter

    filter => qr/\.(ya?ml|co?nf|jso?n)$/,
    filter => sub { shift !~ /\.(swp|tmp)$/,

A CodeRef or Regexp which is used to filter wanted/unwanted events. If this
is a Regexp, we attempt to match the absolute path name and filter out any
that do not match. If a CodeRef, the absolute path name is passed as the
only argument and the event is fired only if there sub returns a true value.

=item cb

    cb  => sub { my @events = @_; ... },

A CodeRef that is called when a modification to the monitored directory(ies) is
detected. The callback is passed a list of
L<AnyEvent::Filesys::Notify::Event>s. Required.

=item backend

    backend => 'Fallback',
    backend => 'KQueue',
    backend => '+My::Filesys::Notify::Role::Backend',

Force the use of the specified backend. The backend is assumed to have the
C<AnyEvent::Filesys::Notify::Role> prefix, but you can force a fully qualified
name by prefixing it with a plus. Optional.

=item no_external

    no_external => 1,

This is retained for backward compatibility. Using C<backend => 'Fallback'>
is preferred. Force the use of the L</Fallback> watcher implementation. This is
not encouraged as the L</Fallback> implement is very inefficient, but it does
not require either L<Linux::INotify2> nor L<Mac::FSEvents>. Optional.

=item parse_events

    parse_events => 1,

In backends that support it (currently INotify2), parse the events instead of
rescanning file system for changed C<stat()> information. Note, that this might
cause slight changes in behavior. In particular, the Inotify2 backend will
generate an additional 'modified' event when a file changes (once when opened
for write, and once when modified).

=item skip_subdirs

    skip_subdirs => 1,

Skips subdirectories and anything in them while building a list of files/dirs
to watch. Optional.

=back

=head1 WATCHER IMPLEMENTATIONS

=head2 INotify2 (Linux)

Uses L<Linux::INotify2> to monitor directories. Sets up an C<AnyEvent-E<gt>io>
watcher to monitor the C<$inotify-E<gt>fileno> filehandle.

=head2 FSEvents (Mac)

Uses L<Mac::FSEvents> to monitor directories. Sets up an C<AnyEvent-E<gt>io>
watcher to monitor the C<$fsevent-E<gt>watch> filehandle.

=head2 KQueue (BSD/Mac)

Uses L<IO::KQueue> to monitor directories. Sets up an C<AnyEvent-E<gt>io>
watcher to monitor the C<IO::KQueue> object.

B<WARNING> - L<IO::KQueue> and the C<kqueue()> system call require an open
filehandle for every directory and file that is being watched. This makes
it impossible to watch large directory structures (and inefficient to watch
moderately sized directories). The use of the KQueue backend is discouraged.

=head2 Fallback

A simple scan of the watched directories at regular intervals. Sets up an
C<AnyEvent-E<gt>timer> watcher which is executed every C<interval> seconds
(or fractions thereof). C<interval> can be specified in the constructor to
L<AnyEvent::Filesys::Notify> and defaults to 2.0 seconds.

This is a very inefficient implementation. Use one of the others if possible.

=head1 Why Another Module For File System Notifications

At the time of writing there were several very nice modules that accomplish
the task of watching files or directories and providing notifications about
changes. Two of which offer a unified interface that work on any system:
L<Filesys::Notify::Simple> and L<File::ChangeNotify>.

L<AnyEvent::Filesys::Notify> exists because I need a way to simply tie the
functionality those modules provide into an event framework. Neither of the
existing modules seem to work with well with an event loop.
L<Filesys::Notify::Simple> does not supply a non-blocking interface and
L<File::ChangeNotify> requires you to poll an method for new events. You could
fork off a process to run L<Filesys::Notify::Simple> and use an event handler
to watch for notices from that child, or setup a timer to check
L<File::ChangeNotify> at regular intervals, but both of those approaches seem
inefficient or overly complex. Particularly, since the underlying watcher
implementations (L<Mac::FSEvents> and L<Linux::INotify2>) provide a filehandle
that you can use and IO event to watch.

This is not slight against the authors of those modules. Both are well 
respected, are certainly finer coders than I am, and built modules which 
are perfect for many situations. If one of their modules will work for you
by all means use it, but if you are already using an event loop, this
module may fit the bill.

=head1 SEE ALSO

Modules used to implement this module L<AnyEvent>, L<Mac::FSEvents>,
L<Linux::INotify2>, L<Moose>.

Alternatives to this module L<Filesys::Notify::Simple>, L<File::ChangeNotify>.

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 CONTRIBUTORS

=over 4

=item *

Gasol Wu E<lt>gasol.wu@gmail.comE<gt> who contributed the BSD support for IO::KQueue

=item *

Dave Hayes E<lt>dave@jetcafe.orgE<gt>

=item *

Carsten Wolff E<lt>carsten@wolffcarsten.deE<gt>

=item *

Ettore Di Giacinto (@mudler)

=item *

Martin Barth (@ufobat)

=back

=head1 SOURCE

Source repository is at L<https://github.com/mvgrimes/AnyEvent-Filesys-Notify>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<http://github.com/mvgrimes/AnyEvent-Filesys-Notify/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
