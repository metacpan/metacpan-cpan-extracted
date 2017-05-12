use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More qw(no_plan);

use Algorithm::Combinatorics qw(variations_with_repetition);
use Tester;

my $tester = Tester->__new(\&variations_with_repetition);

my (@result, @expected);

# ---------------------------------------------------------------------

eval { variations_with_repetition() };
ok($@, '');

eval { variations_with_repetition([1]) };
ok($@, '');

eval { variations_with_repetition(0, 0) };
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
    ["bar", "foo"],
    ["bar", "bar"],
);
$tester->__test(\@expected, ["foo", "bar"], 2);

# ---------------------------------------------------------------------

@expected = (
    ["foo", "foo", "foo"],
    ["foo", "foo", "bar"],
    ["foo", "bar", "foo"],
    ["foo", "bar", "bar"],
    ["bar", "foo", "foo"],
    ["bar", "foo", "bar"],
    ["bar", "bar", "foo"],
    ["bar", "bar", "bar"],
);
$tester->__test(\@expected, ["foo", "bar"], 3);

# ---------------------------------------------------------------------

@expected = (
    ["foo", "foo"],
    ["foo", "bar"],
    ["foo", "baz"],
    ["bar", "foo"],
    ["bar", "bar"],
    ["bar", "baz"],
    ["baz", "foo"],
    ["baz", "bar"],
    ["baz", "baz"],
);
$tester->__test(\@expected, ["foo", "bar", "baz"], 2);

# ---------------------------------------------------------------------

@expected = (
    [0, 0, 0],
    [0, 0, 1],
    [0, 0, 2],
    [0, 0, 3],
    [0, 1, 0],
    [0, 1, 1],
    [0, 1, 2],
    [0, 1, 3],
    [0, 2, 0],
    [0, 2, 1],
    [0, 2, 2],
    [0, 2, 3],
    [0, 3, 0],
    [0, 3, 1],
    [0, 3, 2],
    [0, 3, 3],

    [1, 0, 0],
    [1, 0, 1],
    [1, 0, 2],
    [1, 0, 3],
    [1, 1, 0],
    [1, 1, 1],
    [1, 1, 2],
    [1, 1, 3],
    [1, 2, 0],
    [1, 2, 1],
    [1, 2, 2],
    [1, 2, 3],
    [1, 3, 0],
    [1, 3, 1],
    [1, 3, 2],
    [1, 3, 3],

    [2, 0, 0],
    [2, 0, 1],
    [2, 0, 2],
    [2, 0, 3],
    [2, 1, 0],
    [2, 1, 1],
    [2, 1, 2],
    [2, 1, 3],
    [2, 2, 0],
    [2, 2, 1],
    [2, 2, 2],
    [2, 2, 3],
    [2, 3, 0],
    [2, 3, 1],
    [2, 3, 2],
    [2, 3, 3],

    [3, 0, 0],
    [3, 0, 1],
    [3, 0, 2],
    [3, 0, 3],
    [3, 1, 0],
    [3, 1, 1],
    [3, 1, 2],
    [3, 1, 3],
    [3, 2, 0],
    [3, 2, 1],
    [3, 2, 2],
    [3, 2, 3],
    [3, 3, 0],
    [3, 3, 1],
    [3, 3, 2],
    [3, 3, 3],

);
$tester->__test(\@expected, [0..3], 3);

# ----------------------------------------------------------------------

# n^k
my $ncomb = 0;
my $iter = variations_with_repetition([1..7], 5);
while (my $c = $iter->next) {
    ++$ncomb;
}
is($ncomb, 16807, "");

$ncomb = 0;
$iter = variations_with_repetition([1..4], 7);
while (my $c = $iter->next) {
    ++$ncomb;
}
is($ncomb, 16384, "");
