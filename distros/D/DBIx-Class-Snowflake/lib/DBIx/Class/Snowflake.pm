package DBIx::Class::Snowflake;
our $VERSION = '0.10';


=head1 NAME

DBIx::Class::Snowflake

=head1 VERSION

version .04

=cut

# ABSTRACT: Easily use DBIC with snowflake schemas.

use strict;
use warnings;
use diagnostics;

use base 'DBIx::Class';

my %ignores;

=head2 ignore_columns

B<ignore_columns> sets the columnns to be ignored.  Please see the manual
L<DBIx::Class::Snowflake::Manual> for further explanation.

=cut
sub ignore_columns
{
    my ( $self, $class ) = _normalize_location_for_ignore_columns(shift);
    my $ic = shift;

    if ( not defined( $ignores{$class} ) )
    {
        $ignores{$class} = {};
    }

    if ( ref($self) )
    {
        $self->{'_ignore_columns'} = $self->_make_ignore_hash($ic);
        return { %{ $self->{'_ignore_columns'} }, %{ $ignores{$class} } };
    }
    else
    {
        $ignores{$class} = $self->_make_ignore_hash($ic);
        return $ignores{$class};
    }

}

sub _normalize_location_for_ignore_columns
{
    my $self = shift;
    my $class = ref($self) || $self;
    if ( $class =~ /ResultSet/ )
    {
        $self  = $self->result_class;
        $class = $self;
    }
    return ( $self, $class );
}

=head2 get_ignore_columns

Returns the ignored columns in the internal representation without modifying
them.  Please see L<DBIx::Class::Snowflake::Manual> for more information.

=cut
sub get_ignore_columns
{
    my ( $self, $class ) = _normalize_location_for_ignore_columns(shift);
    my $ic = shift;

    if ( not defined( $ignores{$class} ) )
    {
        $ignores{$class} = {};
    }

    if ( ref($self) and ref( $self->{'_ignore_columns'} ) )
    {
        return { %{ $self->{'_ignore_columns'} }, %{ $ignores{$class} } };
    }
    else
    {
        return $ignores{$class};
    }
}

sub _make_ignore_hash
{
    my $self   = shift;
    my $ignore = shift;
    my %list;
    my $ref;

    $ref = ref($ignore);

    if ( defined $ignore )
    {
        if ( not $ref )
        {
            $list{$ignore} = 1;
        }
        elsif ( $ref eq 'ARRAY' )
        {
            %list = map( { $_ => 1 } @$ignore );
        }
        elsif ( $ref eq 'HASH' )
        {
            %list = %$ignore;
        }
        elsif ( $ref eq 'SCALAR' )
        {
            $list{$$ignore} = 1;
        }
        elsif ( $ref eq 'CODE' )
        {
            %list = %{ $self->_make_ignore_hash( &$ignore() ) };
        }
        else
        {
            $self->throw_exception( "Unable to determine what columns to ignore, I don't know what to do with a '$ref'."
            );
        }
    }
    return \%list;
}

=head2 _resolve_metrics

The B<resolve_values> subroutine will recursively walk through the dimensions
of a fact until it finds the column for the values we are looking for.  It
will then return an array that indicates the steps to take in the SQL query
to get to that dimension.

For example, assume there is a fact_produced table and it had a dim_date table with
a column for the day of the week (dow) and dim_date is a dimension of fact_produced.
This call:
 $produced->_resolve_metrics('dow'); 
would result in a reference to an array like so:
[ fact_produced, dim_date, dow ]

=cut

sub _resolve_metrics
{
    my $self         = shift;
    my $metric       = shift;
    my $relationship = shift;
    my @stack;
    my $ignores = $self->get_ignore_columns();
    my ( $needed_prefix, $needed_column ) = split( /\./, $metric );
    my $prefix = $self->_get_result_source->from();
    if ( not defined $needed_column )
    {
        $needed_column       = $needed_prefix;
        $needed_prefix = undef;
    }

    if (
        $self->_stop_search(
            $needed_prefix, $needed_column, $prefix, $ignores
        )
       )
    {

		$metric =  "$relationship.$needed_column" if( defined $relationship );
        unshift( @stack, $metric );
        return \@stack;
    }
    else
    {
        return $self->_keep_looking( $metric, $ignores );
    }
}

sub _get_rel
{
    my $self   = shift;
    my $source = shift;
    my $column = shift;

    if ( not $source->has_relationship($column) )
    {
        return undef;
    }

    return $source->relationship_info($column)->{'source'};
}

sub _keep_looking
{
    my $self    = shift;
    my $metric  = shift;
    my $ignores = shift;

    my $stack;
    my $source = $self->_get_result_source;
    my $rel_source;

    foreach my $column ( $source->columns )
    {
        if ( not $ignores->{$column} )
        {
            if ( $rel_source = $self->_get_rel( $source, $column ) )
            {
                $stack =
                   $self->result_source->schema->resultset($rel_source)
                   ->_resolve_metrics( $metric, $column );
                if ( defined $stack )
                {
                    unshift( @$stack, $column );
                    last;
                }
            }
        }
    }
    return $stack;
}

sub _stop_search
{
    my $self          = shift;
    my $needed_prefix = shift;
    my $needed_column = shift;
    my $prefix        = shift;
    my $ignores       = shift;
    my %columns       = $self->_columns_as_hash();
    return (
        (
            not defined $needed_prefix
               or $needed_prefix eq $prefix
        )
           and $columns{$needed_column}
           and not $ignores->{$needed_column}
    );
}

=pod

This function recursively calls itself until it finds 

=cut

sub _resolve_dimension_to_attribute
{
    my $self      = shift;
    my $attribute = shift;
    my $value     = shift;
    my $depth     = shift || 0;
    my $relation  = shift || '';
    my ( %columns, @ret_values, $ret_values, $column );
    my $ignores = $self->get_ignore_columns();
    my $source  = $self->_get_result_source();
    my $pk      = ( $source->primary_columns() )[0];
    my ( $needed_prefix, $needed_column ) = split( /\./, $attribute );
    my $prefix = $source->from();
    my $rel_source;

    if ( not defined $needed_column )
    {
        $needed_column       = $needed_prefix;
        $needed_prefix = undef;
    }

    %columns = $self->_columns_as_hash();

    if (
        $self->_stop_search(
            $needed_prefix, $needed_column, $prefix, $ignores
        )
       )
    {
        @ret_values = $self->result_source->resultset->search(
            { $needed_column => $value } )->get_column($pk)->all();
        if ( $depth == 0 )
        {
            return { 'me.' . $needed_column => \@ret_values };
        }
        else
        {
            return \@ret_values;
        }
    }

    if ( not @ret_values )
    {
        foreach $column ( $source->columns )
        {
            if ( not $ignores->{$column} )
            {
                if ( $rel_source = $self->_get_rel( $source, $column ) )
                {
                    $ret_values =
                       $self->result_source->schema->resultset($rel_source)
                       ->_resolve_dimension_to_attribute( $attribute, $value,
                        $depth + 1, $column );
                }
            }

            if ( $depth != 0 )
            {
                if ( ref($ret_values) eq 'ARRAY' and @$ret_values )
                {
                    @ret_values = $source->resultset->search(
                        { $column => { 'in' => \@$ret_values } } )
                       ->get_column($pk)->all();

                    return \@ret_values;
                }
            }
            else
            {
                if ( ref($ret_values) eq 'ARRAY' and @$ret_values )
                {
                    return { 'me.' . $column => $ret_values };
                }
            }
            last if ( ref($ret_values) eq 'ARRAY' and @$ret_values );
        }
    }

    return undef;
}

=head2 attributes

Goes through all of the columns, determines if they are to be ignored
if not then it returns them in a large array containing the accessor
and data type of each  column.

=cut

sub attributes
{
    my $self     = shift;
    my $relation = shift;
    my $burnt    = shift || {};

    $burnt->{ ref($self) } = 1;

    my ( @dimensions, $attrs, $ignore_hash, $info, $source, $rel_info );

    $ignore_hash = $self->get_ignore_columns();

    $source = $self->_get_result_source();

    foreach my $dimension ( $source->columns() )
    {
        if ( not $ignore_hash->{$dimension} )
        {
            if ( $source->has_relationship($dimension) )
            {
                $rel_info = $source->relationship_info($dimension);
                if ( not exists( $burnt->{ $rel_info->{'source'} } ) )
                {
                    $attrs =
                       $self->result_source->schema->resultset(
                        $rel_info->{'source'} )
                       ->attributes( $dimension, $burnt );
                    push( @dimensions, @$attrs );
                }
            }
            else
            {
                $info = $source->column_info($dimension);
				$dimension = $source->from() . '.' . $dimension;
                push(
                    @dimensions,
                    {
                        'name' => $dimension,
                        'type' => $info->{'data_type'}
                    }
                );
            }
        }
    }
    return \@dimensions;
}

sub _get_result_source
{
    my $self = shift;
    my $source;
    if ( $self->can('result_source') )
    {
        $source = $self->result_source;
    }
    else
    {
        $source = $self;
    }
    return $source;
}

sub _columns_as_hash
{
    my $self   = shift;
    my $source = $self->_get_result_source();
    return map( { $_ => 1 } $source->columns() );
}
1;
