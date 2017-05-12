package AnyEvent::Filesys::Notify::Role::Inotify2;

# ABSTRACT: Use Linux::Inotify2 to watch for changed files

use Moo::Role;
use MooX::late;
use namespace::autoclean;
use AnyEvent;
use Linux::Inotify2;
use Carp;
use Path::Iterator::Rule;

our $VERSION = '1.21';

# use Scalar::Util qw(weaken);  # Attempt to address RT#57104, but alas...

sub _init {
    my $self = shift;

    my $inotify = Linux::Inotify2->new()
      or croak "Unable to create new Linux::Inotify2 object";

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
# There are small changes in behavior compared to the parent code:
#
# 1. `touch test` causes an additional "modified" event after the "created"
# 2. `mv test2 test` if test exists before, event for test would be "modified"
#     in parent code, but is "created" here
#
# Because of these differences, we default to the original behavior unless the
# parse_events flag is true.
sub _parse_events {
    my ( $self, @raw_events ) = @_;
    my @events = ();

    for my $e (@raw_events) {
        my $type = undef;

        $type = 'modified' if ( $e->mask & ( IN_MODIFY | IN_ATTRIB ) );
        $type = 'deleted'  if ( $e->mask &
            ( IN_DELETE | IN_DELETE_SELF | IN_MOVED_FROM | IN_MOVE_SELF ) );
        $type = 'created'  if ( $e->mask & ( IN_CREATE | IN_MOVED_TO ) );

        push(
            @events,
            AnyEvent::Filesys::Notify::Event->new(
                path   => $e->fullname,
                type   => $type,
                is_dir => !! $e->IN_ISDIR,
            ) ) if $type;

        # New directories are not automatically watched, we will add it to the
        # list of watched directories in `around '_process_events'` but in
        # the meantime, we will miss any newly created files in the subdir
        if ( $e->IN_ISDIR and $type eq 'created' ) {
            my $rule = Path::Iterator::Rule->new;
            my $next = $rule->iter( $e->fullname );
            while ( my $file = $next->() ) {
                next if $file eq $e->fullname;
                push @events,
                  AnyEvent::Filesys::Notify::Event->new(
                    path   => $file,
                    type   => 'created',
                    is_dir => -d $file,
                  );
            }

        }
    }

    return @events;
}

# Need to add newly created sub-dirs to the watch list.
# This is done after filtering. So entire dirs can be ignored efficiently;
sub _process_events_for_backend {
    my ( $self, @events ) = @_;

    for my $event (@events) {
        next unless $event->is_dir && $event->is_created;

        $self->_fs_monitor->watch(
            $event->path,
            IN_MODIFY | IN_CREATE | IN_DELETE | IN_DELETE_SELF |
                IN_MOVE | IN_MOVE_SELF | IN_ATTRIB,
            sub { my $e = shift; $self->_process_events($e); } );

    }
}

1;

__END__

=pod

=head1 NAME

AnyEvent::Filesys::Notify::Role::Inotify2 - Use Linux::Inotify2 to watch for changed files

=head1 VERSION

version 1.21

=head1 CONTRIBUTORS

=for stopwords Gasol Wu E<lt>gasol.wu@gmail.comE<gt> who contributed the BSD support for IO::KQueue Dave Hayes E<lt>dave@jetcafe.orgE<gt> Carsten Wolff E<lt>carsten@wolffcarsten.deE<gt>

=over 4

=item *

Gasol Wu E<lt>gasol.wu@gmail.comE<gt> who contributed the BSD support for IO::KQueue

=item *

Dave Hayes E<lt>dave@jetcafe.orgE<gt>

=item *

Carsten Wolff E<lt>carsten@wolffcarsten.deE<gt>

=back

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 SOURCE

Source repository is at L<https://github.com/mvgrimes/AnyEvent-Filesys-Notify>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<http://github.com/mvgrimes/AnyEvent-Filesys-Notify/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
