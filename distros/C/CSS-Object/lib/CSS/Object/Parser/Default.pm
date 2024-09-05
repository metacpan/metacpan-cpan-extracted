##----------------------------------------------------------------------------
## CSS Object Oriented - ~/lib/CSS/Object/Parser/Default.pm
## Version v0.2.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/08/09
## Modified 2024/09/05
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package CSS::Object::Parser::Default;
BEGIN
{
    use strict;
    use warnings;
    use Module::Generic;
    use parent qw( CSS::Object::Parser );
    use CSS::Object::Rule;
    use CSS::Object::Selector;
    use CSS::Object::Property;
    our $VERSION = 'v0.2.0';
};

## add a style to the style list
# From css spec at http://www.w3.org/TR/REC-CSS2/selector.html#q1
#  *                    Matches any element.    Universal selector
#  E                    Matches any E element (i.e., an element of type E).
#  E F                  Matches any F element that is a descendant of an E element.
#  E > F             Matches any F element that is a child of an element E.
#  E:first-child        Matches element E when E is the first child of its parent.
#  E + F                Matches any F element immediately preceded by a sibling element E.
#  E[foo]               Matches any E element with the "foo" attribute set (whatever the value).
#  E[foo="warning"]     Matches any E element whose "foo" attribute value is exactly equal to "warning".
#  E[foo~="warning"]    Matches any E element whose "foo" attribute value is a list of space-separated values,
#                       one of which is exactly equal to "warning".
#  E[lang|="en"]        Matches any E element whose "lang" attribute has a hyphen-separated list of values
#                       beginning (from the left) with "en".
#  DIV.warning          Language specific. (In HTML, the same as DIV[class~="warning"].)
#  E#myid               Matches any E element with ID equal to "myid".  ID selectors
sub add_rule
{
    my $self = shift( @_ );
    my $style = shift( @_ );
    my $contents = shift( @_ );
    my $css = $self->css || return( $self->error( "Our css object is gone!" ) );
    
    # my $rule = CSS::Object::Rule->new(
    my $rule = $css->new_rule(
        # format => $self->format,
        debug   => $self->debug,
    ) || return( $self->pass_error( CSS::Object::Rule->error ) );

    ## parse the selectors
    for my $name ( split( /[[:blank:]\h]*,[[:blank:]\h]*/, $style ) )
    {
        ## my $sel = CSS::Object::Selector->new({
        my $sel = $css->new_selector(
            name   => $name,
            # format => $self->format,
            debug  => $self->debug,
        ) || return( $self->error( "Unable to create a new CSS::Object::Selector objet: ", CSS::Object::Selector->error ) );
        $rule->add_selector( $sel ) || return( $self->error( "Unable to add selector name '$name' to rule: ", $rule->error ) );
    }

    ## parse the properties
    ## Check possible comments and replace any ';' inside so they do not mess up this parsing here
    $contents =~ s{\/\*[[:blank:]\h]*(.*?)[[:blank:]\h]*\*\/}
    {
        my $cmt = $1;
        $cmt =~ s/\;/__SEMI_COLON__/gs;
        $cmt =~ s/\:/__COLON__/gs;
        "/* $cmt */";
    }sex;
    foreach( grep{ /\S/ } split( /\;/, $contents ) )
    {
        ## Found one or more comments before the property
        while( s/^[[:blank:]\h]*\/\*[[:blank:]\h]*(.*?)[[:blank:]\h]*\*\///s )
        {
            my $txt = $1;
            $txt =~ s/__SEMI_COLON__/\;/gs;
            $txt =~ s/__COLON__/\:/gs;
            my $cmt = $css->new_comment( [split( /\r?\n/, $txt )] ) || return( $self->error( "Unable to create a new CSS::Object::Comment object: ", CSS::Object::Comment->error ) );
            $rule->add_element( $cmt ) || return( $self->error( "Unable to add comment element to our rule: ", $rule->error ) );
        }
        
        unless( /^[[:blank:]\h]*(?<name>[\w\.\_\-]+)[[:blank:]\h]*:[[:blank:]\h]*(?<value>.*?)[[:blank:]\h]*$/ )
        {
            return( $self->error( "Invalid or unexpected property '$_' in style '$style'" ) );
        }
        ## Put back the colon we temporarily substituted to avoid confusion in the parser
        $+{value} =~ s/__COLON__/\:/gs;
        # my( $prop_name, $prop_val ) = @+{qw(name value)};
        my $prop = CSS::Object::Property->new({
            debug       => $self->debug,
            name        => $+{name},
            value       => $+{value},
            # format      => $rule->format,
        }) || return( $self->error( "Unable to create a new CSS::Object::Property object: ", CSS::Object::Property->error ) );
        $rule->add_property( $prop ) || return( $self->error( "Unable to add property name '$+{name}' to rule: ", $rule->error ) );
    }
    # push( @{$self->{parent}->{styles}}, $rule );
    return( $rule );
}

sub parse_string
{
    my $self = shift( @_ );
    my $string = shift( @_ );

    $string =~ s/\r\n|\r|\n/ /g;
    
    my $rules = Module::Generic::Array->new;
    ## Split into styles
    foreach( grep{ /\S/ } split( /(?<=\})/, $string ) )
    {
        unless( /^[[:blank:]\h]*([^{]+?)[[:blank:]\h]*\{(.*)\}[[:blank:]\h]*$/ )
        {
            return( $self->error( "Invalid or unexpected style data '$_'" ) );
        }
        my $rule = $self->add_rule( $1, $2 ) || return( $self->pass_error );
        $rules->push( $rule );
    }   
    return( $rules );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

CSS::Object::Parser::Default - CSS Object Oriented Default Parser

=head1 SYNOPSIS

    use CSS::Object;
    my $css = CSS::Object->new(
        parser => 'CSS::Object::Parser::Default',
        format => $format_object,
        debug => 3,
    ) || die( CSS::Object->error );
    $css->read( '/my/file.css' ) || die( $css->error );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

L<CSS::Object::Parser::Default> is a simple lightweight css parser.

=head1 CONSTRUCTOR

=head2 new

To instantiate a new L<CSS::Object::Parser::Default> object, pass an hash reference of following parameters:

=over 4

=item I<debug>

This is an integer. The bigger it is and the more verbose is the output.

=back

=head1 METHODS

=head2 add_rule

It takes 2 parameters: string of selectors and the rule content, i.e. inside the curly braces.

It creates a new L<CSS::Object::Rule> object, adds to it a new L<CSS::Object::Selector> object for each selector found and also add a new L<CSS::Object::Property> object for each property found.

It returns the rule object created.

=head2 parse_string

Provided with some css text data and this will parse it and return an array object of L<CSS::Object::Rule> objects. The array returned is an L<Module::Generic::Array> object.

It does this by calling L</add_rule> on each rule found in the css data provided.

Each L<CSS::Object::Rule> object containing one more more L<CSS::Object::Selector> objects and one or more L<CSS::Object::Property> objects.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<CSS::Object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
