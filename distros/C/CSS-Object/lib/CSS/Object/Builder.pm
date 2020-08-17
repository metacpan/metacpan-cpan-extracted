##----------------------------------------------------------------------------
## CSS Object Oriented - ~/lib/CSS/Object/Builder.pm
## Version v0.1.1
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.local>
## Created 2020/06/21
## Modified 2020/06/24
## 
##----------------------------------------------------------------------------
package CSS::Object::Builder;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use Devel::Confess;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    my $css  = shift( @_ ) || return( $self->error( "No css object was provided." ) );
    return( $self->error( "CSS object provided is not a CSS::Object object." ) ) if( !$self->_is_a( $css, 'CSS::Object' ) );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return;
    $self->css( $css ) || return;
    return( $self );
}

sub as_string { return( shift->css->as_string ); }

sub at
{
    my $self = shift( @_ );
    my( $name, $value ) = @_;
    if( $name =~ /^([\-\_][a-zA-Z]+[\-\_])?keyframes/ )
    {
        my( $type, $name ) = @_;
        return( $self->css->new_keyframes_rule( type => $type, name => $name )->add_to( $self->css ) );
    }
    else
    {
        # return( $self->error( "I do not know what kind of rule is \"$type\" for rule name \"$name\"." ) );
        return( $self->css->new_at_rule( name => $name, value => $value )->add_to( $self->css ) );
    }
}

sub charset { return( shift->css->charset( @_ ) ); }

sub comment { return( shift->css->add_element( CSS::Object::Comment->new( @_ ) ) ); }

sub css { return( shift->_set_get_object( '__css', 'CSS::Object', @_ ) ); }

sub current_rule { return( shift->css->elements->last ); }

sub elements { return( shift->_set_get_array_as_object( 'elements', @_ ) ); }

sub new_rule
{
    my $self = shift( @_ );
    my $css = $self->css || return( $self->error( "Our main css object is gone!" ) );
    # $self->message( 3, "Creating new CSS::Object::Builder::Rule object with css object '$css' and formatter set to '", $css->format, "'." );
#     return( CSS::Object::Builder::Rule->new( @_,
#         format => $css->format,
#         debug => $self->debug,
#         css => $css,
#     ) );
    my $rule = CSS::Object::Builder::Rule->new( @_,
        format => $css->format,
        debug => $self->debug,
        css => $css,
    );
    # $self->message( 3, "Returning rule object '", overload::StrVal( $rule ), "'." );
    return( $rule );
}

sub select
{
    my $self = shift( @_ );
    my $this = shift( @_ ) || return( $self->error( "No css selector or rule object was provided" ) );
    my $css = $self->css || return( $self->error( "Our main css object is gone!" ) );
    my $rule;
    if( $self->_is_a( $this, 'CSS::Object::Rule' ) )
    {
        my $found = 0;
        $css->elements->foreach(sub
        {
            if( overload::StrVal( $_ ) eq overload::StrVal( $rule ) )
            {
                $found++;
                return;
            }
        });
        $rule = bless( $this, 'CSS::Object::Builder::Rule' );
        $rule->css( $css );
        ## Unless this object is already added to the CSS::Object we add it now
        unless( $found )
        {
            $rule->add_to( $css );
        }
        return( $rule );
    }
    else
    {
        # $self->message( 3, "Creating new CSS::Object::Builder::Rule object." );
        $rule = $self->new_rule->add_to( $css );
        defined( $rule ) || return( $self->error( "Cannot create CSS::Object::Builder::Rule object: ", CSS::Object::Builder::Rule->error ) );
    }
    # $self->message( 3, "Rule object is '", overload::StrVal( $rule ), "'." );
    if( $self->_is_array( $this ) )
    {
        foreach my $s ( @$this )
        {
            $css->new_selector( name => $s )->add_to( $rule );
        }
    }
    ## further calls will be made in the context of the CSS::Object::Builder::Rule package with dynamic method name
    return( $rule );
}

## Dynamic css property name pakcage
package CSS::Object::Builder::Rule;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( CSS::Object::Rule );
    use Devel::Confess;
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    return( $self );
}

sub comment
{
    my $self = shift( @_ );
    my $cmt = $self->css->new_comment( @_ );
    $cmt->format->indent( $self->elements->length > 0 ? $self->elements->first->format->indent : '    ' );
    return( $self->add_element( $cmt ) );
}

sub css { return( shift->_set_get_object( 'css', 'CSS::Object', @_ ) ); }

AUTOLOAD
{
    my( $prop_name ) = our $AUTOLOAD =~ /([^:]+)$/;
    my $self = shift( @_ );
    die( "No method \"$prop_name\" exists in this package \"", __PACKAGE__, "\".\n" ) if( !defined( $self ) );
    my $css = $self->css || return( $self->error( "Our main css object is gone!" ) );
    $prop_name =~ tr/_/-/;
    my $prop_val = $self->_is_array( $_[0] )
        ? shift( @_ )
        : scalar( @_ ) > 1
            ? [ @_ ]
            : shift( @_ );
    my $prop = $css->new_property(
        name => $prop_name,
        value => $prop_val,
        debug => $self->debug,
    );
    $prop->format->indent( '    ' );
    $self->elements->push( $prop );
    return( $self );
};

1;

__END__

=encoding utf-8

=head1 NAME

CSS::Object::Builder - CSS Object Oriented Builder

=head1 SYNOPSIS

    use CSS::Object;
    my $css = CSS::Object->new( debug => 3 ) ||
        die( CSS::Object->error );
    ny $b = $css->builder;
    $b->select( ['#main_section > .article', 'section .article'] )
        ->display( 'none' )
        ->font_size( '+0.2rem' )
        ->comment( ['Some multiline comment', 'that are made possible with array reference'] )
        ->text_align( 'center' )
        ->comment( 'Making it look pretty' )
        ->padding( 5 );
    $b->charset( 'UTF-8' );
    $b->at( _webkit_keyframes => 'error' )
        ->frame( 0, { _webkit_transform => 'translateX( 0px )' })
        ->frame( 25, { _webkit_transform => 'translateX( 30px )' })
        ->frame( 45, { _webkit_transform => 'translateX( -30px )' })
        ->frame( 65, { _webkit_transform => 'translateX( 30px )' })
        ->frame( 82, { _webkit_transform => 'translateX( -30px )' })
        ->frame( 94, { _webkit_transform => 'translateX( 30px )' })
        ->frame( [qw( 35 55 75 87 97 100 )], { _webkit_transform => 'translateX( 0px )' } );

=head1 VERSION

    v0.1.1

=head1 DESCRIPTION

L<CSS::Object::Builder> is a dynamic object oriented CSS builder

=head1 CONSTRUCTOR

=head2 new

To instantiate a new L<CSS::Object::Builder> object you need to pass it a L<CSS::Object> object and that's it.

Optional argument are:

=over 4

=item I<debug>

This is an integer. The bigger it is and the more verbose is the output.

=back

=head1 METHODS

=head2 as_string

This is a shorthand for calling L<CSS::Object/as_string> using our L</css> method.

=head2 at

This takes an at-mark type parameter as first argument, and the name of the at-mark rule. It returns an object from the proper class. For example, a C<@keyframes> rule would return a L<CSS::Object::Rule::Keyframes>.

=head2 charset

This takes an encoding as unique argument, and no matter when it is called in the chain of method calls, this will always be placed at the top of the stylesheet.

=head2 comment

Provided with a string or an array reference of comment lines, and this will return an L<CSS::Object::Comment> object.

=head2 css

This sets or gets the required L<CSS::Object> for this parser. The parser uses this method and the underlying object to access L<CSS::Object> methods and store css rules using L<CSS::Object/add_element>

=head2 current_rule

Returns the last added rule from L<CSS::Object> list of rules by calling L<Module::Generic::Array/last> on L<CSS::Object/elements> which returns a L<Module::Generic::Array> object.

=head2 elements

Sets or gets the list of css elements. This is a L<Module::Generic::Array>, but is not used. I should remove it.

=head2 new_at_rule

This creates and returns a new L<CSS::Object::Builder::AtRule> object. This should be moved under L<CSS::Object>

=head2 new_keyframes_rule

This creates and returns a new L<CSS::Object::Builder::KeyframesRule-> object. This should be moved under L<CSS::Object>

=head2 new_rule

This creates and returns a new L<CSS::Object::Builder::Rule> object. L<CSS::Object::Builder::Rule> class allos for dynamic method call to create and add css properties inside a css rule.

=head2 select

This takes either a css selector as a string or an array reference of css selectors. It then returns a L<CSS::Object::Builder::Rule>, which is a special class with dynamic method using AUTOLOAD. This makes it possible to call the hundred of css property as method.

Since those css properties are called as perl method, dashes have to be expressed as underline, such as:

    $b->select( '.my-class' )->_moz_transition( 'all .25s ease' );

This would be interpreted as:

    .my-class
    {
        -moz-transition: all .25s ease;
    }

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<CSS::Object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
