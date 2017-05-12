use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More qw(no_plan);

use Algorithm::Combinatorics qw(circular_permutations);
use Tester;

my $tester = Tester->__new(\&circular_permutations);

my (@result, @expected);

# ---------------------------------------------------------------------

eval { permutations() };
ok($@, '');

eval { permutations(0) };
ok($@, '');

# ---------------------------------------------------------------------

@expected = ([]);
$tester->__test(\@expected, []);

# ---------------------------------------------------------------------

@expected = (["foo"]);
$tester->__test(\@expected, ["foo"]);

# ---------------------------------------------------------------------

@expected = (
    ["foo", "bar"],
);
$tester->__test(\@expected, ["foo", "bar"]);

# ---------------------------------------------------------------------

@expected = (
    ["foo", "bar", "baz"],
    ["foo", "baz", "bar"],
);
$tester->__test(\@expected, ["foo", "bar", "baz"]);

# ---------------------------------------------------------------------

@expected = (
    [1, 2, 3, 4],
    [1, 2, 4, 3],
    [1, 3, 2, 4],
    [1, 3, 4, 2],
    [1, 4, 2, 3],
    [1, 4, 3, 2],
);
$tester->__test(\@expected, [1, 2, 3, 4]);

# ----------------------------------------------------------------------

# (n-1)!
my $ncomb = 0;
my $iter = circular_permutations([1..9]);
while (my $c = $iter->next) {
    ++$ncomb;
}
is($ncomb, 40320, "");
