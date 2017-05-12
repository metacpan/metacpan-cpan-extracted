package DBIx::PLSQLHandler;

use warnings;
use strict;

use Abstract::Meta::Class ':has';
use Carp 'confess';
use base 'DBIx::SQLHandler';
use Data::Dumper;
use vars qw($VERSION);

$VERSION = 0.02;

use constant DEFAULT_TYPE => 'SQL_VARCHAR';
use constant DEFAULT_WIDTH => 32000;


=head1 NAME

DBIx::PLSQLHandler - PL/SQL procedural language handler.

=head1 SYNOPSIS

    use DBIx::PLSQLHandler;
    my $plsql = new DBIx::PLSQLHandler(
        connection => $connection,
        plsql      => "
DECLARE
    debit_amt    CONSTANT NUMBER(5,2) := 500.00;
BEGIN
    SELECT a.bal INTO :acct_balance FROM accounts a
    WHERE a.account_id = :acct AND a.debit > debit_amt;
    :extra_info := 'debit_amt: ' || debit_amt;
END;"
);

    my $result_set = $plsql->execute(acct => 000212);
    # $result_set->{acct_balance}; $result_set->{extra_info}
    ... do some stuff

    or

    use DBIx::Connection;

    ...

     my $plsql = $connection->plsql_handler(
            plsql      => "
    DECLARE
        debit_amt    CONSTANT NUMBER(5,2) := 500.00;
    BEGIN
        SELECT a.bal INTO :acct_balance FROM accounts a
        WHERE a.account_id = :acct AND a.debit > debit_amt;
        :extra_info := 'debit_amt: ' || debit_amt;
    END;"
    );


=head1 DESCRIPTION

Base class for PLSQL blocks hyandler(SQL Procedural Language).
It allows use independetly specyfig Procedural Language SQL dialect like PL/SQL (Oracle, mySQL), PL/pgSQL (PostgreSQL)
It uses ":" placeholers to bind variables in or out or inout.

By default it bind variable is defined as varchar,
however you can change it by specyfing your types in bind_variables parameter.


        my $plsql_handler = new DBIx::PLSQLHandler(
            name        => 'int_test',
            connection  => $connection,
            plsql       => "BEGIN
            :var1 := :var2 + :var3;
            :var4 := 'long text';
            END;",
	    bind_variables => {
		var1 => {type => 'SQL_INTEGER'},
                var4 => {type => 'SQL_VARCHAR', width => 30}
	    }
	);

In Oracle database it uses an anonymous PLSQL block,
In mysql procedure wraps the plsql block.
In postgresql function wraps the plsql block.
Name for the procedure/function wrapper is created as 'anonymous_' + $self->name 

=head2 ATTRIBUTES

=over

=item plsql

Plsql block

=cut

    
has '$.plsql';


=item bind_variables

Keeps information about binds variables and its types.

=cut

has '%.bind_variables' => (item_accessor => 'bind_variable');


=item bind_in_variales

Ordered list for binding in variables

=cut

has '@.bind_in_variables';


=item bind_inout_variales

Ordered list for binding in out variables

=cut

has '@.bind_inout_variables';


=item bind_out_variales

Ordered list for binding out variables

=cut

has '@.bind_out_variables';


=item default_type

default type binding

=cut

has '$.default_type' => (default => DEFAULT_TYPE);


=item default_width

default width binding

=cut

has '$.default_width' => (default => DEFAULT_WIDTH);

=back

=head2 METHODS

=over

=item new

=cut

sub new {
    my ($class, %args) = @_;
    my $specialisation_module = $args{connection}->load_module('PLSQL');
    my $self = $specialisation_module->new(%args);
    return $self;
}


=item initialise

Initialises handler.

=cut 

sub initialise {
    my ($self) = @_;
    $self->initialise_bind_variables();
    $self->SUPER::initialise();
}


=item initialise_bind_variables

Parses plsql for binding variables.
TODO replace this naive implementations.

=cut

sub initialise_bind_variables {
    my ($self) = @_;
    my $plsql = $self->plsql;
    my $bind_variables = $self->bind_variables;
    $plsql =~ s/\'[^\']*\'//g;
    while ($plsql =~ s/:(\w+)\s*(:*)//) {
        my $bind_variable = $1;
        my $out_flag = $2;
        my $variable = $bind_variables->{$bind_variable};
        if ($variable && $variable->{binding}) {
            $variable->{binding} = 'inout' if ($out_flag && $variable->{binding} eq 'in');
            
        } else {
            $variable = $bind_variables->{$bind_variable} = $self->default_variable_info
                unless $variable;
            $variable->{binding} = $out_flag ? 'out' : 'in';
        }
    }
    $self->set_binding_order();
}


=item set_binding_order

=cut

sub set_binding_order {
    my ($self) = @_;
    my $bind_variables = $self->bind_variables;
    my $bind_in_variables = $self->bind_in_variables;
    my $bind_inout_variables = $self->bind_inout_variables;
    my $bind_out_variables = $self->bind_out_variables;
    
    foreach my $k (sort keys %$bind_variables) {
        my $variable = $bind_variables->{$k};
        if ($variable->{binding} eq 'in') {
            push @$bind_in_variables, $k;
            
        } elsif ($variable->{binding} eq 'out') {
            push @$bind_out_variables, $k;
            
        } else {
            push @$bind_inout_variables, $k;
        }
    }
}


=item default_variable_info

Adds default variable meta data.

=cut

sub default_variable_info {
    my $self = shift;
    {type  => $self->default_type, width => $self->default_width, @_};
}


=item plsql_block_name

Returns plsql block name (used to create plsql block procedure or function wrapper)

=cut

sub plsql_block_name {
    my ($self) = @_;
    my $result = "anonymous_";
    if ($self->name =~ m/\s+/) {
        $result .= unpack("%32C*",$self->name);
    } else {
        $result .= $self->name;
    }
    substr($result, 0, 30);
}


=item plsql_block_declaration

=cut

sub plsql_block_declaration {
    my ($self) = @_;
    my $result = '';
    foreach my $k($self->bind_variable_order) {
        $result .= ($result ? ', ' : '') . $self->variable_declaration($k);
    }
    $result;
}


=item bind_variable_order

Return bind variable order

=cut

sub bind_variable_order {
    my ($self) = @_;
    ($self->bind_in_variables, $self->bind_inout_variables, $self->bind_out_variables);
}


=item binded_in_variables

Returns bind_in_variables + bind_inout_variables

=cut

sub binded_in_variables {
    my ($self) = @_;    
    ($self->bind_in_variables, $self->bind_inout_variables);
}


=item binded_out_variables

Returns bind_inout_variables + bind_out_variables

=cut

sub binded_out_variables {
    my ($self) = @_;
    ($self->bind_inout_variables, $self->bind_out_variables);
}   


=item variable_declaration

Returns variable definition for plsql block stub

=cut

sub variable_declaration {
    my ($self, $variable_name) = @_;
    my $variable = $self->bind_variable($variable_name);
    my $type = $variable->{type};
    uc($variable->{binding}) .' ' . $variable_name . ' ' . $self->get_type($type) . $self->type_precision($variable_name);
}


=item type_precision

Returns variable type precision, takes bind variable name.

=cut

sub type_precision {
    my ($self, $variable_name) = @_;
    my $variable = $self->bind_variable($variable_name);
    ($variable->{type} && $variable->{type} =~ /CHAR/ ? '(' . $variable->{width} . ')' : '')
}


=item block_source

Block source, used for comparision against database wrapper source.

=cut

sub block_source {
    my ($self) = @_;
    "BEGIN\n"
    . $self->parsed_plsql
    ."\nEND;";
}


=item parsed_plsql

Parses plsql code and replaces :var to var

=cut

sub parsed_plsql {
    my ($self) = @_;
    my $plsql = $self->plsql;
    my $bind_variables = $self->bind_variables;
    foreach my $variable (sort keys %$bind_variables) {
        $plsql =~ s/:$variable/$variable/g;
    }
    $plsql;
}


=item is_block_changed

Checks if plsql_block has been changed and return true otherwise false.

=cut

sub is_block_changed {
    my ($self, @bind_param) = @_;
    my $connection = $self->connection;
    my $record = $connection->record($self->sql_defintion('find_function'), @bind_param);
    my $routine_definition = $record->{routine_definition} or return 1;
    $routine_definition =~ s/[\n\r\s\t;]//g;
    my $block_source  = $self->block_source;
    $block_source =~ s/[\n\r\s\t;]//g;
    if ($block_source ne $routine_definition) {
        $self->drop_plsql_block;
        return 1
    };
    !! undef;
}


1;

__END__

=back

=head1 COPYRIGHT AND LICENSE

The DBIx::PLSQLHandler module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 SEE ALSO

L<DBIx::QueryCursor>
L<DBIx::SQLHandler>

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut
