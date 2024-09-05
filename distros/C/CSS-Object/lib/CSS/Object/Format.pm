##----------------------------------------------------------------------------
## CSS Object Oriented - ~/lib/CSS/Object/Format.pm
## Version v0.2.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/06/21
## Modified 2024/09/05
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package CSS::Object::Format;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    our $VERSION = 'v0.2.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{new_line} = "\n";
    $self->{open_brace_on_new_line} = 1;
    $self->{close_brace_on_new_line} = 1;
    $self->{open_brace_and_new_line} = 1;
    $self->{indent} = '';
    $self->{property_separator} = "\n";
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    $self->{_params} = [qw(
        close_brace_on_new_line
        indent
        new_line
        open_brace_and_new_line
        open_brace_on_new_line
        property_separator
    )];
    return( $self );
}

sub backup_parameters { return( shift->clone ); }

sub class { return( ref( $_[0] ) ); }

sub close_brace_on_new_line { return( shift->_set_get_boolean( 'close_brace_on_new_line', @_ ) ); }

sub comment_as_string
{
    my( $self, $elem ) = @_;
    # no overloading;
    return( $self->error( "No comment object was provided." ) ) if( !defined( $elem ) );
    return( $self->error( "Comment object provied is not a CSS::Object::Comment object." ) ) if( !$self->_is_a( $elem, 'CSS::Object::Comment' ) );
    return( '/* ' . $elem->values->join( "\n" )->scalar . ' */' );
}

sub copy_parameters_from
{
    my $self = shift( @_ );
    my $fmt  = shift( @_ ) || return( $self->error( "No formatter object was provided to copy the parameters from." ) );
    return( $self->error( "Formatter object provided is actually not a formatter object." ) ) if( !$self->_is_a( $fmt, 'CSS::Object::Format' ) );
    # my( $p, $f, $l ) = caller();
    my $ok_params = $self->{_params};
    for( @$ok_params )
    {
        $self->$_( $fmt->$_ ) if( $fmt->can( $_ ) );
    }
    return( $self );
}

sub elements_as_string
{
    my( $self, $elems ) = @_;
    # no overloading;
    return( $self->error( "No elements array was provided." ) ) if( !defined( $elems ) );
    return( $self->error( "Elements provided is not an array object." ) ) if( !$self->_is_a( $elems, 'Module::Generic::Array' ) );
	my $result = Module::Generic::Array->new;
	my $nl = $self->new_line->scalar;
	my $prop_sep = $self->property_separator->scalar;
	## $prop_sep .= $self->indent->scalar;
	$elems->foreach(sub
	{
	    $result->push( $_->format->indent->scalar . $_->as_string . ( $_->isa( 'CSS::Object::Comment' ) ? '' : ';' ) );
	});
	return( $result->join( $prop_sep )->scalar );
}

## sub indent { return( shift->_set_get_scalar_as_object( 'indent', @_ ) ); }
sub indent
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $val = shift( @_ );
#         my( $p, $f, $l ) = caller();
        return( $self->_set_get_scalar_as_object( 'indent', $val ) );
    }
    return( $self->_set_get_scalar_as_object( 'indent' ) );
}

sub keyframes_as_string
{
    my( $self, $keyf ) = @_;
    return( $self->error( "No keyframes rule object was provided." ) ) if( !defined( $keyf ) );
    return( $self->error( "Keyframes object provided (", overload::StrVal( $keyf ), ") is not actually an CSS::Object::Rule::Keyframes" ) ) if( !$self->_is_a( $keyf, 'CSS::Object::Rule::Keyframes' ) );
    ## no overloading;
    ## Calling rule_as_string on each item in our stack
    my $rule_str = $keyf->elements->map(sub{ $_->as_string })->join( "\n" )->scalar;
    my $type = $keyf->type->tr( '_', '-' )->scalar;
    my $name = $keyf->name->scalar;
    my $nl = $self->new_line->scalar;
    return( '@' . "${type} ${name}" . ( $self->open_brace_on_new_line ? $nl : ' ' ) . "{" . ( $self->open_brace_and_new_line ? $nl : '' ) . $rule_str . ( $self->close_brace_on_new_line ? $nl : ' ' ) . "}" );
}

sub new_line { return( shift->_set_get_scalar_as_object( 'new_line', @_ ) ); }

sub open_brace_on_new_line { return( shift->_set_get_boolean( 'open_brace_on_new_line', @_ ) ); }

sub open_brace_and_new_line { return( shift->_set_get_boolean( 'open_brace_on_new_line', @_ ) ); }

## Outdated. See elements_as_string
sub properties_as_string
{
    my( $self, $properties ) = @_;
    # no overloading;
    return( $self->error( "No properties array was provided." ) ) if( !defined( $properties ) );
    return( $self->error( "Properties provided is not an array object." ) ) if( !$self->_is_a( $properties, 'Module::Generic::Array' ) );
    # return( join( '; ', map{ $_->name . ": " . $_->values->map(sub{ $_->value->scalar })->join( '' ) } @$properties ) );
    return( $properties->map(sub{ $_->name->scalar . ': ' . $_->values->map(sub{ $_->value->scalar })->join( '' )->scalar })->join( ";" )->scalar );
}

sub property_as_string
{
    my( $self, $prop ) = @_;
    # no overloading;
    return( $self->error( "No property object was provided." ) ) if( !defined( $prop ) );
    return( $self->error( "Property object provied is not a CSS::Object::Property object." ) ) if( !$self->_is_a( $prop, 'CSS::Object::Property' ) );
    my $indent = $prop->format->indent->scalar;
    return( $prop->name->scalar . ': ' . $prop->values->map(sub{ $_->as_string })->join( '' )->scalar );
}

sub property_separator { return( shift->_set_get_scalar_as_object( 'property_separator', @_ ) ); }

sub restore_parameters
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    return( $self->error( "Data provided is not an hash reference." ) ) if( !$self->_is_hash( $this ) );
    my $params = $self->{_params};
    foreach my $p ( @$params )
    {
        $self->$p( $this->{ $p } );
    }
    return( $self );
}

sub rule_as_string
{
    my( $self, $rule ) = @_;
    # no overloading;
#     my( $pack, $file, $line ) = caller;
    return( $self->error( "No rule object was provided." ) ) if( !defined( $rule ) );
    return( $self->error( "Rule object provided (", overload::Overloaded( $rule ) ? overload::StrVal( $rule ) : $rule ,") is not an actual rule object." ) ) if( !$self->_is_a( $rule, 'CSS::Object::Rule' ) );
    my $rule_indent = $rule->format->indent->scalar;
    my $nl = $self->new_line->scalar;
    ## return( $rule->selectors_as_string . ' { ' . $rule->properties_as_string . " }\n" );
    return(
        $rule_indent . $rule->selectors_as_string . 
        ( $self->open_brace_on_new_line ? $nl : ' ' ) .
        $rule_indent . '{' .
        ( $self->open_brace_and_new_line ? $nl : ' ' ) . 
        $rule->elements_as_string . 
        ( $self->close_brace_on_new_line ? $nl : ' ' ) . 
        "${rule_indent}}"
    );
}

sub selectors_as_string
{
    my( $self, $selectors ) = @_;
    return( $selectors->map(sub{ $_->name->scalar })->join( ', ' )->scalar );
}

sub value_as_string
{
    my( $self, $val ) = @_;
    return( $self->error( "No value object was provided." ) ) if( !$self->_is_a( $val, 'CSS::Object::Value' ) );
    return( $self->error( "Value object provided is not a CSS::Object::Value object." ) ) if( !$self->_is_a( $val, 'CSS::Object::Value' ) );
    return(
        $val->comment_before->map(sub{ $_->as_string })->join( ' ' )->scalar . ( $val->comment_before->length > 0 ? ' ' : '' ) . 
        $val->value->as_string . 
        ( $val->comment_after->length > 0 ? ' ' : '' ) . $val->comment_after->map(sub{ $_->as_string })->join( ' ' )->scalar
    );
}

sub values_as_string
{
    my( $self, $values ) = @_;
    return( $self->error( "No properties values array was provided." ) ) if( !defined( $values ) );
    return( $self->error( "Properties values provided is not an array." ) ) if( !$self->_is_a( $values, 'Module::Generic::Array' ) );
    ## return( join( '', map{ $_->value } @$values ) );
    ## return( $values->map(sub{ $_->value->scalar })->join( '' )->scalar );
    return( $values->map(sub{ $_->as_string })->join( '' )->scalar );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

CSS::Object::Format - CSS Object Oriented Stringificator

=head1 SYNOPSIS

    use CSS::Object::Format;
    my $format = CSS::Object::Format->new( debug => 3 ) ||
        die( CSS::Object::Format->error );
    my $prop = CSS::Object::Property->new(
        format => $format,
        debug => 3,
        name => 'display',
        value => 'inline-block',
    ) || die( CSS::Object::Property->error );
    print( $prop->as_string );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

L<CSS::Object::Format::Inline> is a CSS inline stringificator

=head1 CONSTRUCTOR

=head2 new

To instantiate a new L<CSS::Object::Format> object, pass an hash reference of following parameters:

=over 4

=item I<debug>

This is an integer. The bigger it is and the more verbose is the output.

=back

=head1 PARAMETERS

The available parameters used to alter the formatting of the formatters are as follow. Please see each of them methods for their respective purpose and usage.

=over 4

=item * L</close_brace_on_new_line>

=item * L</new_line>

=item * L</open_brace_on_new_line>

=item * L</open_brace_and_new_line>

=item * L</indent>

=item * L</property_separator>

=back

=head1 METHODS

=head2 backup_parameters

This will create a deep copy of this formatter's L</parameters> and return it.

See L</restore_parameters>

=head2 close_brace_on_new_line

This takes a boolean value. If true, this will instruct the formatter to place the closing brace on a new line.

=head2 comment_as_string

Provided with a comment object, and this will return the comment formatted.

=head2 copy_parameters_from

Provided with another L<CSS::Object::Format> object, and this will copy all suitable L</parameters> to it.

This is called from the L<format> methods in CSS element classes when a new format object is provided to the element.

=head2 elements_as_string

Provided with an array object (L<Module::Generic::Array>), and this will format all the elements and return a string.

=head2 indent

This is one of L</parameters> that sets the string to use as indent. Indent string can be provided in rule formatter or property formatter.

This returns the current character value as a L<Module::Generic::Scalar> object.

=head2 keyframes_as_string

This formats the keyframe special rule and returns a string.

=head2 new_line

This sets or gets the new line character to be used for new lines.

This returns the current character value as a L<Module::Generic::Scalar> object.

=head2 open_brace_on_new_line

This takes a boolean value. If true, this will instruct the formatter to place the opening brace on a new line.

=head2 open_brace_and_new_line

This takes a boolean value. If true, this will instruct the formatter to insert a new line after the opening brace.

=head2 properties_as_string

Provided with an array reference of a L<CSS::Object::Property> objects and this will format them and return their string representation.

=head2 property_as_string

Provided with a L<CSS::Object::Property> object and this will format it and return its string representation.

=head2 property_separator

This sets or gets the property separator. By default, this is a new line C<\n>

If you want the formatter to put all properties on a single line, you could replace this default value with an empty string.

This returns the current character value as a L<Module::Generic::Scalar> object.

=head2 restore_parameters

Provided with an hash reference, typically that created by L</backup_parameters> and this will restore this formatter's L</parameters>

It returns our object

=head2 rule_as_string

Provided with a L<CSS::Object::Rule> object and this will format it and return its string representation.

=head2 selectors_as_string

Provided with an array reference of a L<CSS::Object::Selector> objects and this will format them and return their string representation.

=head2 value_as_string

Provided with a L<CSS::Object::Value> object and this will format it and return its string representation.

=head2 values_as_string

Provided with an array reference of a L<CSS::Object::Value> objects and this will format them and return their string representation.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<CSS::Object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
