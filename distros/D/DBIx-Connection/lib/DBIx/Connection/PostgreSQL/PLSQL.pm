package DBIx::Connection::PostgreSQL::PLSQL;


use warnings;
use strict;

use Abstract::Meta::Class ':all';
use Carp 'confess';
use base qw(DBIx::PLSQLHandler);

use vars qw($VERSION);

$VERSION = 0.02;

=head1 NAME

DBIx::Connection::PostgreSQL::PLSQL - PLSQL block wrapper for PostgreSQL

=head1 SYNOPSIS

    use DBIx::PLSQLHandler;

    my $plsql_handler = new DBIx::PLSQLHandler(
        name        => 'test_proc',
        connection  => $connection,
        plsql       => "
        DECLARE
        var1 INT;
        BEGIN
        var1 := :var2 + :var3;
        END;",
	bind_variables => {
            var2 => {type => 'SQL_INTEGER'},
            var3 => {type => 'SQL_INTEGER'}
	}
    );
    $plsql_handler->execute(var2 => 12, var3 => 8);

    or

    use DBIx::Connection;


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


=head1 DESCRIPTION

This class creates and invokes plsql function dynamicly that wraps
defined plsql block. This module check if body of plsql block has been changed
then it recreated wraper function for changed plsql block

=cut

=head2 METHODS

=over

=cut

{
    my %SQL = (
        find_function => 'SELECT prosrc AS routine_definition FROM pg_proc WHERE proname = ? ',
        function_args => 'SELECT t.typname, t.oid, p.proargtypes FROM pg_proc p JOIN pg_type t ON t.oid =  ANY (p.proallargtypes) WHERE p.proname = ? '
    );

=item sql_defintion

Return sql statement defintion. Takes sql name.

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

Initialises plsql block, checks for changes, recreated if necessary.

=cut

sub initialise_plsql_block {
    my ($self) = @_;
    my @binded_out_variables = $self->binded_out_variables;
    unless (@binded_out_variables) {
        $self->push_bind_out_variables('result');
        $self->bind_variable(result => $self->default_variable_info(binding => 'out'));
    }
    my $plsql_block_wrapper = $self->plsql_block_wrapper;
    if($self->is_block_changed($self->plsql_block_name)) {
        $self->connection->do($plsql_block_wrapper);   
    }
}

=item drop_plsql_block

Removes existing function that acts as plsql block wrapper.

=cut

sub drop_plsql_block {
    my ($self) = @_;
    my $connection = $self->connection;
    my $cursor = $connection->query_cursor(sql => $self->sql_defintion('function_args'));
    $cursor->execute([$self->plsql_block_name]);
    my $args;
    while (my ($typname, $oid, $proargtypes) = $cursor->fetch) {
        $args ||= join (",", split /\s+/, $proargtypes);
        $args =~ s/$oid/$typname/g if $oid;
    }
    $connection->do("DROP FUNCTION " . $self->plsql_block_name . "($args)" );
}


=item plsql_block_wrapper

Returns plsql block weapper as plsql function

=cut

sub plsql_block_wrapper {
    my ($self) = @_;
    'CREATE FUNCTION  ' . $self->plsql_block_name . '(' . $self->plsql_block_declaration . ') AS $$'
    . "\n" . $self->block_source . "\n"
    . '$$ LANGUAGE plpgsql;';
}



=item initialise_sql

Initialises sql that will be used to invoke postgres function (plsql block)

=cut

sub initialise_sql {
    my ($self) = @_;    
    my @bind_in_variables =  $self->binded_in_variables;
    my @bind_out_variables = $self->binded_out_variables;
    $self->set_sql(scalar(@bind_out_variables) == 1
        ? "SELECT " . $self->plsql_block_name  . '('  . join (",", ,map {'?'} @bind_in_variables)  . ') AS ' . $bind_out_variables[0]
        :  "SELECT  " . (join ",", (map { '(f.func).' . $_ } @bind_out_variables)) . " FROM (SELECT " . $self->plsql_block_name  . '('  . join (",", ,map {'?'} @bind_in_variables)  . ') AS func) f');
}


=item execute

Binds and executes plsql block.

=cut

sub execute {
    my ($self, %bind_variables) = @_;
    my @bind_in_variables =  $self->binded_in_variables;
    my $connection = $self->connection;
    $connection->no_cache(1);
    my $result_set;
    eval {$result_set = $self->connection->record($self->sql, map {$bind_variables{$_}} @bind_in_variables);};
    $connection->no_cache(0);
    die $@ if $@;
    $result_set ;
}


=item type_precision

Returns variable precision.

=cut

sub type_precision {''}


{
=item type_map 

Mapping between DBI and specyfic postgres types.
The following mapping is defined:

    SQL_DECIMAL => 'numeric',
    SQL_VARCHAR => 'varchar',
    SQL_DATE    =>'date',
    SQL_CHAR    =>'varchar',
    SQL_DOUBLE  =>'float8',
    SQL_INTEGER =>'int4',
    SQL_BOOLEAN =>'boolean',

=cut

    my %type_map = (
        SQL_DECIMAL => 'numeric',
        SQL_VARCHAR => 'varchar',
        SQL_DATE    =>'date',
        SQL_CHAR    =>'varchar',
        SQL_DOUBLE  =>'float8',
        SQL_INTEGER =>'int4',
        SQL_BOOLEAN =>'boolean',
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

The DBIx::Connection::PostgreSQL::PLSQL module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

See also B<DBIx::Connection> B<DBIx::QueryCursor> B<DBIx::SQLHandler>.

=cut
