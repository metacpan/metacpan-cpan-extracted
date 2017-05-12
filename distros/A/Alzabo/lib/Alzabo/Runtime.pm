package Alzabo::Runtime;

use strict;

use Alzabo;

use Alzabo::Runtime::Column;
use Alzabo::Runtime::ColumnDefinition;
use Alzabo::Runtime::ForeignKey;
use Alzabo::Runtime::Index;
use Alzabo::Runtime::InsertHandle;
use Alzabo::Runtime::JoinCursor;
use Alzabo::Runtime::Row;
use Alzabo::Runtime::RowCursor;
use Alzabo::Runtime::Schema;
use Alzabo::Runtime::Table;
use Alzabo::Utils;

use vars qw($VERSION);

$VERSION = 2.0;

1;

sub import
{
    shift;

    # ignore errors and let them be handled later in the app when it
    # tries to access the schema.
    eval { Alzabo::Runtime::Schema->load_from_file( name => $_ ); } foreach @_;
}

sub sqlmaker
{
    my ($schema, $p) = @_;

    my %sqlmaker_p = ( exists $p->{quote_identifiers} ?
                       ( quote_identifiers => $p->{quote_identifiers} ) :
                       ()
                     );

    return $schema->sqlmaker(%sqlmaker_p);
}

sub process_where_clause
{
    my ($sql, $where) = @_;

    $where = [ $where ]
        unless Alzabo::Utils::is_arrayref( $where->[0] ) || $where->[0] eq '(';

    my $has_where =
        ( $sql->last_op eq 'where' || $sql->last_op eq 'condition' ) ? 1 : 0;

    _process_conditions( $sql, $has_where, $where, 'where' );
}

sub process_having_clause
{
    my ($sql, $having) = @_;

    $having = [ $having ]
        unless Alzabo::Utils::is_arrayref( $having->[0] ) || $having->[0] eq '(';

    my $has_having =
        ( $sql->last_op eq 'having' || $sql->last_op eq 'condition' ) ? 1 : 0;

    _process_conditions( $sql, $has_having, $having, 'having' );
}

sub _process_conditions
{
    my ($sql, $has_start, $conditions, $needed_op) = @_;

    my $needs_op = $sql->last_op eq 'where' || $sql->last_op eq 'having' ? 0 : 1;

    if ($has_start)
    {
        # wrap this in parens in order to protect from interactions with
        # join clauses
        $sql->and if $needs_op;

        $sql->subgroup_start;

        $needs_op = 0;
    }

    my $x = 0;
    foreach my $clause (@$conditions)
    {
        if (ref $clause)
        {
            Alzabo::Exception::Params->throw
                ( error => "Individual where clause components must be array references" )
                    unless Alzabo::Utils::is_arrayref($clause);

            Alzabo::Exception::Params->throw
                ( error => "Individual where clause components cannot be empty" )
                    unless @$clause;

            if ($needs_op)
            {
                my $op = $x || $has_start ? 'and' : $needed_op;
                $sql->$op();
            }

            $sql->condition(@$clause);
            $needs_op = 1;
        }
        elsif (lc $clause eq 'and' || lc $clause eq 'or')
        {
            $sql->$clause();
            $needs_op = 0;
            next;
        }
        elsif ($clause eq '(')
        {
            if ($needs_op)
            {
                my $op = $x || $has_start ? 'and' : $needed_op;
                $sql->$op();
            }
            $sql->subgroup_start;
            $needs_op = 0;
        }
        elsif ($clause eq ')')
        {
            $sql->subgroup_end;
            $needs_op = 1;
        }
        else
        {
            Alzabo::Exception::Params->throw( error => "Invalid where clause specification: $clause" );
        }
        $x++;
    }

    $sql->subgroup_end if $has_start;
}

sub process_order_by_clause
{
    _process_by_clause(@_, 'order');
}

sub process_group_by_clause
{
    _process_by_clause(@_, 'group');
}

sub _process_by_clause
{
    my ($sql, $by, $type) = @_;

    my @items;
    if ( Alzabo::Utils::safe_isa( $by, 'Alzabo::Column' ) || Alzabo::Utils::safe_isa( $by, 'Alzabo::SQLMaker::Function' ) )
    {
        @items = $by;
    }
    elsif ( Alzabo::Utils::is_arrayref($by) )
    {
        @items = @$by;
    }

    my $method = "${type}_by";
    $sql->$method(@items);
}



__END__

=head1 NAME

Alzabo::Runtime - Loads all Alzabo::Runtime::* classes

=head1 SYNOPSIS

  use Alzabo::Runtime qw( schema_name );

=head1 DESCRIPTION

Using this module loads Alzabo::Runtime::* modules.

These modules are what an end user of Alzabo uses to instantiate
objects representing data in a given schema.

=head1 import METHOD

This method is called when you C<use> this class.  You can pass an
array of strings to the module via the C<use> function.  These strings
are assumed to be the names of schema objects that you want to load.
This can be useful if you are running under a mod_perl (or similar)
environment and has the potential to save some memory by preloading
the objects before a fork, hopefully increasing shared memory.

This method explicitly ignores errors that may occur when trying to
load a particular schema.  This means that later attempts to retrieve
that schema will probably also fail.  This is done so that the
application that wants a particular schema can explicitly handle the
failure later on.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
