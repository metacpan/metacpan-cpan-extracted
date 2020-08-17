##----------------------------------------------------------------------------
## CSS Object Oriented - ~/lib/CSS/Object/Property.pm
## Version v0.1.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.local>
## Created 2020/06/21
## Modified 2020/06/21
## 
##----------------------------------------------------------------------------
package CSS::Object::Property;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( CSS::Object::Element );
    use CSS::Object::Format;
    use CSS::Object::Value;
    use Devel::Confess;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    ## print( STDERR ref( $self ), "::init() Args received are: ", $self->dump( @_ ), "\n" );
    ## $self->{format}    = '';
    $self->{name}       = '';
    $self->{value}      = '';
    $self->{values}     = [];
    ## $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    $self->format->indent( '    ' );
    return( $self );
}

sub add_to
{
    my $self = shift( @_ );
    my $rule = shift( @_ ) || return( $self->error( "No rule object was provided to add our property to it." ) );
    return( $self->error( "Rule object provided (", overload::StrVal( $rule ), ") is not actually a CSS::Object::Rule object." ) ) if( !$self->_is_a( $rule, 'CSS::Object::Rule' ) );
    $self->format->indent( $rule->format->indent );
    $rule->add_property( $self );
    return( $self );
}

sub as_string { return( $_[0]->format->property_as_string( $_[0] ) ); }

sub format
{
    my $self = shift( @_ );
    if( @_ )
    {
        # my( $p, $f, $l ) = caller;
        # $self->message( 3, "Property format called in package $p at line $l in file $f" );
	    my $format = $self->SUPER::format( @_ ) || return;
        $self->values->foreach(sub
        {
            shift->format( $format ) || return;
        });
        $format->indent( '    ' );
        return( $format );
    }
    return( $self->_set_get_object( 'format', 'CSS::Object::Format' ) );
}

sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

sub value
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $val = shift( @_ );
        my $valObj;
        if( $self->_is_a( $val, 'CSS::Object::Value' ) )
        {
            $valObj = $val;
            $valObj->format( $self->format );
            $valObj->debug( $self->debug );
        }
        ## Array of values, which could be
        elsif( $self->_is_array( $val ) )
        {
            ## Make sure this is a Module::Generic::Array
            $val = $self->new_array( $val );
            $val->foreach(sub
            {
                if( $self->_is_a( $_, 'CSS::Object::Value' ) )
                {
                    $self->values->push( $_ );
                }
                elsif( !ref( $_ ) || $self->_is_a( $_, 'Module::Generic::Scalar' ) )
                {
                    $valObj = CSS::Object::Value->new( "$_",
                        debug  => $self->debug,
                        format => $self->format,
                    );
                    $self->values->push( $_ );
                }
                else
                {
                    CORE::warn( "Got value \"$_\" in an array of values provided for this property, but I just do not know what to do with it.\n" );
                }
            });
        }
        else
        {
            # $self->message( 3, "Creating a value object for value '$val'." );
            $valObj = CSS::Object::Value->new( $val,
                debug  => $self->debug,
                format => $self->format,
            );
            defined( $valObj ) || return( $self->error( "Unable to initialise CSS::Object::Value object for value \"$val\"." ) );
        }
        # $self->message( 3, "Adding new value object '", overload::StrVal( $valObj ), " ($val) to our stack." );
        $self->values->set( $valObj );
        # $self->message( 3, "Stack of values contains ", $self->values->length, " elements. Returning the CSS::Object::Value object (", $valObj->as_string, ")." );
        return( $valObj );
    }
    # my $last = $self->values->last;
    # $self->message( 3, "Returning value object '", $last, "'." );
    return( $self->values->last );
}

## Array of CSS::Object::Value objects
sub values { return( shift->_set_get_array_as_object( 'values', @_ ) ); }

sub values_as_string { return( $_[0]->format->values_as_string( $_[0]->values ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

CSS::Object::Property - CSS Object Oriented Property

=head1 SYNOPSIS

    use CSS::Object::Property;
    my $prop = CSS::Object::Property->new(
        name => 'display',
        value => 'inline-block',
        format => $format_object,
        debug => 3,
    ) || die( CSS::Object::Property->error );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

L<CSS::Object::Property> is a class to represent a CSS property.

=head1 CONSTRUCTOR

=head2 new

To instantiate a new L<CSS::Object::Property> object, pass an hash reference of following parameters:

=over 4

=item I<debug>

This is an integer. The bigger it is and the more verbose is the output.

=item I<format>

This is a L<CSS::Object::Format> object or one of its child modules.

=item I<name>

This is the property's name. When provided, this calls the method L</name> to store the value.

=item I<value>

This is the property's name. When provided, this calls the method L</value> to store the value.

=back

=head1 METHODS

=head2 format

This is a L<CSS::Object::Format> object or one of its child modules.

=head2 as_string

This calls the L</format> and its method L<CSS::Object::Format/property_as_string>

It returns the css string produced or undef and sets an L<Module::Generic::Exception> upon error.

=head2 format

This sets or gets the L<CSS::Object::Format> object. When set, this will share the formatter with all its L<CSS::Object::Value> objects.

=head2 name

Sets or gets the property's name. The name stored here becomes a L<Module::Generic::Scalar> and thus all its object methods can be used

=head2 value

Sets the value or get the last value for this property.

It takes either a string or a L<CSS::Object::Value> object and add it to the list of stored values for this property using the L</properties> method.

It returns the last property value object in the L</values> array.

=head2 values

This sets or gets the list of L<CSS::Object::Value> objects. It uses a L<Module::Generic::Array> object to store those value objects.

It returns the array object.

=head2 values_as_string

This returns a string representation of all the L<CSS::Object::Value> objects currently stored. It does this by calling the format's method L<CSS::Object::Format/values_as_string>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<CSS::Object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
