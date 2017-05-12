use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More qw(no_plan);

use Algorithm::Combinatorics qw(derangements);
use Tester;

my $tester = Tester->__new(\&derangements);

my (@result, @expected);

# ---------------------------------------------------------------------

eval { derangements() };
ok($@, '');

eval { derangements(0) };
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
my $iter = derangements([1..8]);
while (my $c = $iter->next) {
    ++$ncomb;
}
is($ncomb, 14833, "");

$ncomb = 0;
$iter = derangements([1..9]);
while (my $c = $iter->next) {
    ++$ncomb;
}
is($ncomb, 133496, "");