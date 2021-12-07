##----------------------------------------------------------------------------
## CSS Object Oriented - ~/lib/CSS/Object.pm
## Version v0.1.5
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/06/24
## Modified 2021/11/28
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package CSS::Object;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use CSS::Object::Builder;
    use CSS::Object::Comment;
    use CSS::Object::Format;
    use CSS::Object::Property;
    use CSS::Object::Rule;
    use CSS::Object::Rule::At;
    use CSS::Object::Rule::Keyframes;
    use CSS::Object::Selector;
    use CSS::Object::Value;
    use Want ();
    use Devel::Confess;
    our $VERSION = 'v0.1.5';
};

sub init
{
    my $self = shift( @_ );
    $self->{parser}     = 'CSS::Object::Parser::Default';
    $self->{format}     = '';
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    # $self->message( 3, "Formatter class set: '", ref( $self->format ), "'." );
    unless( $self->_is_a( $self->{format}, 'CSS::Object::Format' ) )
    {
        my $format = CSS::Object::Format->new(
            debug => $self->debug
        );
        $self->format( $format );
    }
    $self->{rules} = Module::Generic::Array->new;
    return( $self );
}

# Add comment at the top level. To add comment inside a rule, see add_element in CSS::Object::Rule
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

sub add_rule
{
    my $self = shift( @_ );
    my $rule = shift( @_ );
    $self->message( 4, "CSS rule provided to add to our stack of elements: '", overload::StrVal( $rule ), "'." );
    return( $self->error( "No rule object was provided to add." ) ) if( !defined( $rule ) );
    return( $self->error( "Object provided is not a CSS::Object::Rule object." ) ) if( !$self->_is_a( $rule, 'CSS::Object::Rule' ) );
    # $self->rules->push( $rule );
    $self->elements->push( $rule );
    $self->message( 4, "Returning rule object added: '", overload::StrVal( $rule ), "'. Now we have ", $self->elements->length, " rules stored." );
    return( $rule );
}

sub as_string
{
    my $self = shift( @_ );
    $self->messagef( 3, "There are %d elements in our stack.", $self->elements->length );
    if( @_ )
    {
        my $format = shift( @_ );
        return( $self->error( "Provided parameter to as_string was not an CSS::Object::Format object." ) ) if( $format !~ /^CSS\::Object\::Format/ && !$self->_is_a( $format, 'CSS::Object::Format' ) );
        $self->elements->foreach(sub
        {
            shift->format( $format );
        });
    }

    my $output = Module::Generic::Array->new;
    # $self->rules->foreach(sub
    $self->elements->foreach(sub
    {
        $output->push( shift->as_string );
    });
    my $nl = $self->format->new_line;
    return( $output->join( "$nl$nl" )->scalar );
}

sub builder
{
    my $self = shift( @_ );
    return( $self->{_builder} ) if( $self->_is_object( $self->{_builder} ) );
    # $self->message( 3, "Creating builder object with debug set to '", $self->debug, "' and formatter set to '", $self->format->class, "'." );
    my $b = CSS::Object::Builder->new( $self, debug => $self->debug ) ||
        return( $self->error( "Could not initialise the CSS builder: ", CSS::Object::Builder->error ) );
    $self->{_builder} = $b;
    return( $b );
}

sub charset { return( shift->_set_get_scalar_as_object( 'charset', @_ ) ); }

# Array of CSS::Object::Element objects or their sub classes
sub elements { return( shift->_set_get_object_array_object( 'elements', 'CSS::Object::Element', @_ ) ); }

sub format
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $val = shift( @_ );
        my $format;
        if( ref( $val ) )
        {
            $format = $self->_set_get_object( 'format', 'CSS::Object::Format', $val ) || return( $self->pass_error );
        }
        # Formatter as a class name
        elsif( !ref( $val ) && CORE::index( $val, '::' ) != -1 )
        {
            $self->_load_class( $val ) || return( $self->pass_error );
            $format = $val->new( debug => $self->debug ) || return( $self->pass_error( $val->error ) );
            $self->_set_get_object( 'format', 'CSS::Object::Format', $format );
        }
        else
        {
            return( $self->error( "Unknown format \"$val\". I do not know what to do with it." ) );
        }
        $self->messagef( 3, "Setting new formatter '$format' for %d elements -> %s", $self->elements->length, sub{ $self->elements->join( "', '" )} );
        $self->elements->foreach(sub
        {
            return(1) if( !$self->_is_object( $_[0] ) );
            shift->format( $format ) || return;
        });
        return( $format );
    }
    return( $self->_set_get_object( 'format', 'CSS::Object::Format' ) );
}

sub get_rule_by_selector
{
    my( $self, $name ) = @_;
    return( $self->error( "No selector was provided to find its equivalent rule object." ) ) if( !$name );
    # $self->messagef( 3, "%d elements found.", $self->elements->length );
    my $found = Module::Generic::Array->new;
    foreach my $rule ( @{$self->elements} )
    {
        next if( !$rule->isa( 'CSS::Object::Rule' ) );
        # $self->messagef( 3, "This rule has %d selectors", $rule->selectors->length );
        foreach my $sel ( @{$rule->selectors} )
        {
            # $self->message( 3, "Does '", $sel->name, "' match our target selector '$name' ?" );
            if( $sel->name eq $name )
            {
                # return( $rule );
                $found->push( $rule );
            }
        }
    }
    ## The user is calling this in a chain context, we make sure this is possible using the Module::Generic::Null class if needed
    if( Want::want( 'OBJECT' ) )
    {
        rreturn( $found->length > 0 ? $found->first : Module::Generic::Null->new );
    }
    elsif( Want::want( 'LIST' ) )
    {
        rreturn( @$found );
    }
    else
    {
        return( $found->first );
    }
}

sub load_parser
{
    my $self = shift( @_ );
    my $parser_class = $self->parser;
    $self->_load_class( "$parser_class" ) || return( $self->error( "Unable to load parser class \"$parser_class\": ", $self->error ) );
    my $parser = $parser_class->scalar->new( $self ) || return( $self->error( "Unable to instantiate parser \"$parser_class\" object: ", $parser_class->scalar->error ) );
    $parser->debug( $self->debug );
    # $self->message( 3, "Parser \"$parser_class\" initiated with object '$parser'." );
    return( $parser );
}

sub new_at_rule
{
    my $self = shift( @_ );
    my $o = CSS::Object::Rule::At->new( @_,
        format => $self->format,
        debug => $self->debug,
        css => $self,
    );
    return( $self->error( "Cannot create a new at rule object: ", CSS::Object::Rule::At->error ) ) if( !defined( $o ) );
    return( $o );
}

sub new_keyframes_rule
{
    my $self = shift( @_ );
    my $o = CSS::Object::Rule::Keyframes->new( @_,
        format => $self->format,
        debug => $self->debug,
        css => $self,
    );
    return( $self->error( "Cannot create a new keyframes rule object: ", CSS::Object::Rule::Keyframes->error ) ) if( !defined( $o ) );
    return( $o );
}

sub new_comment
{
    my $self = shift( @_ );
    my $o = CSS::Object::Comment->new( @_, format => $self->format, debug => $self->debug );
    return( $self->error( "Cannot create a new comment object: ", CSS::Object::Comment->error ) ) if( !defined( $o ) );
    return( $o );
}

sub new_property
{
    my $self = shift( @_ );
    my $o = CSS::Object::Property->new( @_, format => $self->format, debug => $self->debug );
    return( $self->error( "Cannot create a new property object: ", CSS::Object::Property->error ) ) if( !defined( $o ) );
    return( $o );
}

sub new_rule
{
    my $self = shift( @_ );
    $self->message( 3, "Creating new rule with formatter '", $self->format->class, "'." );
    my $o = CSS::Object::Rule->new( @_, format => $self->format, debug => $self->debug );
    return( $self->error( "Cannot create a new rule object: ", CSS::Object::Rule->error ) ) if( !defined( $o ) );
    # $self->message( 3, "Returning \"", overload::StrVal( $o ), "\"." );
    return( $o );
}

sub new_selector
{
    my $self = shift( @_ );
    my $o = CSS::Object::Selector->new( @_, format => $self->format, debug => $self->debug );
    return( $self->error( "Cannot create a new selector object: ", CSS::Object::Selector->error ) ) if( !defined( $o ) );
    return( $o );
}

sub new_value
{
    my $self = shift( @_ );
    my $o = CSS::Object::Value->new( @_, format => $self->format, debug => $self->debug );
    return( $self->error( "Cannot create a new value object: ", CSS::Object::Value->error ) ) if( !defined( $o ) );
    return( $o );
}

sub parse_string
{
    my $self = shift( @_ );
    my $string = shift( @_ );
    $self->message( 3, "Parsing string '$string'" );

    # remove comments
    # $string =~ s!/\*.*?\*\/!!g;
    $string =~ s|<!--||g;
    $string =~ s|-->||g;
    
    my $parser = $self->load_parser || return( $self->pass_error );
    my $elems = $parser->parse_string( $string ) || return( $self->pass_error( $parser->error ) );
    $self->messagef( 3, "Parser returned %d elements.", $elems->length );
    $self->messagef( 3, "First element is of class \"", ref( $elems->first ), "\"." );
    # $self->messagef( 3, "First rule has %d properties.", $rules->first->properties->length );
    return( $elems );
}

sub parser { return( shift->_set_get_scalar_as_object( 'parser', @_ ) ); }

sub purge { return( shift->elements->reset ); }

sub read_file
{
    my $self = shift( @_ );
    my $path = shift( @_ );

    if( ref( $path ) )
    {
        if( ref( $path ) eq 'ARRAY' )
        {
            $self->read_file( $_ ) for( @$path );
            return( $self );
        }
    }
    elsif( $path )
    {
        $self->message( 3, "Reading file \"$path\"." );
        my $io = IO::File->new( "<$path" ) || return( $self->error( "Could not open file \"$path\": $!" ) );
        $io->binmode( ':utf8' );
        my $source = join( '', $io->getlines );
        $io->close;
        $self->messagef( 3, "%d bytes of data read.", CORE::length( $source ) );
        if( $source )
        {
            my $elems = $self->parse_string( $source ) || return( $self->pass_error );
            $self->messagef( 3, "%d elements found from parsing.", $elems->length );
            # $self->rules->push( @$rules );
            $self->elements->push( @$elems );
        }
        return( $self );
    }
    return( $self->error( "Only scalars and arrays accepted: $!" ) );
}

sub read_string
{
    my $self = shift( @_ );
    my $data = shift( @_ );

    if( ref( $data ) )
    {
        if( ref( $data ) eq 'ARRAY' )
        {
            for( @$data )
            {
                $self->read_string( $_ ) || return( $self->pass_error );
            }
            return( $self );
        }
    }
    elsif( length( $data ) )
    {
        my $elems = $self->parse_string( $data ) || return( $self->pass_error );
        ## $self->rules->push( @$rules );
        $self->elements->push( @$elems );
    }
    return( $self );
}

sub remove_rule
{
    my $self = shift( @_ );
    my $rule = shift( @_ );
    # $self->message( 3, "CSS rule provided to add to our stack of elements: '", overload::StrVal( $rule ), "'." );
    return( $self->error( "No rule object was provided to remove." ) ) if( !defined( $rule ) );
    return( $self->error( "Object provided is not a CSS::Object::Rule object." ) ) if( !$self->_is_a( $rule, 'CSS::Object::Rule' ) );
    $self->elements->remove( $rule );
    return( $self );
}

# sub rules { return( shift->_set_get_array_as_object( 'rules', @_ ) ); }
sub rules { return( $_[0]->elements->map(sub{ $_[0]->_is_a( $_, 'CSS::Object::Rule' ) ? $_ : () }) ); }

1;

# XXX POD
__END__

=encoding utf-8

=head1 NAME

CSS::Object - CSS Object Oriented

=head1 SYNOPSIS

    use CSS::Object;

=head1 VERSION

    v0.1.5

=head1 DESCRIPTION

L<CSS::Object> is a object oriented CSS parser and manipulation interface.

=head1 CONSTRUCTOR

=head2 new

To instantiate a new L<CSS::Object> object, pass an hash reference of following parameters:

=over 4

=item I<debug>

This is an integer. The bigger it is and the more verbose is the output.

=item I<format>

This is a L<CSS::Object::Format> object or one of its child modules.

=item I<parser>

This is a L<CSS::Object::Parser> object or one of its child modules.

=back

=head1 EXCEPTION HANDLING

Whenever an error has occurred, L<CSS::Object> will set a L<Module::Generic::Exception> object containing the detail of the error and return undef.

The error object can be retrieved with the inherited L<Module::Generic/error> method. For example:

    my $css = CSS::Object->new( debug => 3 ) || die( CSS::Object->error );

=head1 METHODS

=head2 add_element

Provided with a L<CSS::Object::Element> object and this adds it to the list of css elements.

It uses an array object L</elements> which is an L<Module::Generic::Array> object.

=head2 add_rule

Provided with a L<CSS::Object::Rule> object and this adds it to our list of rules. It returns the rule object that was added.

=head2 as_string

This will return the css data structure, currently registered, as a string.

It takes an optional L<CSS::Object::Format> object as a parameter, to control the output. If none are provided, it will use the default one calling L</format>

=head2 builder

This returns a new L<CSS::Object::Builder> object.

=head2 charset

This sets or gets the css charset. It stores the value in a L<Module::Generic::Scalar> object.

=head2 elements

Sets or gets the array of CSS elements. This is a L<Module::Generic::Array> object that accepts only L<CSS::Object::Element> objects or its child classes, such as L<CSS::Object::Rule>, L<CSS::Object::Comment>, etc

=head2 format

Sets or gets a L<CSS::Object::Format> object. See L</as_string> below for more detail about their use.

L<CSS::Object::Format> objects control the stringification of the css structure. By default, it will return the data in a string identical or at least very similar to the one parsed if it was parsed.

=head2 get_rule_by_selector

Provided with a selector and this returns a L<CSS::Object::Rule> object or an empty string.

Hoever, if this method is called in an object context, such as chaining, then it returns a L<Module::Generic::Null> object instead of an empty string to prevent the perl error of C<xxx method called on an undefined value>. For example:

    $css->get_rule_by_selector( '.does-not-exists' )->add_element( $elem ) ||
    die( "Unable to add css element to rule \".does-not-exists\": ", $css->error );

But, in a non-object context, such as:

    my $rule = $css->get_rule_by_selector( '.does-not-exists' ) ||
    die( "Unable to add css element to rule \".does-not-exists\": ", $css->error );

L</get_rule_by_selector> will return an empty value.

=head2 load_parser

This will instantiate a new object based on the parser name specified with L</parser> or during css object instantiation.

It returns a new L<CSS::Object::Parser> object, or one of its child module matching the L</parser> specified.

=head2 new_comment

This returns a new L<CSS::Object::Comment> object and pass its instantiation method the provided arguments.

    return( $css->new_comment( $array_ref_of_comment_ilnes ) );

=head2 new_property

This takes a property name, and an optional value o array of values and return a new L<CSS::Object::Property> object

=head2 new_rule

This returns a new L<CSS::Object::Rule> object.

=head2 new_selector

This takes a selector name and returns a new L<CSS::Object::Selector> object.

=head2 new_value

This takes a property value and returns a new L<CSS::Object::Value> object.

=head2 parse_string

Provided with some css data and this will instantiate the L</parser>, call L<CSS::Object::Parser/parse_string> and returns an array of L<CSS::Object::Rule> objects. The array is an array object from L<Module::Generic::Array> and can be used as a regular array or as an object.

=head2 parser

Sets or gets the L<CSS::Object::Parser> object to be used by L</parse_string> to parse css data.

A valid parser object can be from L<CSS::Object::Parser> or any of its sub modules.

It returns the current parser object.

=head2 purge

This empties the array containing all the L<CSS::Object::Rule> objects.

=head2 read_file

Provided with a css file, and this will load it into memory and parse it using the parser name registered with L</parser>.

It can also take an array reference of css files who will be each fed to L</read_file>

It returns the L<CSS::Object> used to call this method.

=head2 read_string

Provided with some css data, and this will call L</parse_string>. It also accepts an array reference of data.

It returns the css object used to call this method.

=head2 rules

This sets or gets the L<Module::Generic::Array> object used to store all the L<CSS::Object::Rule> objects.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<CSS::Object>

L<Mozilla documentation on Custom CSS Properties|https://developer.mozilla.org/en-US/docs/Web/CSS/--*>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
