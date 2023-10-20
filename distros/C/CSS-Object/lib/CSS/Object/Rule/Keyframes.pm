##----------------------------------------------------------------------------
## CSS Object Oriented - ~/lib/CSS/Object/Rule.pm
## Version v0.1.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.local>
## Created 2020/06/21
## Modified 2020/06/21
## 
##----------------------------------------------------------------------------
package CSS::Object::Rule::Keyframes;
BEGIN
{
    use strict;
    use warnings;
    ## We add CSS::Object in our @ISA so that we can add rule to our KeyframesRule package
    ## KeyFrames are special rules that are blocks of further rules
    use parent qw( CSS::Object::Rule::At CSS::Object );
    use Devel::Confess;
    use Want ();
    use overload (
        '""' => 'as_string',
        fallback => 1,
    );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->format->indent( '    ' );
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    return( $self->format->keyframes_as_string( $self ) );
}

sub frame
{
    my $self = shift( @_ );
    # no overloading;
    ## $offset can be a scalar or an array reference
    my( $offset, @props ) = @_;
    ## If we are given an hash reference, we make it an array with hash keys sorted
    if( scalar( @props ) == 1 && $self->_is_hash( $props[0] ) )
    {
        @props = map{ $_ => $props[0]->{ $_ } } sort( keys( %{$props[0]} ) );
    }
    return( $self->error( "Uneven number of parameters to set keyframes" ) ) if( scalar( @props ) % 2 );
    my $css = $self->css;
    my $frame_rule = $css->new_rule->add_to( $self ) ||
        return( $self->error( "Cannot add new rule: ", CSS::Object::Rule::Keyframes->error ) );
    $frame_rule->format->indent( '    ' );
    if( $self->_is_array( $offset ) )
    {
        foreach my $this ( @$offset )
        {
            $css->new_selector( name => "${this}\%" )->add_to( $frame_rule );
        }
    }
    else
    {
        $css->new_selector( name => "${offset}\%" )->add_to( $frame_rule );
    }
    while( my( $prop, $val ) = CORE::splice( @props, 0, 2 ) )
    {
        $prop =~ tr/_/-/;
        $css->new_property( name => $prop, value => $val )->add_to( $frame_rule )->format->indent( '        ' );
    }
    ## For chaining
    return( $self );
}

# In our @ rule, we hold all the rules. This makes our @ rule special, because it is a rule that contains a set of rules
# Array of CSS::Object::Rule::Keyframes objects
sub rules { return( shift->_set_get_array_as_object( 'rules', @_ ) ); }

sub type { return( shift->_set_get_scalar_as_object( 'type', @_ ) ); }


1;

__END__

=encoding utf-8

=head1 NAME

CSS::Object::Rule::Keyframes - CSS Object Oriented Rule

=head1 SYNOPSIS

    use CSS::Object::Rule::Keyframes;
    my $rule = CSS::Object::Rule::Keyframes->new( debug => 3, format => $format_object ) ||
        die( CSS::Object::Rule::Keyframes->error );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

L<CSS::Object::Rule::Keyframes> a class containing one or more L<CSS::Object::Selector> objects> and one ore more L<CSS::Object::Property> objects.

=head1 CONSTRUCTOR

=head2 new

To instantiate a new L<CSS::Object::Rule::Keyframes> object, pass an hash reference of following parameters:

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

It returns a list of objects in list context or the first match found in scalar context.

=head2 properties

This sets or gets the L<Module::Generic::Array> object used to store all the L<CSS::Object::Property> objects.

=head2 properties_as_string

This returns the string value of all the properties objects currently held. It calls the method L<CSS::Object::Format/properties_as_string> to stringify those properties.

=head2 selectors

This sets or gets the L<Module::Generic::Array> object used to store all the L<CSS::Object::Selector> objects.

=head2 selectors_as_string

This returns the string value of all the selector objects currently held. It calls the method L<CSS::Object::Format/selectors_as_string> to stringify those selectors.

head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<CSS::Object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
