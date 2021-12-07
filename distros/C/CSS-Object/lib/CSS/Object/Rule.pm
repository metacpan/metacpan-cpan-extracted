##----------------------------------------------------------------------------
## CSS Object Oriented - ~/lib/CSS/Object/Rule.pm
## Version v0.1.3
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/06/21
## Modified 2021/11/28
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package CSS::Object::Rule;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( CSS::Object::Element );
    use Devel::Confess;
    use Want ();
    use overload (
        '""' => 'as_string',
        fallback => 1,
    );
    our $VERSION = 'v0.1.3';
};

sub init
{
    my $self = shift( @_ );
    $self->{format}     = '';
    $self->{properties} = [];
    $self->{selectors}  = [];
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    return( $self );
}

sub add_element
{
	my $self = shift( @_ );
	my $elem = shift( @_ ) || return( $self->error( "No element object was provided to add to this rule." ) );
	return( $self->error( "Element object provided ($elem) is not a CSS::Object::Element object." ) ) if( !$self->_is_a( $elem, 'CSS::Object::Element' ) );
	# $self->message( 3, "Adding element object '$elem'." );
	# $elem->format( $self->format );
	$elem->debug( $self->debug );
	# $self->properties->push( $prop );
	$self->elements->push( $elem );
	return( $self );
}

sub add_property
{
	my $self = shift( @_ );
	my $prop = shift( @_ ) || return( $self->error( "No property object was provided to add to this rule." ) );
	return( $self->error( "Property object provided ($prop) is not a CSS::Object::Property object." ) ) if( !$self->_is_a( $prop, 'CSS::Object::Property' ) );
	# $self->message( 3, "Adding property object '$prop'." );
	# $prop->format( $self->format );
	$prop->debug( $self->debug );
	# $self->properties->push( $prop );
	$self->elements->push( $prop );
	return( $self );
}

sub add_selector
{
	my $self = shift( @_ );
	my $sel  = shift( @_ ) || return( $self->error( "No selector object was provided to add to this rule." ) );
	return( $self->error( "Selector object provided is not a CSS::Object::Selector object." ) ) if( !$self->_is_a( $sel, 'CSS::Object::Selector' ) );
	# $sel->format( $self->format );
	$sel->debug( $self->debug );
    $self->selectors->push( $sel );
    return( $self );
}

sub add_to
{
    my $self = shift( @_ );
    # no overloading;
    my $css  = shift( @_ ) || return( $self->error( "No css object was provided to add our rule to it." ) );
    # my $caller = ( split( /\::/, (caller(1))[3] ) )[-1];
    # $self->message( 3, "Called from '$caller' and css object is '$css'." );
    return( $self->error( "CSS object provided (", overload::StrVal( $css ), ") is not actually a CSS::Object object." ) ) if( !$self->_is_a( $css, 'CSS::Object' ) );
    defined( $css->add_rule( $self ) ) || return( $self->error( "Unable to add our css rule object (", overload::StrVal( $self ), ") to main css object elements stack: ", $css->error ) );
    # $self->message( 3, "Returning our rule object '", overload::StrVal( $self ), "'." );
    return( $self );
}

sub as_string
{
	my $self = shift( @_ );
	# my( $p, $f, $l ) = caller;
	# $self->message( 3, "Stringifying rule called from package $p at line $l in file $f" );
	my $format = $self->format || return( $self->error( "No formatter set to format this rule as string." ) );
	return( $format->rule_as_string( $self ) );
}

sub comments
{
	my $self = shift( @_ );
	return( $self->elements->map(sub{ $_->isa( 'CSS::Object::Comment' ) ? $_ : () }) );
}
sub elements { return( shift->_set_get_object_array_object( 'elements', 'CSS::Object::Element', @_ ) ); }

sub elements_as_string
{
	my $self = shift( @_ );
	my $format = $self->format || return( $self->error( "No format object set to format properties as string." ) );
	return( $format->elements_as_string( $self->elements ) );
}

sub format
{
	my $self = shift( @_ );
	if( @_ )
	{
        # my( $p, $f, $l ) = caller;
        # $self->message( 3, "Rule format called in package $p at line $l in file $f" );
	    my $format = $self->SUPER::format( @_ ) || return( $self->pass_error );
	    # $self->message( 3, "New format set: '$format'." );
	    $self->selectors->foreach(sub
	    {
	        shift->format( $format ) || return;
	    });
	    $self->properties->foreach(sub
	    {
	        shift->format( $format ) || return;
	    });
	    return( $format );
	}
	return( $self->_set_get_object( 'format', 'CSS::Object::Format' ) );
}

sub get_property_by_name
{
    my( $self, $prop_name ) = @_;
    # my $props = $self->properties;
    my $arr = Module::Generic::Array->new;
    # $self->messagef( 3, "There are %d elements in this rule.", $self->elements->length );
    $self->elements->foreach(sub
    {
        my $elem = shift( @_ );
        # $self->message( 3, "Checking this element '$elem'." );
        next if( !$elem->isa( 'CSS::Object::Property' ) );
        # $self->message( 3, "This element is a property with name \"", $elem->name, "\" and does it match our target \"$prop_name\" ?" );
        if( $elem->name eq $prop_name )
        {
            $arr->push( $elem );
        }
    });
    if( Want::want( 'OBJECT' ) )
    {
        rreturn( $arr->length > 0 ? $arr->first : Module::Generic::Null->new );
    }
    elsif( Want::want( 'LIST' ) )
    {
        rreturn( $arr->length > 0 ? $arr->list : () );
    }
    else
    {
        return( $arr->first );
    }
}

# Obsolete. See elements instead which has a wider scope including also comments
# sub properties { return( shift->_set_get_object_array_object( 'properties', 'CSS::Object::Property', @_ ) ); }
sub properties
{
	my $self = shift( @_ );
	return( $self->elements->map(sub{ $self->_is_a( $_, 'CSS::Object::Property' ) ? $_ : () }) );
}

sub properties_as_string
{
	my $self = shift( @_ );
	my $format = $self->format || return( $self->error( "No formatter set to format properties as string." ) );
	return( $format->properties_as_string( $self->properties ) );
}

sub remove_from
{
    my $self = shift( @_ );
    my $css  = shift( @_ ) || return( $self->error( "No css object was provided to remove our rule from it." ) );
    # my $caller = ( split( /\::/, (caller(1))[3] ) )[-1];
    # $self->message( 3, "Called from '$caller' and css object is '$css'." );
    return( $self->error( "CSS object provided (", overload::StrVal( $css ), ") is not actually a CSS::Object object." ) ) if( !$self->_is_a( $css, 'CSS::Object' ) );
    $css->remove_rule( $self );
    return( $self );
}

sub remove_property
{
    my $self = shift( @_ );
    my $prop = shift( @_ );
	return( $self->error( "Property object provided ($prop) is not a CSS::Object::Property object." ) ) if( !$self->_is_a( $prop, 'CSS::Object::Property' ) );
	$self->elements->remove( $prop );
	return( $self );
}

# Array of CSS::Object::Selector objects
sub selectors { return( shift->_set_get_object_array_object( 'selectors', 'CSS::Object::Property', @_ ) ); }

sub selectors_as_string
{
	my $self = shift( @_ );
	my $format = $self->format || return( $self->error( "No formatter set to format selectors as string." ) );
	return( $format->selectors_as_string( $self->selectors ) );
}

1;

__END__

=encoding utf-8

=head1 NAME

CSS::Object::Rule - CSS Object Oriented Rule

=head1 SYNOPSIS

    use CSS::Object::Rule;
    my $rule = CSS::Object::Rule->new( debug => 3, format => $format_object ) ||
        die( CSS::Object::Rule->error );

=head1 VERSION

    v0.1.3

=head1 DESCRIPTION

L<CSS::Object::Rule> a class containing one or more L<CSS::Object::Selector> objects and one ore more L<CSS::Object::Property> objects.

=head1 CONSTRUCTOR

=head2 new

To instantiate a new L<CSS::Object::Rule> object, pass an hash reference of following parameters:

=over 4

=item I<debug>

This is an integer. The bigger it is and the more verbose is the output.

=item I<format>

This is a L<CSS::Object::Format> object or one of its child modules.

=back

=head1 METHODS

=head2 add_element

Provided with a L<CSS::Object::Element> object and this add it to the array of L</elements> for this rule.

=head2 add_property

Provided with a L<CSS::Object::Property> object and this adds it to the list of properties contained in this rule.

The object is added to the L</properties> array object, which is an L<Module::Generic::Array> object.

=head2 add_selector

Provided with a L<CSS::Object::Selector> object and this adds it to the list of selectors contained in this rule.

The object is added to the L</selectors> array object, which is an L<Module::Generic::Array> object.

=head2 add_to

Provided with a L<CSS::Object> object and this add our object to its list of elements by calling L<CSS::Object/add_rule>

=head2 as_string

This calls the L</format> and its method L<CSS::Object::Format/rule_as_string>

It returns the css string produced or undef and sets an L<Module::Generic::Exception> upon error.

=head2 elements

Sets or gets the list of elements for this rule. This uses an array object from L<Module::Generic::Array>

Typical elements for a rule are properties (L<CSS::Object::Property>) and comments (L<CSS::Object::Comment>).

=head2 elements_as_string

This takes our list of L</elements> and call L<CSS:Object::Format/elements_as_string> to stringify them and return a formatted string.

=head2 format

This is a L<CSS::Object::Format> object or one of its child modules.

=head2 get_property_by_name

Provided with a property name, and this returns its matching L<CSS::Object::Property> objects.

It returns a list of objects in list context or an empty list if no match found.

In object context, it returns the first match found or the L<Module::Generic::Null> special class object to allow chaining even when nothing was returned. in scalar context, it just returns the first entry found, if any, so this could very well be undefined.

=head2 properties

This sets or gets the L<Module::Generic::Array> object used to store all the L<CSS::Object::Property> objects.

=head2 properties_as_string

This returns the string value of all the properties objects currently held. It calls the method L<CSS::Object::Format/properties_as_string> to stringify those properties.

=head2 remove_from

This takes a L<CSS::Object> as argument and it will remove this current rule object from the css list of rules.

It basically calls L<CSS::Object/remove_rule>.

It returns the current rule object.

=head2 remove_property

Given a L<CSS::Object::Property>, this will remove it from its list of elements. It returns the current rule object.

It basically does:

    $self->elements->remove( $rule );

=head2 selectors

This sets or gets the L<Module::Generic::Array> object used to store all the L<CSS::Object::Selector> objects.

=head2 selectors_as_string

This returns the string value of all the selector objects currently held. It calls the method L<CSS::Object::Format/selectors_as_string> to stringify those selectors.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<CSS::Object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
