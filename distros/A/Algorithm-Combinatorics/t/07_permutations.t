use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More qw(no_plan);

use Algorithm::Combinatorics qw(permutations);
use Tester;

my $tester = Tester->__new(\&permutations);

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
    ["bar", "foo"],
);
$tester->__test(\@expected, ["foo", "bar"]);

# ---------------------------------------------------------------------

@expected = (
    ["foo", "bar", "baz"],
    ["foo", "baz", "bar"],
    ["bar", "foo", "baz"],
    ["bar", "baz", "foo"],
    ["baz", "foo", "bar"],
    ["baz", "bar", "foo"],
);
$tester->__test(\@expected, ["foo", "bar", "baz"]);

# ----------------------------------------------------------------------

# n!
my $ncomb = 0;
my $iter = permutations([1..8]);
while (my $c = $iter->next) {
    ++$ncomb;
}
is($ncomb, 40320, "");
