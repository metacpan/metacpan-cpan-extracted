package DBIx::QueryCursor;

use warnings;
use strict;

use Abstract::Meta::Class ':all';
use Carp 'confess';
use base 'DBIx::SQLHandler';
use vars qw($VERSION);

$VERSION = 0.03;

=head1 NAME

DBIx::QueryCursor - Database cursor handler

=head1 SYNOPSIS

    use DBIx::QueryCursor;
    my $cursor = new DBIx::QueryCursor(
        connection  => $connection,
        sql         => "SELECT * FROM emp WHERE ename = ?"
    );
    my $result_set = $cursor->execute(['Smith']);

    if($cursor->fetch()) {
        $ename = result_set->{ENAME};
        ... do some stuff
    }


    or

    use DBIx::Connection;

    my $cursor = $connection->query_cursor(
        sql         => "SELECT * FROM emp WHERE ename = ?"
    );


=head1 DESCRIPTION

Class that represents database cursor.

=head2 attributes

=over

=item result_set

Fetch resultset.

=cut

has '$.result_set';


=item rows

Number of rows retrieved since last execution.

=cut

has '$.rows';

=back

=head2 methods

=over

=item columns

Function return list of column from current cursor

=cut

sub columns {
    my ($self) = @_;
    \@{$self->sth->{NAME_lc}}
}


=item execute

Executes statements, takes bind parameters as ARRAY ref, optionaly resul set as reference(HASH, SCALAR, ARRAY)
Returns result set.

=cut

sub execute {
    my ($self, $bind_params, $result_set) = @_;
    $result_set ||= {};
    $self->set_result_set($result_set);
    $self->finish if $self->rows;
    $self->SUPER::execute(@$bind_params);
    $self->bind_columns($result_set);
    $self->set_rows(0);
    $result_set;
}


=item iterator

Returns the cursor itarator, on each iteration database error is checked.
For instance sub query returned more then error exception is capture here.

=cut

sub iterator {
    my ($self) = @_;
    my $sth = $self->sth;
    my $dbh = $self->connection->dbh; 
    sub {
        my $result = $sth->fetch();
        $self->set_rows($self->rows + 1);
        confess $self->error_handler 
          if $dbh->errstr;
        $result;
    };
}


=item fetch

Move cursor to next result.
Returns true if a row was fetched or false if no more results exist.

=cut

sub fetch {
    my ($self) = @_;
    my $dbh = $self->connection->dbh; 
    my $has_result = $self->sth->fetch;
    $self->error_handler
      if $dbh->errstr;
    $self->set_rows($self->rows + 1);
    $has_result ? (wantarray ? @$has_result  : $has_result) : ();
}


=item finish

Signals that the cursor will not be used again.

=cut

sub finish {
    my ($self) = @_;
    $self->sth->finish if $self->sth;
}

1;

__END__

=back

=head1 COPYRIGHT AND LICENSE

The DBIx::QueryCursor module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 SEE ALSO

L<DBIx::Connection>
L<DBIx::SQLHandler>.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut