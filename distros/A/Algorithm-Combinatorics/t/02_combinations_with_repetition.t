use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More qw(no_plan);

use Algorithm::Combinatorics qw(combinations_with_repetition);
use Tester;

my $tester = Tester->__new(\&combinations_with_repetition);

my (@result, @expected);

# ---------------------------------------------------------------------

eval { combinations_with_repetition() };
ok($@, '');

eval { combinations_with_repetition([1]) };
ok($@, '');

eval { combinations_with_repetition(0, 0) };
ok($@, '');

# ---------------------------------------------------------------------

@expected = ([]);
$tester->__test(\@expected, [], 0);

@expected = ([]);
$tester->__test(\@expected, [1, 2], 0);

# ---------------------------------------------------------------------

@expected = (["foo"]);
$tester->__test(\@expected, ["foo"], 1);

# ---------------------------------------------------------------------

@expected = (["foo"], ["bar"]);
$tester->__test(\@expected, ["foo", "bar"], 1);

# ---------------------------------------------------------------------

@expected = (
    ["foo", "foo"],
    ["foo", "bar"],
    ["bar", "bar"],
);
$tester->__test(\@expected, ["foo", "bar"], 2);

# ---------------------------------------------------------------------

@expected = (
    ["foo", "foo", "foo"],
    ["foo", "foo", "bar"],
    ["foo", "bar", "bar"],
    ["bar", "bar", "bar"],
);
$tester->__test(\@expected, ["foo", "bar"], 3);

# ---------------------------------------------------------------------

@expected = (
    ["foo", "foo"],
    ["foo", "bar"],
    ["foo", "baz"],
    ["bar", "bar"],
    ["bar", "baz"],
    ["baz", "baz"],
);
$tester->__test(\@expected, ["foo", "bar", "baz"], 2);

# ---------------------------------------------------------------------

@expected = (
    [0, 0, 0],
    [0, 0, 1],
    [0, 0, 2],
    [0, 0, 3],
    [0, 1, 1],
    [0, 1, 2],
    [0, 1, 3],
    [0, 2, 2],
    [0, 2, 3],
    [0, 3, 3],
    [1, 1, 1],
    [1, 1, 2],
    [1, 1, 3],
    [1, 2, 2],
    [1, 2, 3],
    [1, 3, 3],
    [2, 2, 2],
    [2, 2, 3],
    [2, 3, 3],
    [3, 3, 3],
);
$tester->__test(\@expected, [0..3], 3);

# ----------------------------------------------------------------------

# n+k-1 over k
my $ncomb = 0;
my $iter = combinations_with_repetition([1..15], 5);
while (my $c = $iter->next) {
    ++$ncomb;
}
is($ncomb, 11628, "");

$ncomb = 0;
$iter = combinations_with_repetition([1..7], 11);
while (my $c = $iter->next) {
    ++$ncomb;
}
is($ncomb, 12376, "");
