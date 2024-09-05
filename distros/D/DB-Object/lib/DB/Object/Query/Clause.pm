##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Query/Clause.pm
## Version v1.0.1
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/07/08
## Modified 2024/09/04
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DB::Object::Query::Clause;
BEGIN
{
    use strict;
    use common::sense;
    use parent qw( DB::Object::Query::Elements );
    use vars qw( $VERSION );
    use overload (
        '""'    => 'as_string',
        'bool'  => sub{1},
        fallback => 1,
    );
    our $VERSION = 'v1.0.1';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{generic}    = '';
    $self->{operator}   = '';
    $self->{type}       = '';
    $self->{value}      = '';
    $self->{_init_strict_use_sub} = 1;
    # $self->{fields} = [];
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{_clause_reset} = '';
    return( $self );
}

sub as_string
{
    # no overloading;
    my $self = shift( @_ );
    my $fields = $self->fields;
    if( $self->generic->length && $self->query_object->table_object->use_bind )
    {
        return( $self->{_cache_clause_generic} ) if( $self->{_cache_clause_generic} && !CORE::length( $self->{_reset} // '' ) );
        CORE::delete( $self->{_reset} );
        return( $self->{_cache_clause_generic} = $self->generic ) if( !$fields->length );
        return( $self->{_cache_clause_generic} = Module::Generic::Scalar->new( CORE::sprintf( $self->generic, @$fields ) ) );
    }
    return( $self->{_cache_clause} ) if( $self->{_cache_clause} && !CORE::length( $self->{_reset} // '' ) );
    CORE::delete( $self->{_reset} );
    my $str = $self->value;
    # return( $str ) if( !$fields->length );
    return( $self->{_cache_clause} = $str ) if( !length( $str // '' ) || $str !~ /(?<!\%)\%\s\d/ );
    # Stringification of the fields will automatically format them properly, ie with a table prefix, schema prefix, database prefix as necessary
    return( $self->{_cache_clause} = Module::Generic::Scalar->new( CORE::sprintf( $str, @$fields ) ) );
}

# sub bind
# {
#     return( shift->_set_get_class( 'bind', 
#     {
#         # The sql types of the value bound to the placeholders
#         types => { type => 'array_as_object' },
#         # The values bound to the placeholders in the sql clause
#         values => { type => 'array_as_object' },
#     }, @_ ) );
# }
sub bind { warn( "Call to ", ref( $_[0] ), "->bind is now deprecated." ); }

# sub fields { return( shift->_set_get_array_as_object( 'fields', @_ ) ); }
# NOTE: sub fields is inherited from DB::Object::Query::Elements

sub generic { return( shift->_set_get_scalar_as_object( 'generic', @_ ) ); }

sub length { return( shift->value->length ); }

sub metadata { return( shift->_set_get_hash_as_object( 'metadata', @_ ) ); }

# NOTE: sub merge supersedes the one inherited from DB::Object::Query::Elements
# This takes or or more values and merge its clauses and the binded parameters
sub merge
{
    my $self = shift( @_ );
    if( @_ )
    {
        # By default
        my $op = 'AND';
        my @params = ();
        # $clause->merge( $dbh->OR( $clause1, $clause2, $clause3 ) );
        # or just
        # $clause->merge( $clause1, $clause2, $clause3 );
        if( $self->_is_object( $_[0] ) && $_[0]->isa( 'DB::Object::Operator' ) )
        {
            my $op_obj = shift( @_ );
            return( $self->error( "Database Object operator provided is invalid. It should be either an AND or OR." ) ) if( $op_obj->operator ne 'AND' and $op_obj->operator ne 'OR' and $op_obj->operator ne 'NOT' );
            $op = $op_obj->operator;
            @params = grep( !$self->_is_a( 'DB::Object::Fields::Unknown' ), $op_obj->value );
        }
        else
        {
            @params = @_;
        }
        
        my @clause = ();
        @clause = ( $self->value ) if( $self->value->length > 0 );
        my @generic = ();
        @generic = ( $self->generic ) if( $self->generic->length > 0 );
        my $elems = $self->elements;
        foreach my $this ( @params )
        {
            # Safeguard against garbage
            # Special treatment for DB::Object::Fields::Overloaded who are already formatted
            if( $self->_is_a( $this => [qw( DB::Object::Fields::Overloaded DB::Object::Expression )] ) )
            {
                push( @clause, $this );
                next;
            }
            
            next if( !$self->_is_a( $this => 'DB::Object::Query::Clause' ) );
            # First check we even have a clause, otherwise skip
            if( !$this->value->length )
            {
                CORE::next;
            }
            # where, order, group, limit etc...
            if( $self->type->length && $this->type->length && $this->type ne $self->type )
            {
                return( $self->error( "This clause provided for merge is not of the same type \"", $this->type, "\" as ours \"", $self->type, "\"." ) );
            }
            # Possibly our type is empty and if so, we initiate it by using the type of the first object we find
            # This makes it convenient to merge without having to set the type beforehand like so:
            # $clause->type( 'where' );
            # $clause->merge( $w1, $w2, $e3 );
            # We can do instead
            # $clause->merge( $w1, $w2, $e3 );
            # And it will take the type from $w1
            $self->type( $this->type ) if( !$self->type->length );
            if( !$this->operator->is_empty && $this->operator ne $op )
            {
                CORE::push( @clause, '( ' . $this->value . ' )' );
            }
            else
            {
                CORE::push( @clause, $this->value );
            }
            
            if( !$this->generic->is_empty )
            {
                if( !$this->operator->is_empty && $this->operator ne $op )
                {
                    CORE::push( @generic, '( ' . $this->generic . ' )' );
                }
                else
                {
                    CORE::push( @generic, $this->generic );
                }
            }
            
            # we just stack them, and later we will sort them by their object property 'index' value.
            $this->elements->for(sub
            {
                my( $i, $v ) = @_;
                # This is perfectly ok. It just means there is nothing at this offset
                if( !defined( $v ) )
                {
                    return;
                }
                # If an entry with same index is provided, it overwrite the previous one.
#                 elsif( $v->is_numbered )
#                 {
#                     $elems->[$i] = $v;
#                 }
#                 else
#                 {
#                     $elems->push( $v );
#                 }
                $elems->push( $v );
            });
            
#             $self->fields->push( @{$this->fields} ) if( $this->fields->length );
#             $self->bind->types->push( @{$this->bind->types} ) if( $this->bind->types->length );
#             $self->bind->values->push( @{$this->bind->values} ) if( $this->bind->values->length );
            my $ref = $this->metadata;
            my $hash = $self->metadata;
            foreach my $k ( keys( %$ref ) )
            {
                $hash->{ $k } = $ref->{ $k } if( !CORE::exists( $hash->{ $k } ) );
            }
            $self->metadata( $hash );
        }
        $self->value( CORE::join( " $op ", @clause ) );
        $self->generic( CORE::join( " $op ", @generic ) );
        $self->operator( $op );
    }
    return( $self );
}

sub operator { return( shift->_set_get_scalar_as_object( 'operator', @_ ) ); }

# NOTE: sub push is inherited from DB::Object::Query::Elements

# NOTE: sub query_object is inherited from DB::Object::Query::Elements

# NOTE: sub reset is inherited from DB::Object::Query::Elements

# The clause type e.g. where, order, group, having, limit, etc
sub type { return( shift->_set_get_scalar_as_object( 'type', @_ ) ); }

# NOTE: sub types is inherited from DB::Object::Query::Elements

# The string value of the clause
sub value { return( shift->_set_get_scalar_as_object( 'value', @_ ) ); }

# NOTE: sub values is inherited from DB::Object::Query::Elements

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

DB::Object::Query::Clause - SQL Query Clause Object

=head1 SYNOPSIS

    my $clause = DB::Object::Query::Clause->new({
        value => "$field != '$user'",
        generic => "$field != ?",
        type => 'where',
        # or possibly:
        # bind => 
        # {
        #     values => $values_array_ref,
        #     types => $types_array_ref
        # }
    })
    # A DB::Object::Query object
    $clause->query_object( $q );
    $clause->bind->values( $res );
    $clause->bind->types( '' );
    $clause->fields( $field ) if( Scalar::Util::blessed( $field ) && $field->isa( 'DB::Object::Fields::Field' ) );

Merging multiple clauses

    $clause = DB::Object::Query::Clause->new->merge( $dbh->AND( @clauses ) );
    $clause->bind->values( @values ) if( $bind );
    $clause->bind->types( @types ) if( $bind );

Get the clause stringified

    my $sql = "SELECT * FROM my_table WHERE $clause";

This could become something like:

    SELECT * FROM my_table WHERE username != 'joe' AND username != 'bob'

However if binding values is activated, this would rather become:

    SELECT * FROM my_table WHERE username != ? AND username != ?

And the associated values would be automatically bound to the query upon execution

=head1 VERSION

v1.0.1

=head1 DESCRIPTION

The purpose of this module is to contain various attributes of a SQL clause so that it can be accessed and manipulated flexibly.

It will not create SQL query. This is done by the calling module and the query is stored in the I<value> parameter which is also the L</"value"> method

This is used to contain clauses such as I<group>, I<having>, I<limit>, I<order>, I<where>

=head1 METHODS

=head2 new

It can take the following properties that can also be accessed as method:

=over 4

=item C<value>

The sql query fragment string

=item C<generic>

The sql fragment with placeholders, for example:

    username = ?

=item C<bind>

Provided a hash with the following properties:

=over 8

=item C<values>

The values to bind as an array reference

=item C<types>

The SQL types of the values to bind as an array reference

=back

=back

=head2 as_string

This returns the clause as a string.

This is also called when the object is used as a string

    print( "SQL query is: SELECT * FROM my_table WHERE $clause\n")

If field objects were used such as:

    $dbh->NOT( $user_tbl->fo->username => 'Bob' );

Then if needed, B<as_string> would prefix the field name with its associated table name

=head2 fields

An array reference of field objects (L<DB::Object::Fields::Field>)

The array itself is an object from L<Module::Generic::Array>

=head2 generic

Returns a string representing the SQL fragment with placeholder.

The string returned is an object of L<Module::Generic::Scalar>

=head2 length

Returns the length of the string in L</"value">

=head2 metadata

Set or get an hash reference accessible as a dynamic class object from L<DB::Object::Query::Clause::Metadata>

=head2 merge

Given an array of clauses, this will merge them into one new clause object.

If the first value of the array is a L<DB::Object::Operator> such as L<DB::Object::Operator::AND> or L<DB::Object::Operator::OR>, the list will be taken from this object and the resulting sql statement will the operator value, ie C<AND> or C<OR> for example

=head2 operator

Sets or get the operator used in this clause, if any.

=head2 push

This is inherited from the L<DB::Object::Query::Elements>.

This is used to add elements.

=head2 query_object

Set or get the L<DB::Object::Query> object, which normally would have created this clause object.

=head2 type

Set or get the type of clause this is, such as I<group>, I<having>, I<limit>, I<order>, I<where>

The return value is a string that can be accessed as an object of L<Module::Generic::Scalar>

=head2 types

This is inherited from the L<DB::Object::Query::Elements>.

This is used to get the type of all elements, as an L<array object|Module::Generic::Array>

=head2 value

The SQL fragment as a string. The return value is a string that can be accessed as an object of L<Module::Generic::Scalar>

=head2 values

This is inherited from the L<DB::Object::Query::Elements>.

This is used to get the value of all elements, as an L<array object|Module::Generic::Array>

=head1 SEE ALSO

L<DB::Object::Query>, L<DB::Object::Mysql::Query>, L<DB::Object::Postgres::Query>, L<DB::Object::SQLite::Query>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2019-2023 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
