package AnyEvent::Filesys::Notify::Role::Inotify2;

# ABSTRACT: Use Linux::Inotify2 to watch for changed files

use Moo::Role;
use MooX::late;
use namespace::autoclean;
use AnyEvent;
use Linux::Inotify2;
use Carp;
use Path::Iterator::Rule;

our $VERSION = '1.23';

# use Scalar::Util qw(weaken);  # Attempt to address RT#57104, but alas...

sub _init {
    my $self = shift;

    my $inotify = Linux::Inotify2->new()
      or croak "Unable to create new Linux::Inotify2 object: $!";

    # Need to add all the subdirs to the watch list, this will catch
    # modifications to files too.
    my $old_fs = $self->_old_fs;
    my @dirs = grep { $old_fs->{$_}->{is_dir} } keys %$old_fs;

    # weaken $self; # Attempt to address RT#57104, but alas...

    for my $dir (@dirs) {
        $inotify->watch(
            $dir,
            IN_MODIFY | IN_CREATE | IN_DELETE | IN_DELETE_SELF |
              IN_MOVE | IN_MOVE_SELF | IN_ATTRIB,
            sub { my $e = shift; $self->_process_events($e); } );
    }

    $self->_fs_monitor($inotify);

    $self->_watcher(
        AnyEvent->io(
            fh   => $inotify->fileno,
            poll => 'r',
            cb   => sub {
                $inotify->poll;
            } ) );

    return 1;
}

# Parse the events returned by Inotify2 instead of rescanning the files.
# There are small changes in behavior compared to the previous releases
# without parse_events:
#
# 1. `touch test` causes an additional "modified" event after the "created"
# 2. `mv test2 test` if test exists before, event for test would be "modified"
#     in parent code, but is "created" here
#
# Because of these differences, we default to the original behavior unless the
# parse_events flag is true.
sub _parse_events {
    my ( $self, $filter_cb, @raw_events ) = @_;

    my @events =
      map  { $filter_cb->($_) }                    # filter new event
      grep { defined }                             # filter undef events
      map  { $self->_mk_event($_) } @raw_events;

    # New directories are not automatically watched by inotify.
    $self->_add_events_to_watch(@events);

    # Any entities that were created in new dirs (before the call to
    # _add_events_to_watch) will have been missed. So we walk the filesystem
    # now.
    push @events,    # add to @events
      map { $self->_add_entities_in_subdir( $filter_cb, $_ ) }  # ret new events
      grep { $_->is_dir and $_->is_created }    # only new directories
      @events;

    return @events;
}

sub _add_entities_in_subdir {
    my ( $self, $filter_cb, $e ) = @_;
    my @events;

    my $rule = Path::Iterator::Rule->new;
    my $next = $rule->iter( $e->path );
    while ( my $file = $next->() ) {
        next if $file eq $e->path; # $e->path will have already been added

        my $new_event = AnyEvent::Filesys::Notify::Event->new(
            path   => $file,
            type   => 'created',
            is_dir => -d $file,
        );

        next unless $filter_cb->($new_event);
        $self->_add_events_to_watch( $new_event );
        push @events, $new_event;
    }

    return @events;
}

sub _mk_event {
    my ( $self, $e ) = @_;

    my $type = undef;

    $type = 'modified' if ( $e->mask & ( IN_MODIFY | IN_ATTRIB ) );
    $type = 'deleted'
      if ( $e->mask &
        ( IN_DELETE | IN_DELETE_SELF | IN_MOVED_FROM | IN_MOVE_SELF ) );
    $type = 'created' if ( $e->mask & ( IN_CREATE | IN_MOVED_TO ) );

    return unless $type;
    return AnyEvent::Filesys::Notify::Event->new(
        path   => $e->fullname,
        type   => $type,
        is_dir => !!$e->IN_ISDIR,
    );
}

# Needed if `parse_events => 0`
sub _post_process_events {
    my ( $self, @events ) = @_;
    return $self->_add_events_to_watch(@events);
}

sub _add_events_to_watch {
    my ( $self, @events ) = @_;

    for my $event (@events) {
        next unless $event->is_dir && $event->is_created;

        $self->_fs_monitor->watch(
            $event->path,
            IN_MODIFY | IN_CREATE | IN_DELETE | IN_DELETE_SELF |
              IN_MOVE | IN_MOVE_SELF | IN_ATTRIB,
            sub { my $e = shift; $self->_process_events($e); } );
    }

    return;
}

1;

__END__

=pod

=head1 NAME

AnyEvent::Filesys::Notify::Role::Inotify2 - Use Linux::Inotify2 to watch for changed files

=head1 VERSION

version 1.23

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
