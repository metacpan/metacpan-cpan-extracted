use warnings;
use strict;
use Test::More;
BEGIN { use_ok('C::Tokenize') };
BEGIN { use_ok('C::Tokenize', '$trad_comment_re', 'decomment') };
BEGIN { use_ok('C::Tokenize', ':all') };
use C::Tokenize 'tokenize';

my $tokens;

# Test for not eating subsequent text up to another comment.

my $long_comment =<<'EOF';
/****************************************************************************

  Globals read from font file

****************************************************************************/

char		hardblank;
int		charheight;
_Bool wolf;
/* Bogus */
EOF

$tokens = tokenize ($long_comment);

my $found;

my @expect = (
    ['comment', qr/Globals/],
    ['reserved', qr/char/],
    ['word', qr/hardblank/],
    ['grammar', qr/;/],
    ['reserved', qr/int/],
    ['word', qr/charheight/],
    ['grammar', qr/;/],
    ['reserved', qr/_Bool/],
    ['word', qr/wolf/],
    ['grammar', qr/;/],
    ['comment', qr/bogus/i],
);

is (scalar @$tokens, scalar @expect, "Same number of tokens");

for my $i (0..$#expect) {
    my $token = $tokens->[$i];
    my $expect = $expect[$i];
    my $type = $token->{type};
    is ($type, $expect->[0], "$type is $expect->[0]");
    my $value = $token->{$type};
    like ($value, $expect->[1], "$value matches $expect->[1]");
}

# Test for comments within preprocessor instructions

my $cpp_comment =<<'EOF';
#define SMO_YES 1		/* use command-line smushmode, ignore font
				 * smushmode */
EOF
$tokens = tokenize ($cpp_comment);
is (@$tokens, 1, "Comment in CPP with newline");

like ($long_comment, qr/$trad_comment_re/);

my $stuff = "babu\nchabu";
my $comment = "/*$stuff*/";
my $decommented = decomment ($comment);

is ($decommented, $stuff, "Test decomment for multiline comments");

my $octal_1 = '012345';
like ($octal_1, $C::Tokenize::octal_re, "octal matches");
my $out = decomment ('/* comment */');
is ($out, " comment ");

like ('==', $operator_re, "Double equals is operator");
my $double_eq = '==';
ok ($double_eq =~ /($operator_re)/, "== matches bracketed op");
ok ($1 eq $double_eq);

done_testing ();

# Local variables:
# mode: perl
# End:
