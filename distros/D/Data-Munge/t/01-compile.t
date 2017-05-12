#!perl

use Test::More tests => 64;
use Test::Warnings;

use warnings FATAL => 'all';
use strict;
use Data::Munge;

{
    my $str = "abc|bar|baz|foo|\\*\\*|ab|\\!|\\*|a";
    is list2re(qw[! a abc ab foo bar baz ** *]), qr/$str/, 'list2re';
}

is +(byval { s/foo/bar/ } 'foo-foo'), 'bar-foo', 'byval';
is_deeply [mapval { tr[a-d][1-4] } 'foo', 'bar', 'baz'], [qw[foo 21r 21z]], 'mapval';

is replace('Apples are round, and apples are juicy.', qr/apples/i, 'oranges', 'g'), 'oranges are round, and oranges are juicy.', 'replace g';
is replace('John Smith', qr/(\w+)\s+(\w+)/, '$2, $1'), 'Smith, John', 'replace';
is replace('97653 foo bar 42', qr/(\d)(\d)/, sub { $_[1] + $_[2] }, 'g'), '16113 foo bar 6', 'replace fun g';

"foo bar" =~ /(\w+) (\w+)/ or die;
is_deeply [submatches], [qw(foo bar)];
"" =~ /^/ or die;
is_deeply [submatches], [];

is trim("  a  b  "), "a  b";
is trim(""), "";
is trim(","), ",";
is trim(" "), "";
is trim("  "), "";
is trim("\na"), "a";
is trim("b\t"), "b";
is trim("X\nY \n "), "X\nY";
is trim(undef), undef;

{
    my $fac = rec {
        my ($rec, $n) = @_;
        $n < 2 ? 1 : $n * $rec->($n - 1)
    };
    is $fac->(5), 120;
    is $fac->(6), 720;
}

is eval_string('"ab" . "cd"'), 'abcd';
is eval { eval_string('{') }, undef;
like $@, qr/Missing right curly/;
is eval { eval_string '$VERSION' }, undef;
like $@, qr/Global symbol "\$VERSION"/;

ok !elem 42, [];
ok elem 42, [42];
ok elem "A",   [undef, [], "A", "B"];
ok elem "B",   [undef, [], "A", "B"];
ok elem undef, [undef, [], "A", "B"];
ok !elem [],   [undef, [], "A", "B"];
ok !elem "C",  [undef, [], "A", "B"];
for my $ref ([], {}, sub {}) {
    ok !elem $ref, [];
    ok !elem $ref, [undef];
    ok !elem $ref, ["$ref"];
    ok !elem "$ref", [$ref];
    ok !elem $ref, [[], {}];
    ok elem $ref, [$ref];
    ok elem $ref, ["A", "B", $ref];
    ok elem $ref, ["A", $ref, "B"];
    ok elem $ref, [$ref, "A", $ref, $ref];
    ok elem $ref, [undef, $ref];
}

my $source = slurp \*DATA;
like $source, qr/\AThis is the beginning\.\n/;
like $source, qr/\nThis is the end\.\Z/;

__DATA__
This is the beginning.
stuff
etc.
This is the end.
