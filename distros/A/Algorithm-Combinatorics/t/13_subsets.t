use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More qw(no_plan);

use Algorithm::Combinatorics qw(subsets);
use Tester;

my $tester = Tester->__new(\&subsets);

my (@result, @expected);

# ---------------------------------------------------------------------

eval { subsets() };
ok($@, '');

eval { subsets(1) };
ok($@, '');

# ---------------------------------------------------------------------

@expected = ([]);
$tester->__test(\@expected, []);

@expected = ([1, 2], [2], [1], []);
$tester->__test(\@expected, [1, 2]);

# ---------------------------------------------------------------------

@expected = (
    ["foo", "bar", "baz"],
    ["bar", "baz"], 
    ["foo", "baz"],
    ["baz"],
    ["foo", "bar"],
    ["bar"],
    ["foo"],
    [],
);
$tester->__test(\@expected, ["foo", "bar", "baz"]);

# ---------------------------------------------------------------------

@expected = (
    [1, 2, 3, 4],
    [2, 3, 4],
    [1, 3, 4],
    [3, 4],
    [1, 2, 4],
    [2, 4],
    [1, 4],
    [4],
    [1, 2, 3],
    [2, 3],
    [1, 3],
    [3],
    [1, 2],
    [2],
    [1],
    []
);
$tester->__test(\@expected, [1..4]);

# ----------------------------------------------------------------------

my $nsubsets = 0;
my $iter = subsets([1..16]);
while (my $c = $iter->next) {
    ++$nsubsets;
}
is($nsubsets, 65536, "");

