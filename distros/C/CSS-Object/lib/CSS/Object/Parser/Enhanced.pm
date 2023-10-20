##----------------------------------------------------------------------------
## CSS Object Oriented - ~/lib/CSS/Object/Parser/Enhanced.pm
## Version v0.1.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2020/08/09
## Modified 2020/08/09
## 
##----------------------------------------------------------------------------
package CSS::Object::Parser::Enhanced;
BEGIN
{
    use strict;
    use warnings;
    use Module::Generic;
    use parent qw( CSS::Object::Parser );
    use CSS::Object::Rule;
    use CSS::Object::Selector;
    use CSS::Object::Property;
    use Devel::Confess;
    our $VERSION = 'v0.1.0';
};

sub parse_string
{
    my $self = shift( @_ );
    my $string = shift( @_ ) || return;
    my $css = $self->css || return( $self->error( "Our css object is gone!" ) );
    my $this = {};
    for( my $pos = 0; $pos < length( $string ); $pos++ )
    {
        my $c = substr( $string, $pos, 1 );
        my $next = substr( $string, $pos + 1, 1 );
        my $prev = $pos > 0 ? substr( $string, $pos - 1, 1 ) : '';
        if( $c eq '*' && $next eq '/' )
        {
            $css->new_comment( [ split( /\r?\n/, $this->{line} ) ] )->add_to( $css );
            $this->{line} = '';
            $this->{inside_comment} = 0;
            next;
        }
        ## We found a comment in between rules. Comments within rules are processed separately in parse_element
        elsif( $c eq '/' && $next eq '*' )
        {
            $this->{inside_comment}++;
            next;
        }
        elsif( $this->{inside_comment} )
        {
            $this->{line} .= $c;
        }
        elsif( $this->{inside_statement} )
        {
            ## If we found a space and the next character is an opening brace, we are inside the element definition
            if( $c =~ /^[[:space:]\h]$/ && 
                !$this->{inside_quote} && 
                $next eq '{' )
            {
                $this->{name} = $this->{buffer};
                $this->{name} = $self->_trim( $this->{name} );
                ## $pos + 1 because we skip the opening brace
                $pos = $self->parse_element({
                    data => \$string,
                    pos => $pos + 1,
                    name => $this->{name},
                });
            }
            elsif( $this->{inside_quote} )
            {
                if( $c eq $this->{inside_quote} && $prev ne '\\' )
                {
                    $this->{inside_quote} = '';
                }
                $this->{buffer} .= $c;
            }
            elsif( ( $c eq '"' || $c eq "'" ) && $prev ne '\\' )
            {
                if( $this->{inside_quote} )
                {
                    $this->{inside_quote} = '';
                }
                else
                {
                    $this->{inside_quote} = $c;
                }
                $this->{buffer} .= $c;
            }
            elsif( $this->{inside_quote} )
            {
                $this->{buffer} .= $c;
            }
            else
            {
                $this->{buffer} .= $c;
            }
        }
        ## We may have found an element, check the first character
        ## NOTE: Confirm with rfc for the lawful characters
        elsif( !$this->{inside_statement} && $c =~ /^[\@\:\[\#\.a-zA-Z0-9]$/ )
        {
            $this->{inside_statement}++;
            $this->{buffer} = $c;
        }
    }
}

sub parse_element
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = shift( @_ ) if( $self->_is_hash( $_[0] ) );
    ## String reference
    my $sref = $opts->{data};
    my $pos  = $opts->{pos};
    die( "Value provided is not a scalar reference\n" ) if( ref( $sref ) ne 'SCALAR' );
    die( "Position provided is not an integer\n" ) if( $pos !~ /^\-?\d+$/ );
    my $css = $self->css || return( $self->error( "Our css object is gone!" ) );
    my $rule = $self->rule_from_token( $opts->{name} ) || return( $self->pass_error );
    my $p;
    my $this = {};
    for( $p = $pos; $p < length( $$sref ); $p++ )
    {
        my $c = substr( $string, $p, 1 );
        my $next = substr( $string, $p + 1, 1 );
        my $prev = $p > 0 ? substr( $string, $p - 1, 1 ) : '';
        if( ( $c eq "'" || $c eq '"' ) && $prev ne '\\' )
        {
            if( $this->{inside_quote} )
            {
                $this->{inside_quote} = '';
            }
            else
            {
                $this->{inside_quote} = $c;
            }
            $this->{buffer} .= $c;
        }
        elsif( $this->{inside_quote} )
        {
            $this->{buffer} .= $c;
        }
        elsif( !length( $this->{prop} ) )
        {
            $this->{prop} = $c;
        }
        ## We are done with this property, and either this is the start of a sub element, such as with keyframes containing braces for the definitions of each frames
        elsif( $c eq '{' && $prev ne '\\' )
        {
            $this->{prop} .= $this->{buffer};
            $this->{buffer} = '';
            $this->{prop} = $self->_trim( $this->{prop} );
            my $res = $self->parse_element({
                name => $this->{prop},
                data => $sref,
                ## After the opening brace we just found
                pos => $p + 1,
            }) || return( $self->pass_error );
            my $props = $res->{properties};
            $p = $res->{pos};
        }
        ## or we found semicolon which signals the start of the property value
        else
        {
            $this->{buffer} .= $c;
        }
    }
    $pos = $p;
    return({ pos => $pos });
}

## "There are two kinds of statements"
## https://developer.mozilla.org/en-US/docs/Web/CSS/Syntax#CSS_statements
sub rule_from_token
{
    my $self  = shift( @_ );
    my $token = shift( @_ ) || return( $self->error( "No token was provided to create associated rule" ) );
    ## If it's an at-rule
    if( substr( $token, 0, 1 ) eq '@' )
    {
    }
    else
    {
        my $selectors = $self->_split( $token );
    }
}

sub _split
{
    my $self = shift( @_ );
    my $token = shift( @_ );
    return( [] ) if( !length( $token ) );
    my $this = {};
    for( my $i = 0; $i < length( $token ); $i++ )
    {
        my $c = substr( $token, $i, 1 );
        my $next = substr( $token, $i + 1, 1 );
        my $prev = $i > 0 ? substr( $token, $i - 1, 1 ) : '';
        if( $this->{inside_quote} )
        {
            if( $c eq $this->{inside_quote} && $prev ne '\\' )
            {
                $this->{inside_quote} = '';
            }
            $this->{buffer} .= $c;
        }
    }
}

sub _trim
{
    my $self = shift( @_ );
    my $text = shift( @_ );
    return if( !length( $text ) );
    $text =~ s/^[[:blank:]\h\r\n\v]+|[[:blank:]\h\r\n\v]+$//gs;
    return( $text );
}

1;

__END__

=encoding utf-8

=head1 NAME

CSS::Object::Parser::Enhanced - CSS Object Oriented Enhanced Parser

=head1 SYNOPSIS

    use CSS::Object;
    my $css = CSS::Object->new(
        parser => 'CSS::Object::Parser::Enhanced',
        format => $format_object,
        debug => 3,
    ) || die( CSS::Object->error );
    $css->read( '/my/file.css' ) || die( $css->error );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

L<CSS::Object::Parser::Enhanced> is a lightweight, but thorough css parser. It aims at being very reliable and fast. The elements parsed are stored in a way so they can be stringified to produce a css stylesheet very close to the one that was parsed.

=head1 CONSTRUCTOR

=head2 new

To instantiate a new L<CSS::Object::Parser::Enhanced> object, pass an hash reference of following parameters:

=over 4

=item I<debug>

This is an integer. The bigger it is and the more verbose is the output.

=back

=head1 METHODS

=head2 add_rule

It takes 2 parameters: string of selectors and the rule content, i.e. inside the curly braces.

It creates a new L<CSS::Object::Rule> object, adds to it a new L<CSS::Object::Selector> object for each selector found and also add a new L<CSS::Object::Property> object for each property found.

It returns the rule object created.

=head2 parse_element

Provided with a set of parameters as an hash reference and this parse the element and returns a hash reference with 2 properties: I<rule> which is a L<CSS::Object::Rule> object and I<pos> which is an integer representing the position of the pointer in the parsed string.

=head2 parse_string

Provided with some css text data and this will parse it and return an array object of L<CSS::Object::Rule> objects. The array returned is an L<Module::Generic::Array> object.

It does this by calling L</add_rule> on each rule found in the css data provided.

Each L<CSS::Object::Rule> object containing one more more L<CSS::Object::Selector> objects and one or more L<CSS::Object::Property> objects.

=head2 rule_from_token

Provided with a css token and this returns an adequate rule object. CSS token can be a css selector, or an at rule

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<CSS::Object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
