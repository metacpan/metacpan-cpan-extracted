package C::Tokenize;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/tokenize
                decomment
		remove_quotes
                @fields
		$include
		$include_local
                $char_const_re
                $comment_re
                $cpp_re
		$cvar_re
                $cxx_comment_re
		$decimal_re
                $grammar_re
		$hex_re
                $number_re
		$octal_re
                $operator_re
                $reserved_re
                $single_string_re
                $string_re
                $trad_comment_re
                $word_re
               /;

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

use warnings;
use strict;
our $VERSION = '0.13';

# http://www.open-std.org/JTC1/SC22/WG14/www/docs/n1256.pdf
# 6.4.1

my @reserved_words = sort {length $b <=> length $a} 
qw/
auto
break
case
char
const
continue
default
do
double
else
enum
extern
float
for
goto
if
inline
int
long
register
restrict
return
short
signed
sizeof
static
struct
switch
typedef
union
unsigned
void
volatile
while
_Bool
_Complex
_Imaginary
/;

my $reserved_words = join '|', @reserved_words;
our $reserved_re = qr/\b(?:$reserved_words)\b/;

our @fields = qw/comment cpp char_const operator grammar 
                 number word string reserved/;

# Regular expression to match a /* */ C comment.

our $trad_comment_re = qr!
                            /\*
                            (?:
                                # Match "not an asterisk"
                                [^*]
                            |
                                # Match multiple asterisks followed
                                # by anything except an asterisk or a
                                # slash.
                                \*+[^*/]
                            )*
                            # Match multiple asterisks followed by a
                            # slash.
                            \*+/
                        !x;

# Regular expression to match a // C comment (C++-style comment).

our $cxx_comment_re = qr!//.*\n!;

# Master comment regex

our $comment_re = qr/
                       (?:
                           $trad_comment_re
                       |
                           $cxx_comment_re
                       )
                   /x;

# Regular expression to match a C preprocessor instruction.

our $cpp_re = qr/^\h*
                 \#
                 (?:
                    $trad_comment_re
                |
                    [^\\\n]
                |
                    \\[^\n]
                |
                    \\\n
                )+\n
               /mx;

# Regular expression to match a C character constant like 'a' or '\0'.
# This allows any \. expression at all.

our $char_const_re = qr/
                          '
                          (?:
                              .
                          |
                              \\.
                          )
                          '
                      /x;

# Regular expression to match one character operators

our $one_char_op_re = qr/(?:\%|\&|\+|\-|\=|\/|\||\.|\*|\:|>|<|\!|\?|~|\^)/;

# Regular expression to match all operators

our $operator_re = qr/
                        (?:
                                # Operators with two characters
                                \|\||&&|<<|>>|--|\+\+|->
                            |
                                # Operators with one or two characters
                                # followed by an equals sign.
                                (?:<<|>>|\+|-|\*|\/|%|&|\||\^)
                                =
                            |
                                $one_char_op_re
                            )
                    /x;

# Re to match a C number

our $octal_re = qr/0[0-7]+/;

our $decimal_re = qr/[-+]?([0-9]*\.)?[0-9]+([eE][-+]?[0-9]+)?l?/i;

our $hex_re = qr/0x[0-9a-f]+l?/i;

our $number_re = qr/
                      (?:
                          $hex_re
                      |
                          $decimal_re
		      |
			  $octal_re
                      )
                  /x;

# Re to match a C word

our $word_re = qr/[a-z_](?:[a-z_0-9]*)/i;

# Re to match C grammar

our $grammar_re = qr/[(){};,\[\]]/;

# Regular expression to match a C string.

our $single_string_re = qr/
                             (?:
                                 "
                                 (?:[^\\"]+|\\[^"]|\\")*
                                 "
                             )
                         /x;


# Compound string regular expression.

our $string_re = qr/$single_string_re(?:\s*$single_string_re)*/;

# Master regular expression for tokenizing C text. This uses named
# captures.
    
our $c_re = qr/
                 (?<leading>\s+)?
                 (?:
                     (?<comment>$comment_re)
                 |
                     (?<cpp>$cpp_re)
                 |
                     (?<char_const>$char_const_re)
                 |
                     (?<operator>$operator_re)
                 |
                     (?<grammar>$grammar_re)
                 |
                     (?<number>$number_re)
                 |
                     (?<reserved>$reserved_re)
                 |
                     (?<word>$word_re)
                 |
                     (?<string>$string_re)
                 )
             /x;


# Match for '#include "file.h"'. This captures the entire #include
# statement in $1 and the file name in $2.

our $include_local = qr/
			  ^
			  (\#
			      \s*
			      include
			      \s*
			      "([a-zA-Z0-9\-]+\.h)"
			  )
			  (\s|$comment_re)*
			  $
		      /smx;

our $include = qr/
			  ^
			  (\#
			      \s*
			      include
			      \s*
			      ["<]
			      ([a-zA-Z0-9\-]+\.h)
			      [">]
			  )
			  (\s|$comment_re)*
			  $
		 /smx;

my $deref = qr!
		  [\*&]+\s*$word_re
	      !x;

my $array_re = qr!
		     $word_re
		     \s*
		     \[
		     \s*
		     $word_re
		     \s*
		     \]
		 !x;

my $member = qr!
		     (?:
			 (?:
			     ->
			 |
			     \.
			 )
			 $word_re
		     |
			 $array_re
		     )
	       !x;

# Any C variable which can be used as an lvalue or a function argument.

our $cvar_re = qr!
		 (?:
		     # Any deferenced value
		     $deref
		 |
		     # A word or a dereferenced value in brackets
		     (?:
			 $word_re
		     |
			 $array_re
		     |
			 \(\s*$deref\)
		     )
		     # Followed by zero or more struct member
		     $member*
		 )
	     !x;

sub decomment
{
    my ($comment) = @_;
    $comment =~ s/^\/\*(.*)\*\/$/$1/sm;
    return $comment;
}

sub tokenize
{
    my ($text) = @_;

    # This array contains array references, each of which is a pair of
    # start and end points of a line in $text.

    my @lines = get_lines ($text);

    # The tokens the input is broken into.

    my @tokens;

    my $line = 1;
    while ($text =~ /\G($c_re)/g) {
        my $match = $1;
        if ($match =~ /^\s+$/s) {
            die "Bad match.\n";
        }
	# Add one to the line number while
        while ($match =~ /\n/g) {
            $line++;
        }
        my %element;
        # Store the whitespace in front of the element.
        if ($+{leading}) {
            $element{leading} = $+{leading};
        }
        else {
            $element{leading} = '';
        }
        $element{line} = $line;
        my $matched;
        for my $field (@fields) {
            if (defined $+{$field}) {
                $element{type} = $field;
                $element{$field} = $+{$field};
                $matched = 1;
                last;
            }
        }
        if (! $matched) {
            die "Bad regex $line: '$match'\n";
        }

        push @tokens, \%element;
    }

    return \@tokens;
}

# The return value is an array containing start and end points of the
# lines in $text.

sub get_lines
{
    my ($text) = @_;
    my @lines;
    my $start = 0;
    my $end;
    my $line = 1;
    while ($text =~ /\n/g) {
        $end = pos $text;
        $lines[$line] = {start => $start, end => $end};
        $line++;
        $start = $end + 1;
    }
    return @lines;
}

1;
