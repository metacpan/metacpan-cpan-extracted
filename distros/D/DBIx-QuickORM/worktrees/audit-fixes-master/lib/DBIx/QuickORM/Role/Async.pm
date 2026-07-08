package DBIx::QuickORM::Role::Async;
use strict;
use warnings;

our $VERSION = '0.000028';

use Time::HiRes qw/sleep/;
use Role::Tiny;

with 'DBIx::QuickORM::Role::STH';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Role::Async - Role for asynchronous statement handles.

=head1 DESCRIPTION

Extends L<DBIx::QuickORM::Role::STH> for statement handles whose results
arrive asynchronously (driver-level async or a forked child). Provides
C<wait> (poll C<ready> until the result is available) and a C<DESTROY> that
cancels or drains an unfinished handle so it never leaks an in-flight query.

=cut

sub wait { sleep 0.1 until $_[0]->ready }

sub DESTROY {
    my $self = shift;

    return if $self->done;

    # An inherited copy in a forked child shares the owner's pipe read-end (Fork)
    # or driver socket (Async/Aside). Waiting, reading, cancelling, or fetching
    # here would steal the owner's frames or corrupt its connection protocol, so
    # a non-owner process must touch nothing and let the owner finalize.
    return if $self->can('in_owner_process') && !$self->in_owner_process;

    # A driver-async handle can be invalidated when its connection reconnects
    # (the shared driver handle is closed under it). Finalize it without reading
    # or cancelling the dead handle.
    return $self->finalize_invalidated if $self->can('finalize_invalidated') && $self->invalidated;

    # Cancel only a cancellable handle whose destructor is allowed to abort it.
    # Otherwise (e.g. a forked write that must run to completion) fall through to
    # set_done, which drives the query to its terminal state without re-reading
    # the child's result frame (which could croak out of this destructor).
    my $should_cancel = !$self->got_result;
    $should_cancel &&= $self->cancel_supported;
    $should_cancel &&= $self->cancel_on_destroy;

    $self->cancel if $should_cancel;

    $self->set_done;
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
