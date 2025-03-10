##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Query/Elements.pm
## Version v0.1.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/07/08
## Modified 2023/07/08
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DB::Object::Query::Elements;
BEGIN
{
    use strict;
    use common::sense;
    use parent qw( Module::Generic );
    use vars qw( $VERSION );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{elements} = [];
    $self->{query_object} = undef;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{_cache_fields}  = '';
    $self->{_cache_formats} = '';
    $self->{_cache_types}   = '';
    $self->{_cache_values}  = '';
    return( $self );
}

# This is used to forward unknown method to Module::Generic::Array
sub autoload
{
    my $self = shift( @_ );
    my $meth = shift( @_ ) || return;
    my $elems = $self->elements || return;
    my $code;
    if( $code = $elems->can( $meth ) )
    {
        no strict 'refs';
        my $sub = sub
        {
            my $this = shift( @_ );
            return( $code->( $this->elements, @_ ) );
        };
        *$meth = $sub;
        return( $sub );
    }
    warn( "No method '$meth' supported by this class ", ref( $self ), " or by ", ref( $elems ) );
    return;
}

# NOTE: sub clone is inherited from Module::Generic

sub elements { return( shift->reset(@_)->_set_get_object_array_object( 'elements', 'DB::Object::Query::Element', @_ ) ); }

sub fields
{
    my $self = shift( @_ );
    return( $self->{_cache_fields} ) if( $self->{_cache_fields} && !CORE::length( $self->{_reset} // '' ) );
    my $arr = $self->new_array;
    my $e = $self->elements;
    $e->foreach(sub
    {
        my $o = shift( @_ );
        $arr->push( defined( $o ) ? $o->field : undef );
    });
    $self->{_cache_fields} = $arr;
    CORE::delete( $self->{_reset} );
    return( $arr );
}

sub for { return( shift->elements->for( @_ ) ); }

sub foreach { return( shift->elements->foreach( @_ ) ); }

sub formats
{
    my $self = shift( @_ );
    return( $self->{_cache_formats} ) if( $self->{_cache_formats} && !CORE::length( $self->{_reset} // '' ) );
    my $arr = $self->new_array;
    my $e = $self->elements;
    $e->foreach(sub
    {
        my $o = shift( @_ );
        $arr->push( defined( $o ) ? $o->format : undef );
    });
    $self->{_cache_formats} = $arr;
    CORE::delete( $self->{_reset} );
    return( $arr );
}

sub generics
{
    my $self = shift( @_ );
    return( $self->{_cache_generics} ) if( $self->{_cache_generics} && !CORE::length( $self->{_reset} // '' ) );
    my $arr = $self->new_array;
    my $e = $self->elements;
    $e->foreach(sub
    {
        my $o = shift( @_ );
        $arr->push( defined( $o ) ? $o->generic : '?' );
    });
    $self->{_cache_generics} = $arr;
    CORE::delete( $self->{_reset} );
    return( $arr );
}

sub is_empty { return( shift->elements->is_empty ); }

sub length { return( shift->elements->length ); }

# This merge one or more objects of the same class into this one
sub merge
{
    my $self = shift( @_ );
    my $elems = $self->elements;
    CORE::foreach my $this ( @_ )
    {
        if( !$self->_is_a( $this => 'DB::Object::Query::Elements' ) )
        {
            warn( "Element provided '", overload::StrVal( $this ), "' is not an DB::Object::Query::Elements or DB::Object::Query::Clause object" );
            next;
        }
        
        $elems->push( $this->elements->list );
    }
    # Make sure our elements are in the right order
    $self->_sort;
    $self->reset(1) if( scalar( @_ ) );
    return( $self );
}

sub new_element
{
    my $self = shift( @_ );
    my $el = $self->query_object->new_element( @_ ) ||
        return( $self->pass_error( $self->query_object->error ) );
    return( $el );
}

sub push
{
    my $self = shift( @_ );
    my $e = $self->elements;
    CORE::foreach my $elem ( @_ )
    {
        my( $o );
        # This works also for DB::Object::Query::Clause that inherits from DB::Object::Query::Elements
        if( $self->_is_a( $elem => 'DB::Object::Query::Elements' ) )
        {
            $self->push( $elem->elements->list );
            next;
        }
        elsif( $self->_is_a( $elem => 'DB::Object::Query::Element' ) )
        {
            $o = $elem;
        }
        elsif( ref( $elem ) eq 'HASH' )
        {
            $o = $self->new_element( %$elem ) || return( $self->pass_error );
        }
        else
        {
            return( $self->error( "Unknown value '", ( $elem // 'undef' ), "' to add as element to our clause elements stack." ) );
        }
        
        # Order does not really matter, we just stack them, and after we will sort them by their object property 'index' value, if necessary
        $e->push( $o );
    }
    # Make sure our elements are in the right order
    $self->_sort;
    $self->reset(1) if( scalar( @_ ) );
    return( $self );
}

sub query_object { return( shift->_set_get_object( 'query_object', 'DB::Object::Query', @_ ) ); }

sub reset
{
    my $self = shift( @_ );
    if( !CORE::length( $self->{_reset} // '' ) && scalar( @_ ) )
    {
        $self->{_reset} = scalar( @_ );
    }
    return( $self );
}

sub sort
{
    my $self = shift( @_ );
    my $elems = $self->elements->sort(sub
    {
        my( $a, $b ) = @_;
        return( $a->index <=> $b->index );
    });
    my $clone = $self->clone;
    $clone->elements( $elems );
    return( $clone );
}

sub types
{
    my $self = shift( @_ );
    return( $self->{_cache_types} ) if( $self->{_cache_types} && !CORE::length( $self->{_reset} // '' ) );
    my $arr = $self->new_array;
    my $e = $self->elements;
    $e->foreach(sub
    {
        my $o = shift( @_ );
        $arr->push( defined( $o->type ) ? $o : undef );
    });
    $self->{_cache_types} = $arr;
    CORE::delete( $self->{_reset} );
    return( $arr );
}

sub values
{
    my $self = shift( @_ );
    return( $self->{_cache_values} ) if( $self->{_cache_values} && !CORE::length( $self->{_reset} // '' ) );
    my $arr = $self->new_array;
    my $e = $self->elements;
    $e->foreach(sub
    {
        my $o = shift( @_ );
        $arr->push( defined( $o ) ? $o->value : undef );
    });
    $self->{_cache_values} = $arr;
    CORE::delete( $self->{_reset} );
    return( $arr );
}

sub _sort
{
    my $self = shift( @_ );
    my $e = $self->elements;
    my $el;
    # We check the first element to decide whether the placeholders, if any, are numbered or not.
    $e->foreach(sub
    {
        my $this = shift( @_ );
        if( $self->_is_object( $this ) && 
            $self->_can( $this => 'is_numbered' ) &&
            $this->is_numbered )
        {
            $el = $this;
            return(0);
        }
    });
    if( $el && $el->placeholder && $el->is_numbered )
    {
        my $sorted = $self->sort->elements;
        $self->elements( $sorted ) if( $sorted );
    }
    return( $self );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

DB::Object::Query::Elements - Query Elements Manipulation Class

=head1 SYNOPSIS

    use DB::Object::Query::Elements;
    my $elems = DB::Object::Query::Elements->new( debug => 4 ) || 
        die( DB::Object::Query::Elements->error, "\n" );
    $elems->push( $new_element );
    $elems->push({
        field => $some_field_name,
        value => $some_field_value,
        type  => $sql_type,
        format => $insert_formatting,
        # Could also be $1, $2, ?1, ?2, or other variants supported by driver
        placeholder => '?',
    });
    $elems->merge( $other_elements_object );
    # Clause class inherits from Elements class
    $elems->merge( $some_clause_object );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class represent a query manipulation class designed to access, store and retrieve L<query elements|DB::Object::Query::Element>

Elements are stored in an internal array object accessible with L</elements>, and all the other methods are used to access or manipulate those elements data.

=head1 CONSTRUCTOR

=head2 new

Takes an hash or hash reference of key-value pairs matching any of the methods below.

Returns a newly instantiated object upon success, or sets an L<error|Module::Generic/error> and return C<undef> or an empty list, depending on the caller's context.

=head1 METHODS

=for Pod::Coverage autoload

=head2 elements

Sets or gets an L<array object|Module::Generic::Array> of L<DB::Object::Query::Element> objects.

=head2 fields

Read-only. Returns an L<array object|Module::Generic::Array> of all the elements L<field|DB::Object::Query::Element/field> property.

=head2 for

This is a shortcut for calling L<Module::Generic::Array/for> on this class L</elements>

=head2 foreach

This is a shortcut for calling L<Module::Generic::Array/foreach> on this class L</elements>

=head2 formats

Read-only. Returns an L<array object|Module::Generic::Array> of all the elements L<format|DB::Object::Query::Element/format> property.

=head2 generics

Read-only. Returns an L<array object|Module::Generic::Array> of all the elements L<generic|DB::Object::Query::Element/generic> representation.

=head2 is_empty

This is a shortcut for calling L<Module::Generic::Array/is_empty> on this class L</elements>

=head2 length

This is a shortcut for calling L<Module::Generic::Array/length> on this class L</elements>

=head2 merge

Provided with one or more L<DB::Object::Query::Elements> objects (including L<DB::Object::Query::Clause> objects that inherit from L<DB::Object::Query::Elements>), and this will merge those objects into this current object.

If the underlying elements are numbered placeholders such as C<$1>, C<$2>, or C<?1>, C<?2>, then they will be properly sorted internally.

It returns the current object.

=head2 new_element

Provided with an hash or hash reference of parameter, and this will instantiate a new L<DB::Object::Query::Element> object and return it.

If an error occurred, such as if bad parameters were provided, an L<error object|Module::Generic/error> is set and C<undef>, or an empty list depending on the context, is returned.

=head2 push

Provided with objects of classes L<DB::Object::Query::Elements> or L<DB::Object::Query::Element>, or alternatively an hash reference of property-value pairs needed to instantiate a new L<DB::Object::Query::Element>, and this will add those objects to the stack of elements managed by this class.

If the underlying elements are numbered placeholders such as C<$1>, C<$2>, or C<?1>, C<?2>, then they will be properly sorted internally.

It returns the current object.

=head2 query_object

Sets or gets the L<DB::Object::Query> object set for this object.

=head2 reset

Various methods return cached value once they have been computed for improved performance. Calling C<reset> will force re-computing next time either one is called.

Those methods are L</fields>, L</formats>, L</types> and L</values>

=head2 sort

Returns a new clone of the current L<DB::Object::Query::Elements> object with its elements sorted based on their L<index property|DB::Object::Query::Element/index>

=head2 types

Read-only. Returns an L<array object|Module::Generic::Array> of all the elements L<type|DB::Object::Query::Element/type> property.

=head2 values

Read-only. Returns an L<array object|Module::Generic::Array> of all the elements L<value|DB::Object::Query::Element/value> property.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<DB::Object::Query>, L<DB::Object::Query::Clause>, L<DB::Object::Query::Element>, L<DB::Object>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2023 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
