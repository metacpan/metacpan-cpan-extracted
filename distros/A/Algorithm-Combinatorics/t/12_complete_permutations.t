use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More qw(no_plan);

use Algorithm::Combinatorics qw(complete_permutations);
use Tester;

my $tester = Tester->__new(\&complete_permutations);

my (@result, @expected);

# ---------------------------------------------------------------------

eval { complete_permutations() };
ok($@, '');

eval { complete_permutations(0) };
ok($@, '');

# ---------------------------------------------------------------------

@expected = ([]);
$tester->__test(\@expected, []);

# ---------------------------------------------------------------------

@expected = ();
$tester->__test(\@expected, ["foo"]);

# ---------------------------------------------------------------------

@expected = (
    ["bar", "foo"],
);
$tester->__test(\@expected, ["foo", "bar"]);

# ---------------------------------------------------------------------

@expected = (
    ["bar", "baz", "foo"],
    ["baz", "foo", "bar"],
);
$tester->__test(\@expected, ["foo", "bar", "baz"]);

# ---------------------------------------------------------------------

@expected = (
    [2, 1, 4, 3],
    [2, 3, 4, 1],
    [2, 4, 1, 3],
    [3, 1, 4, 2],
    [3, 4, 1, 2],
    [3, 4, 2, 1],
    [4, 1, 2, 3],
    [4, 3, 1, 2],
    [4, 3, 2, 1],
);
$tester->__test(\@expected, [1, 2, 3, 4]);

# ----------------------------------------------------------------------

# d(n) = n*d(n-1) + (-1)**n if n > 0, d(0) = 1.
my $ncomb = 0;
my $iter = complete_permutations([1..8]);
while (my $c = $iter->next) {
    ++$ncomb;
}
is($ncomb, 14833, "");

$ncomb = 0;
$iter = complete_permutations([1..9]);
while (my $c = $iter->next) {
    ++$ncomb;
}
is($ncomb, 133496, "");