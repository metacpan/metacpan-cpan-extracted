use strict;
use warnings;

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
$tester->__test(\@expected, []);

# ---------------------------------------------------------------------

@expected = ([["foo"]]);
$tester->__test(\@expected, ["foo"]);

# ---------------------------------------------------------------------

@expected = ([["foo", "bar"]], [["foo"], ["bar"]]);
$tester->__test(\@expected, ["foo", "bar"]);

# ---------------------------------------------------------------------

@expected = (
    [["foo", "bar", "baz"]],
    [["foo", "bar"], ["baz"]],
    [["foo", "baz"], ["bar"]],
    [["foo"], ["bar", "baz"]],
    [["foo"], ["bar"], ["baz"]],
);
$tester->__test(\@expected, ["foo", "bar", "baz"]);

# ---------------------------------------------------------------------

@expected = (
    [[qw(a b c d)]],
    [[qw(a b c)], ["d"]],
    [[qw(a b d)], ["c"]],
    [[qw(a b)], [qw(c d)]],
    [[qw(a b)], ["c"], ["d"]],
    [[qw(a c d)], ["b"]],
    [[qw(a c)], [qw(b d)]],
    [[qw(a c)], ["b"], ["d"]],
    [[qw(a d)], [qw(b c)]],
    [["a"], [qw(b c d)]],
    [["a"], [qw(b c)], ["d"]],
    [[qw(a d)], ["b"], ["c"]],
    [["a"], [qw(b d)], ["c"]],
    [["a"], ["b"], [qw(c d)]],
    [["a"], ["b"], ["c"], ["d"]],
);
$tester->__test(\@expected, [qw(a b c d)]);

# ---------------------------------------------------------------------

my $n = 0;
my $iter = partitions([1..9]);
while (my $p = $iter->next) {
    ++$n;
}
is($n, 21147, "");

$n = 0;
$iter = partitions([1..10]);
while (my $p = $iter->next) {
    ++$n;
}
is($n, 115975, "");
