use strict;

use FindBin qw($Bin);
use lib $Bin;

use Test::More qw(no_plan);

use Algorithm::Combinatorics qw(partitions);
use Tester;

my $tester = Tester->__new(\&partitions);

my (@result, @expected);

# ---------------------------------------------------------------------

eval { partitions() };
ok($@, '');

eval { partitions(0) };
ok($@, '');

# ---------------------------------------------------------------------

@expected = ([]);
$tester->__test(\@expected, [], 0);

# ---------------------------------------------------------------------

@expected = ();
$tester->__test(\@expected, [1, 2], 0);

# ---------------------------------------------------------------------

@expected = ([["foo"]]);
$tester->__test(\@expected, ["foo"], 1);

# ---------------------------------------------------------------------

@expected = ([["foo"], ["bar"]]);
$tester->__test(\@expected, ["foo", "bar"], 2);

# ---------------------------------------------------------------------

@expected = (
    [["foo"], ["bar"], ["baz"]],
);
$tester->__test(\@expected, ["foo", "bar", "baz"], 3);

# ---------------------------------------------------------------------

@expected = (
    [["a", "b"], ["c"], ["d"]],
    [["a", "c"], ["b"], ["d"]],
    [["a"], ["b", "c"], ["d"]],
    [["a", "d"], ["b"], ["c"]],
    [["a"], ["b", "d"], ["c"]],
    [["a"], ["b"], ["c", "d"]],
);
$tester->__test(\@expected, [qw(a b c d)], 3);

# ---------------------------------------------------------------------

my $n = 0;
my $iter = partitions([1..10], 4);
while (my $p = $iter->next) {
    ++$n;
}
is($n, 34105, "");

$n = 0;
$iter = partitions([1..11], 4);
while (my $p = $iter->next) {
    ++$n;
}
is($n, 145750, "");