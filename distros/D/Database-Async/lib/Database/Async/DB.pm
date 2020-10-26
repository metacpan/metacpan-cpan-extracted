package Database::Async::DB;

use strict;
use warnings;

our $VERSION = '0.012'; # VERSION

use Future;

use Database::Async::StatementHandle;

use Log::Any qw($log);

our @METHODS = qw(
    do
    prepare
    insert
    query
);

sub db { shift->{db} }

=head2 do

Executes the given SQL with optional bind parameters.

=cut

sub do : method {
    my ($self, $sql, %args) = @_;
    Future->done
}

=head2 prepare

Prepares a L<Database::Async::StatementHandle>.

=cut

sub prepare {
    my ($self, $sql) = @_;
    Future->done(
        Database::Async::StatementHandle->new
    )
}

sub quote_table_name {
    my ($self, $name) = @_;
    $name =~ s/"/""/g;
    '"' . $name . '"'
}

sub quote_field_name {
    my ($self, $name) = @_;
    $name =~ s/"/""/g;
    '"' . $name . '"'
}

sub insert {
    my ($self, $table, $data) = @_;
    $self->query(
        'insert into '
        . $self->quote_table_name(
            $table
        )
        . ' ('
        . join(',', map { $self->quote_field_name($_) } keys %$data)
        . ') values ('
        . join(',', ('?') x (keys %$data))
        . ')',
        values %$data
    )
}

sub query {
    my ($self, $sql, @bind) = @_;
    $log->tracef('Attempting query %s with %s', $sql, \@bind);
    Database::Async::Query->new(
        db   => $self->db,
        sql  => $sql,
        bind => \@bind
    )
}

1;

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >>

=head1 LICENSE

Copyright Tom Molesworth 2011-2020. Licensed under the same terms as Perl itself.

