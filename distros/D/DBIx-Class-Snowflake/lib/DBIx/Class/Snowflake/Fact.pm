package DBIx::Class::Snowflake::Fact;
our $VERSION = '0.10';


=head1 NAME

DBIx::Class::Snowflake::Fact

=head1 VERSION

version 0.10

=head1 ABSTRACT

DBIx::Class::Snowflake::Fact - Load this for any fact tables.

=cut

use strict;
use warnings;
use diagnostics;

use base qw( DBIx::Class::Snowflake );

=head1 NAME

DBIx::Class::Fact - Make your table a star/snowflake fact table

=head1 SYNOPSIS

  __PACKAGE__->load_components(qw/ Snowflakee::Fact /);

=head1 DESCRIPTION

Component for DBIx::Class that makes it easier to develop star or snowflake schemas.
This will provide the class with useful accessors to get a list of dimensions and easily search given a dimension.

=head1 METHODS

=cut

=head2 attributes

Returns the attributes of the fact excluding any ignore columns.
It returns them as an array containing hashes each
containing the data type and the accesssor name.

=cut

=head2 attrs

Convenience alias to attributes

=cut 
sub attrs
{
    shift->attributes(@_);
}

=head2 generate_report

B<generate_report> returns a resultset for the report requested.  
Each item in the array is a row in the report and each element in 
the hash is one of the metrics requested.

Usage:
    $fact->generate_report({'filters' => {'dimdate.day_of_week' => 3}, 'metric' => {'dimline.line_velocity' => 1}})

=cut
sub generate_report
{
    my $self    = shift;
    my $hash    = shift;
    my $filters = $hash->{'filters'};
    my $metrics = $hash->{'metric'};
    my ($temp, $results, %row, @joins, @names);

    $metrics = $self->_resolve_types( $metrics );
    $filters = $self->_resolve_types( $filters );

    #convert our WHERE
    foreach my $attr ( keys( %{$filters->{'dimensions'}} ) )
    {
        $temp =
           $self->_resolve_dimension_to_attribute( $attr,
            $filters->{'dimensions'}{$attr} );
        if ( defined($temp) )
        {
            $filters->{'attributes'} = {%{$filters->{'attributes'}}, %{$temp}};
        }
        else
        {
            $self->throw_exception("Unable to resolve dimension '$attr', does not exist in snowflake.");
        }
    }

    #convert our SELECT
    foreach my $metric ( keys( %{$metrics->{'dimensions'}} ) )
    {
        my $temp = $self->_resolve_metrics($metric);
        if( defined($temp) )
        {
            push( @names, pop(@$temp) );
            push( @joins, $temp );
        }
        else
        {
            $self->throw_exception("Unable to resolve dimension '$metric', does not exist in snowflake.");
        }
    }

    $self->_convert_joins(\@joins);

    $results = $self->result_source->resultset->search(
        $filters->{'attributes'},
        {
            'join'    => \@joins,
            '+select' => \@names
        }
    );
}

sub _convert_joins
{
    my $self  = shift;
    my $joins = shift;

    foreach my $join (@$joins)
    {
        # if there is only 1 or 0 elements then don't worry about it, it's formatted
        if ( @$join > 1 )
        {
            # temp is what our join will be when we are done building it
            my $temp;
            if ( @$join > 2 )
            {
                # inner temp is going to always reference the deepest embedded hash while
                # we loop
                my $inner_temp = {};
                # temp references the top of this structure
                $temp       = $inner_temp;
                my $join_part = 0;
                # we don't want the last two elements because the second to last element
                # is going to an array ref instead of a hash ref and the last element is
                # going to be a scalar.
                foreach $join_part ( 0 .. @$join - 3 )
                {
                    $inner_temp->{ $join->[$join_part] } = {};
                    $inner_temp = $inner_temp->{ $join->[$join_part] };
                }
                # the last step is to make the deepest hash contain a key,value of the
                # second to last element with the value being an arrayref that contains
                # only the last element
                $inner_temp->{ $join->[ $join_part + 1 ] } = [ $join->[-1] ];
            }
            else # there are only two elements
            {
                # simple edge case, just makes { 'foo' => [ 'bar' ] }
                $temp = { $join->[0] => [ $join->[1] ] };
            }
            $join = $temp;
        }
    }
    return $joins;
}

=head2 _resolve_types

The resolve types subroutine attempts to determine if the value passed
in is the name of a dimension or an attribute given the columns of
the current table.

In this case the term attribute is described as column on a fact table
that does not reference another table.  So, if there was a fact table
fact_produced that had two columns, date_id and widget_id, and date referred
to the date_id column of the date table which had a column dow and widget_id did not refer to
anything then the following call:
$fact->_resolve_types({'dow' => 3, 'widget_id' => 6});
the following hash would be returned:
{ 'attributes' => { 'widget_id' => 6}, 'dimensions' => { 'dow' => 3 }}

B<NOTE> If the column does not exist it assumes it is a dimension, IT
DOES NOT SEARCH FOR IT TO VERIFY.
=cut
sub _resolve_types
{
    my $self = shift;

    # list of possibly dimensions, possibly attributes
    my $dimensions = shift;
    my %columns    = $self->_columns_as_hash();
    my ( %attrs, %dims );
    foreach my $dim ( keys(%$dimensions) )
    {
        if ( defined( $columns{$dim} ) )
        {
            $attrs{$dim} = $dimensions->{$dim};
        }
        else
        {
            $dims{$dim} = $dimensions->{$dim};
        }
    }
    return { 'attributes' => \%attrs, 'dimensions' => \%dims };
}

1;