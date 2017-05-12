use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More qw(no_plan);

use Algorithm::Combinatorics qw(tuples);
use Tester;

my $tester = Tester->__new(\&tuples);

my (@result, @expected);

# ---------------------------------------------------------------------

eval { tuples() };
ok($@, '');

eval { tuples([1]) };
ok($@, '');

eval { tuples(0, 0) };
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
    ["foo", "bar"],
    ["bar", "foo"],
);
$tester->__test(\@expected, ["foo", "bar"], 2);

# ---------------------------------------------------------------------

@expected = (
    ["foo", "bar"],
    ["foo", "baz"],
    ["bar", "foo"],
    ["bar", "baz"],
    ["baz", "foo"],
    ["baz", "bar"],
);
$tester->__test(\@expected, ["foo", "bar", "baz"], 2);

# ---------------------------------------------------------------------

@expected = (
    [0, 1, 2],
    [0, 1, 3],
    [0, 2, 1],
    [0, 2, 3],
    [0, 3, 1],
    [0, 3, 2],

    [1, 0, 2],
    [1, 0, 3],
    [1, 2, 0],
    [1, 2, 3],
    [1, 3, 0],
    [1, 3, 2],

    [2, 0, 1],
    [2, 0, 3],
    [2, 1, 0],
    [2, 1, 3],
    [2, 3, 0],
    [2, 3, 1],

    [3, 0, 1],
    [3, 0, 2],
    [3, 1, 0],
    [3, 1, 2],
    [3, 2, 0],
    [3, 2, 1],
);
$tester->__test(\@expected, [0..3], 3);

# ----------------------------------------------------------------------

# n*(n-1)*(n-2)* ... *(n-p+1)
my $ncomb = 0;
my $iter = tuples([1..9], 5);
while (my $c = $iter->next) {
    ++$ncomb;
}
is($ncomb, 15120, "");
