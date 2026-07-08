package DBIx::QuickORM::Role::STH;
use strict;
use warnings;

our $VERSION = '0.000028';

use Carp qw/croak/;

use Role::Tiny;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Role::STH - Role for statement-handle wrappers.

=head1 DESCRIPTION

The common interface for the statement-handle wrappers
(L<DBIx::QuickORM::STH> and its async variants). It defines the iteration
contract: fetch the result, check readiness, pull rows, and finalize.

Provides default C<cancel_supported> (false) and C<cancel> (croaks);
cancellable handles override both. Also provides C<cancel_on_destroy> (true):
a handle whose destructor should wait for completion instead of cancelling an
unfinished query overrides it to false.

Provides C<dialect> (lazily taken from the connection) and C<next> (the
C<only_one> policing iteration built on the required C<_next>/C<set_done>).

=head1 REQUIRED METHODS

C<connection>, C<source>, C<only_one>, C<got_result>, C<result>, C<ready>,
C<done>, C<set_done>, C<clear>, C<_next>.

=head1 PUBLIC METHODS

=over 4

=item $bool = $sth->cancel_supported

=item $sth->cancel

=item $bool = $sth->cancel_on_destroy

Cancellation defaults; see the description above.

=item $dialect = $sth->dialect

The dialect, lazily taken from the connection and cached on the handle.

=item $row_hr = $sth->next

Return the next row as a hashref, or undef once exhausted. With C<only_one>
set, a second row is an error.

=back

=cut

sub cancel_supported { 0 }

sub cancel { croak "cancel() is not supported" }

sub cancel_on_destroy { 1 }

# Cache the dialect in the consumer's 'dialect' slot, populated lazily from the
# connection on first use.
sub dialect { $_[0]->{dialect} //= $_[0]->connection->dialect }

sub next {
    my $self = shift;
    my $row = $self->_next;

    if ($self->only_one) {
        # Finalize before throwing so the statement is released (child reaped,
        # async/fork slot on the connection freed) even on the error path.
        if ($self->_next) {
            $self->set_done;
            croak "Expected only 1 row, but got more than one";
        }
        $self->set_done;
    }

    return $row;
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
