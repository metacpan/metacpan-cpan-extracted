package DBIx::Connection::MySQL::PLSQL;

use warnings;
use strict;

use Abstract::Meta::Class ':all';
use Carp 'confess';
use base qw(DBIx::PLSQLHandler);

use vars qw($VERSION);

$VERSION = 0.02;

=head1 NAME

DBIx::Connection::MySQL::PLSQL - PLSQL handler

=head1 SYNOPSIS

    use DBIx::PLSQLHandler;

    my $plsql_handler = new DBIx::PLSQLHandler(
        name        => 'test_proc',
        connection  => $connection,
        plsql       => "
        DECLARE
        var1 INT;
        BEGIN
        SET var1 := :var2 + :var3;
        END;",
	bind_variables => {
            var2 => {type => 'SQL_INTEGER'},
            var3 => {type => 'SQL_INTEGER'}
	}
    );
    $plsql_handler->execute(var2 => 12, var3 => 8);

    or

    use DBIx::Connection;
    ....

    my $plsql_handler = $connection->plsql_handler(
        name        => 'test_proc',
        connection  => $connection,
        plsql       => "
        DECLARE
        var1 INT;
        BEGIN
        :var1 := :var2 + :var3;
        END;",
	bind_variables => {
            var1 => {type => 'SQL_INTEGER'},
            var2 => {type => 'SQL_INTEGER'},
            var3 => {type => 'SQL_INTEGER'}
	}
    );

    my $result_set = $plsql_handler->execute(var2 => 12, var3 => 8);


=head2 METHODS

=over

=cut

{
    my %SQL = (
        find_function => 'SELECT routine_definition FROM information_schema.ROUTINES WHERE routine_schema = ? AND routine_name = ? ',
    );


=item sql_defintion

Returns sql statment definitio, Takes sql name as parameter.

=cut

    sub sql_defintion {
        my ($self, $name) = @_;
        $SQL{$name};
    }
}


=item prepare

Prepares plsql block

=cut

sub prepare {
    my ($self) = @_;
    $self->initialise_plsql_block();
    $self->initialise_sql();
}


=item initialise_plsql_block

=cut

sub initialise_plsql_block {
    my ($self) = @_;
    my $connection = $self->connection;
    if($self->is_block_changed($connection->username, $self->plsql_block_name)) {
        my $plsql_block_wrapper = $self->plsql_block_wrapper;
        $self->connection->do($plsql_block_wrapper);   
    }
}

=item drop_plsql_block

Removes plsql block wrapper

=cut

sub drop_plsql_block {
    my ($self) = @_;
    $self->connection->do("DROP PROCEDURE IF EXISTS " . $self->plsql_block_name);
}


=item plsql_block_wrapper

Generates plsql procedure.

=cut

sub plsql_block_wrapper {
    my ($self) = @_;
    "CREATE PROCEDURE  " . $self->plsql_block_name  . '(' . $self->plsql_block_declaration  . ')'
    . $self->block_source;
}


=item initialise_sql                          

=cut

sub initialise_sql {
    my ($self) = @_;
    my @binded_out_variables = $self->binded_out_variables;
    my $result = join (",", map { '@' . $_ . ' AS '  . $_ } @binded_out_variables);
    $self->set_sql(@binded_out_variables ? "SELECT $result" : '');
}


=item execute

Executes plsql block

=cut

sub execute {
    my ($self, %bind_variables) = @_;
    my $connection = $self->connection;
    $self->bind_parameters(\%bind_variables);
    my $sql = $self->sql;
    return $connection->record($sql) if $sql ;
}


=item bind_parameters

=cut

sub bind_parameters {
    my ($self, $bind_variables) = @_;
    my $connection = $self->connection;
    my @binded_out_variables = $self->binded_out_variables;
    foreach my $variable (@binded_out_variables) {
        $connection->execute_statement('SET @' . $variable . ' = ?', $bind_variables->{$variable});
    }
    my @bind_in_variables = $self->bind_in_variables;
    my $call_params = join(",", (map { '?' } @bind_in_variables),  (map { '@' . $_ } @binded_out_variables));
    my @bind_variables = map { $bind_variables->{$_} } @bind_in_variables;
    my $sql = "CALL " . $self->plsql_block_name . "($call_params)";
    $connection->execute_statement($sql, @bind_variables);
}



=item parsed_plsql

Parses plsql code and replaces :var to var

=cut

sub parsed_plsql {
    my ($self) = @_;
    my $plsql = $self->plsql;
    my $bind_variables = $self->bind_variables;
    foreach my $variable (sort keys %$bind_variables) {
        $plsql =~ s/:$variable\s*:=/SET $variable :=/g;
        $plsql =~ s/:$variable/$variable/g;
    }
    $plsql;
}

{
=item type_map 

mapping between DBI and database types.
The following mapping is defined:

    SQL_DECIMAL => 'NUMERIC',
    SQL_VARCHAR => 'VARCHAR',
    SQL_DATE    =>'DATE',
    SQL_CHAR    =>'CHAR',
    SQL_DOUBLE  =>'NUMERIC',
    SQL_INTEGER =>'INT',
    SQL_BOOLEAN =>'BOOLEAN',

=cut

    my %type_map = (
        SQL_DECIMAL => 'NUMERIC',
        SQL_VARCHAR => 'VARCHAR',
        SQL_DATE    =>'DATE',
        SQL_CHAR    =>'CHAR',
        SQL_DOUBLE  =>'NUMERIC',
        SQL_INTEGER =>'INT',
        SQL_BOOLEAN =>'BOOLEAN',
    );


=item get_type

Returns 

=cut

    sub get_type {
        my ($class, $type) = @_;
        $type_map{$type};
    }
}



1;

__END__

=back

=head1 COPYRIGHT AND LICENSE

The DBIx::Connection::MySQL::PLSQL module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

See also B<DBIx::Connection> B<DBIx::QueryCursor> B<DBIx::SQLHandler>.

=cut