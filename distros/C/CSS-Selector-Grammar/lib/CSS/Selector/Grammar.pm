package CSS::Selector::Grammar;
$CSS::Selector::Grammar::VERSION = '0.002';
# ABSTRACT: Generate parse trees for CSS3 selectors.


use v5.10;
use strict;
use warnings;

use parent 'Exporter';

our @EXPORT = qw(parse_selector);

{
    use Regexp::Grammars;

    # lexemes
    qr/

    <grammar: CSS3::Lexemes>
    <nocontext:>
    
    <token: ident>     [-]?<.nmstart><.nmchar>*
    <token: name>      <.nmchar>+
    <token: nmstart>   [_a-zA-Z]|<.nonascii>|<.escape>
    <token: nonascii>  [^\0-\177]
    <token: unicode>   \\[0-9a-fA-F]{1,6}(?:\r\n|[ \n\r\t\f])?+
    <token: escape>    <.unicode>|\\[^\n\r\f0-9a-f]
    <token: nmchar>    [_a-zA-Z0-9-]|<.nonascii>|<.escape>
    <token: num>       [0-9]+|[0-9]*\.[0-9]++
    <token: string>    <.string1>|<.string2>
    <token: string1>   \"(?:[^\n\r\f\\"]|\\<.nl>|<.nonascii>|<.escape>)*+\"
    <token: string2>   \'(?:[^\n\r\f\\']|\\<.nl>|<.nonascii>|<.escape>)*+\'
    <token: invalid>   <.invalid1>|<.invalid2>
    <token: invalid1>  \"(?:[^\n\r\f\\"]|\\<.nl>|<.nonascii>|<.escape>)*+
    <token: invalid2>  \'(?:[^\n\r\f\\']|\\<.nl>|<.nonascii>|<.escape>)*+
    <token: nl>        \n|\r\n|\r|\f
    <token: w>         [ \t\r\n\f]*+
    
    <token: D>         (?i:d|\\0{0,4}(?:44|64)(?:\r\n|[ \t\r\n\f])?)
    <token: E>         (?i:e|\\0{0,4}(?:45|65)(?:\r\n|[ \t\r\n\f])?)
    <token: N>         (?i:n|\\0{0,4}(?:4e|6e)(?:\r\n|[ \t\r\n\f])?|\\n)
    <token: O>         (?i:o|\\0{0,4}(?:4f|6f)(?:\r\n|[ \t\r\n\f])?|\\o)
    <token: T>         (?i:t|\\0{0,4}(?:54|74)(?:\r\n|[ \t\r\n\f])?|\\t)
    <token: V>         (?i:v|\\0{0,4}(?:58|78)(?:\r\n|[ \t\r\n\f])?|\\v)
    
    <token: S> [ \t\r\n\f]+
    
    <token: INCLUDES>       ~=
    <token: DASHMATCH>      \|=
    <token: PREFIXMATCH>    \^=
    <token: SUFFIXMATCH>    \$=
    <token: SUBSTRINGMATCH> \*=
    <token: IDENT>          <context:> <i=(?{$INDEX})> <.ident>
    <token: STRING>         <context:> <i=(?{$INDEX})> <.string>
    <token: FUNCTION>       <context:> <i=(?{$INDEX})> <.ident> \(
    <token: NUMBER>         <context:> <i=(?{$INDEX})> <.num>
    <token: HASH>           <context:> <i=(?{$INDEX})> \# <.name>
    <token: PLUS>           <.w> \+
    <token: GREATER>        <.w> \>
    <token: COMMA>          <.w> ,
    <token: TILDE>          <.w> ~
    <token: NOT>            : <.N><.O><.T> \(
    <token: ATKEYWORD>      <context:> <i=(?{$INDEX})> @ <.ident>
    <token: INVALID>        <context:> <i=(?{$INDEX})> <.invalid>
    <token: PERCENTAGE>     <context:> <i=(?{$INDEX})> <.num> %
    <token: DIMENSION>      <context:> <i=(?{$INDEX})> <.num> <.ident>
    <token: CDO>            <context:> <i=(?{$INDEX})> \<!--
    <token: CDC>            --\>

    /x;

    # productions
    qr/

    <grammar: CSS3::Selectors>
    <extends: CSS3::Lexemes>
    
    <token: selectors_group>
        <[selector]> (?: <.COMMA> <.S>* <[selector]> )*
    
    <token: selector>
        <first=simple_selector_sequence> <[combined_simple_selector]>*
    
    <token: combined_simple_selector>
        <combinator> <simple_selector_sequence>
    
    <token: combinator>
        <i=(?{$INDEX})> 
        (?: <PLUS> <.S>* | <GREATER> <.S>* | <TILDE> <.S>* | <.S>+ )
    
    <token: simple_selector_sequence>
        <initial_selector>
        <[simple_selector_sequence_element]>*
        | 
        <[simple_selector_sequence_element]>+

    <token: initial_selector>
        <type_selector> | <universal>
    
    <token: simple_selector_sequence_element>
        <HASH> | <class> | <attrib> | <pseudo> | <negation>
    
    <token: type_selector>
        <namespace_prefix>? <element_name>
    
    <token: namespace_prefix>
        <i=(?{$INDEX})>
        (?:  <IDENT> | \*  )? \|
    
    <token: element_name> <IDENT>
    
    <token: universal>
        <i=(?{$INDEX})>
        <namespace_prefix>? \*
    
    <token: class>
        <i=(?{$INDEX})> \. <IDENT>
    
    <token: attrib>
        <i=(?{$INDEX})> 
        \[
        <.S>* <attrib_name> <.S>*
        (?: <comparator> <.S>* <attrib_value> <.S>*)?
        \]

    <token: attrib_name>
        (?: <namespace_prefix> )? <IDENT>
    
    <token: attrib_value>
        <IDENT> | <STRING>
    
    <token: comparator>
        <PREFIXMATCH>    |
        <SUFFIXMATCH>    |
        <SUBSTRINGMATCH> |
        =                |
        <INCLUDES>       |
        <DASHMATCH>

    <token: pseudo>
        <i=(?{$INDEX})> 
        \:{1,2} (?: <IDENT> | <functional_pseudo> )
    
    <token: functional_pseudo>
        <.FUNCTION> <.S>* <expression> \)
    
    <token: expression>
        (?: <[expression_element]> <.S>* )+

    <token: expression_element>
        <i=(?{$INDEX})> 
        (?:
        <PLUS>      |
        \-          |
        <DIMENSION> |
        <NUMBER>    |
        <STRING>    |
        <IDENT>
        )
    
    <token: negation>
        <.NOT> <.S>* <negation_arg> <.S>* \)
    
    <token: negation_arg>
        <type_selector> |
        <universal>     |
        <HASH>          |
        <class>         |
        <attrib>        |
        <pseudo>

    /x;
}


sub parse_selector {
    state $rx = do {
        use Regexp::Grammars;
        qr/
            \A \s*+ <selectors_group> \s* \z
            <extends: CSS3::Selectors>
        /x;
    };
    return {%/} if shift =~ $rx;
    return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CSS::Selector::Grammar - Generate parse trees for CSS3 selectors.

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use CSS::Selector::Grammar;

  my $ast = parse_selector('html|*:not(:link):not(:visited)');

=head1 DESCRIPTION

L<CSS::Selector::Grammar> translates the grammar defined in
L<http://www.w3.org/TR/css3-selectors/#w3cselgrammar> into the
L<Regexp::Grammars> formalism with a few minimal changes in structure, but not
semantics, to facilitate examining the resulting parse tree.

L<CSS::Selector::Grammar> exports one function by default: C<parse_selector>. If
you are using L<Regexp::Grammars>, it also defines two grammars: C<CSS3::Lexemes>
and C<CSS3::Selectors>.

In addition to the normal output of L<Regexp::Grammars>, certain nodes in the
CSS selector parse trees will have an C<i> attribute representing the index of
their first character. E.g.,

  parse_selector('*[foo]');

gives you

  {
      ''                => '*[foo]',
      'selectors_group' => {
          ''         => '*[foo]',
          'selector' => [
              {
                  ''      => '*[foo]',
                  'first' => {
                      ''                 => '*[foo]',
                      'initial_selector' => {
                          ''          => '*',
                          'universal' => {
                              ''  => '*',
                              'i' => '0'
                          }
                      },
                      'simple_selector_sequence_element' => [
                          {
                              ''       => '[foo]',
                              'attrib' => {
                                  ''            => '[foo]',
                                  'attrib_name' => {
                                      ''      => 'foo',
                                      'IDENT' => {
                                          ''  => 'foo',
                                          'i' => '2'
                                      }
                                  }
                              }
                          }
                      ]
                  }
              }
          ]
      }
  };

In general, identifiers and strings will have their index indicated.

=head1 FUNCTIONS

=head2 parse_selector

  my $ast = parse_selector($expression);

For a given selector returns a parse tree, or C<undef> if the grammar cannot
parse the expression.

=head1 KNOWN BUGS

L<Regexp::Grammars> itself does not work with Perl version 5.18, so if that's
your version, L<CSS::Selector::Grammar> won't work for you either. I suggest
you try L<App::perlbrew>.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
