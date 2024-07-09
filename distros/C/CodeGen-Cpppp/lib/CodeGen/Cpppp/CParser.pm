package CodeGen::Cpppp::CParser;

our $VERSION = '0.005'; # VERSION
# ABSTRACT: C Parser Utility Library

use v5.20;
use warnings;
use Carp;
use experimental 'signatures', 'postderef';

sub new {
   my $class= shift;
   my $self= bless {
      !(@_ & 1)? @_
      : @_ == 1 && ref $_[0] eq 'HASH'? %{$_[0]}
      : Carp::croak("Expected hashref or even-length list")
   }, $class;
}


sub tokenize {
   my ($class, undef, $tok_lim)= @_;
   my $textref= ref $_[1] eq 'SCALAR'? $_[1] : \$_[1];
   $class->_get_tokens($textref, $tok_lim);
}

sub CodeGen::Cpppp::CParser::Token::type    { $_[0][0] }
sub CodeGen::Cpppp::CParser::Token::value   { $_[0][1] }
sub CodeGen::Cpppp::CParser::Token::src_pos { $_[0][2] }
sub CodeGen::Cpppp::CParser::Token::src_len { $_[0][3] }

our %keywords= map +($_ => 1), qw( 
   auto break case char const continue default do double else enum extern
   float for goto if int long register return short signed sizeof static
   struct switch typedef union unsigned void volatile while

   inline _Bool _Complex _Imaginary

   __FUNCTION__ __PRETTY_FUNCTION__ __alignof __alignof__ __asm
   __asm__ __attribute __attribute__ __builtin_offsetof __builtin_va_arg
   __complex __complex__ __const __extension__ __func__ __imag __imag__ 
   __inline __inline__ __label__ __null __real __real__ 
   __restrict __restrict__ __signed __signed__ __thread __typeof
   __volatile __volatile__ 

   restrict
);
our %named_escape= (
   a => "\a", b => "\b", e => "\e", f => "\f",
   n => "\n", r => "\r", t => "\t", v => "\x0B"
);
our %tokens_before_infix_minus= map +($_ => 1), (
   ']', ')', 'integer','real','ident',
);
sub _get_tokens {
   my ($class, $textref, $tok_lim)= @_;
   pos($$textref)= 0 unless defined pos($$textref);
   my @tokens;
   local our $_type;
   local our $_value;
   local our $_error;
   while ((!defined $tok_lim || --$tok_lim >= 0)
      && $$textref =~ m{
         \G
         (?> \s* ) \K # ignore whitespace
         (?|
            # single-line comment
            // ( [^\r\n]* )
            (?{ $_type= 'comment' })

            # block comment
         |  /\* ( (?: [^*]+ | \* (?=[^/]) )* ) ( \*/ | \Z )
            (?{ $_type= 'comment'; $_error= "Reached end of input looking for '*/'" unless $2 })

            # Preprocessor directive
         |  \# \s* ( (?: [^\r\n\\]+ | \\ \r? \n | \\ (?=[^\r\n]) )* )
            (?{ $_type= 'directive' })

            # string literal
         |  " (?{ '' })
               (?|
                  ([^"\\]+)          (?{ $^R . $1 })
               |  \\x ([0-9A-Fa-f]+) (?{ $^R . chr(hex $1) })
               |  \\ ([0-9]{1,3})    (?{ $^R . chr(oct $1) })
               |  \\ \r?\n
               |  \\ (.)             (?{ $^R . ($named_escape{$1} // $1) })
               )*
            ( " | \Z )
            (?{ $_type= 'string'; $_value= $^R; $_error= q{Reached end of input looking for '"'} unless $2 })

            # character constant
         |  '  (?|
                  ([^'\\])           (?{ $1 })
               |  \\x ([0-9A-Fa-f]+) (?{ chr(hex $1) })
               |  \\ ([0-9]{1,3})    (?{ chr(oct $1) })
               |  \\ (.)             (?{ $named_escape{$1} // $1 })
               )
            ( '? )
            (?{ $_type= 'char'; $_value= $^R; $_error= q{Unterminated character constant} unless $2 })

            # identifier
         |  ( [A-Za-z_] \w* )
            (?{ $_type= $keywords{$1}? 'keyword' : 'ident' })

            # real number
         |  ( (?: [0-9]+ \. [0-9]* | \. [0-9]+ ) (?: e -? [0-9]+ )? [lLfF]? )
            (?{ $_type= 'real' })

         |  # integer
            (?|
               0x([A-Fa-f0-9]+) (?{ $_value= hex($1) })
            |  0([0-7]+)        (?{ $_value= oct($1) })
            |  ([0-9]+)
            )
            [uU]?[lL]*
            (?{ $_type= 'integer' })

         |  # punctuation and operators
            ( \+\+ | -- | -> | \+=? | -=? | \*=? | /=? | %=? | >>=? | >=? | <<=? | <=?
            | \&\&=? | \&=? | \|\|=? | \|=? | \^=? | ==? | !=? | \? | ~
            | [\[\]\(\)\{\};,.:]
            )
            (?{ $_type= $1 })
         
         |  # all other characters
            (.) (?{ $_type= 'unknown'; $_error= q{parse error} })
         )
      }xcg
   ) {
      my @token= ($_type, $_value // $1, $-[0], $+[0] - $-[0], defined $_error? ($_error) : ());
      # disambiguate negative number from minus operator
      if (($_type eq 'integer' || $_type eq 'real')
         && @tokens && $tokens[-1][0] eq '-'
         && (@tokens == 1 || !$tokens_before_infix_minus{$tokens[-2]->type})
      ) {
         $token[1]= -$token[1];
         $token[2]= $tokens[-1][2];
         $token[3]= $+[0] - $tokens[-1][2];
         @{$tokens[-1]}= @token;
      } else {
         push @tokens, bless \@token, 'CodeGen::Cpppp::CParser::Token';
      }
      ($_error, $_value)= (undef, undef);
   }
   return @tokens;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CodeGen::Cpppp::CParser - C Parser Utility Library

=head1 METHODS

=head2 tokenize

  @tokens= $class->tokenize($string);
  @tokens= $class->tokenize(\$string);
  @tokens= $class->tokenize(\$string, $max_tokens);

Parse some number of C language tokens from the input string, and update the
regex C<pos()> of the string so that you can resume parsing more tokens later.
Since this updates the pos of the string, you can pass it as a reference to
make it more clear to readers what is happening.

If C<$max_tokens> is given, only that many tokens will be returned.

Whitespace is ignored (not returned as a token) except for whitespace contained
in a 'directive' token.  The body of a directive needs further tokenized.

Each token is an arrayref of the form:

  [ $type, $value, $offset, $length, $error=undef ]
  
  $type:   'directive', 'comment', 'string', 'char', 'real', 'integer',
           'keyword', 'ident', 'unknown', or any punctuation character
  
  $value:  for constants, this is the decoded string or numeric value
           for directives and comments, it is the body text
           for punctuation, it is a copy of $type
           for unknown, it is the exact character that didn't parse
  
  $src_pos: the character offset within the source $string
  
  $src_len: the number of characters occupied in the source $string
  
  $error: if the token is invalid in some way, but still undisputedly that
          type of token (e.g. unclosed string or unclosed comment) it will be
          returned with a 5th element containing the error message.

For some tokens, you will need to inspect C<< substr($string, $offset, $length) >>
to get the full details, like the suffixes on integer constants.

Consecutive string tokens are not merged, since the parser needs to handle
that step after preprocessor macros are substituted.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 VERSION

version 0.005

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
