use warnings;
no warnings qw(deprecated void);

use Test::More tests => 24;

is(qw(a b c d e f)[4], "e");
is(substr("abcdef", 4, 1), "e");

use Classic::Perl qw($[);

is(qw(a b c d e f)[4], "e");
is(substr("abcdef", 4, 1), "e");

$[ = 2;

is(qw(a b c d e f)[4], "c");
is(substr("abcdef", 4, 1), "c");

{
 local $[ = 3;
 is(qw(a b c d e f)[4], "b");
 is(substr("abcdef", 4, 1), "b");
}

is(qw(a b c d e f)[4], "c");
is(substr("abcdef", 4, 1), "c");

{
 local $[ = 1;
 is(qw(a b c d e f)[4], "d");
 is(substr("abcdef", 4, 1), "d");
}

is(qw(a b c d e f)[4], "c");
is(substr("abcdef", 4, 1), "c");

{
 local($[) = 1;
 is(qw(a b c d e f)[4], "d");
 is(substr("abcdef", 4, 1), "d");
}

is(qw(a b c d e f)[4], "c");
is(substr("abcdef", 4, 1), "c");

{
 local $[ = 0;
 is(qw(a b c d e f)[4], "e");
 is(substr("abcdef", 4, 1), "e");
}

is(qw(a b c d e f)[4], "c");
is(substr("abcdef", 4, 1), "c");

$[ = 0;

is(qw(a b c d e f)[4], "e");
is(substr("abcdef", 4, 1), "e");

1;
