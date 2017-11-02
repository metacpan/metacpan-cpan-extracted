use Scalar::Util qw(refaddr);
use Test::More;

BEGIN
{
    $ENV{CLONE_CHOOSE_PREFERRED_BACKEND} and eval "use $ENV{CLONE_CHOOSE_PREFERRED_BACKEND}; 1;";
    $@ and plan skip_all => "No $ENV{CLONE_CHOOSE_PREFERRED_BACKEND} found.";
}

use Clone::Choose;

my $array = [1, ["two", [3, ["four"],],],];
my $cloned_array = clone $array;

ok(refaddr $array != refaddr $cloned_array,                         "Clone depth 0");
ok(refaddr($array->[1]) != refaddr($cloned_array->[1]),             "Clone depth 1");
ok(refaddr($array->[1][1]) != refaddr($cloned_array->[1][1]),       "Clone depth 2");
ok(refaddr($array->[1][1][1]) != refaddr($cloned_array->[1][1][1]), "Clone depth 3");

ok($array->[0] == $cloned_array->[0],                   "Array value depth 0");
ok($array->[1][0] eq $cloned_array->[1][0],             "Array value depth 1");
ok($array->[1][1][0] == $cloned_array->[1][1][0],       "Array value depth 2");
ok($array->[1][1][1][0] eq $cloned_array->[1][1][1][0], "Array value depth 3");

ok($cloned_array->[0] == 1,               "Array value sanity depth 0");
ok($cloned_array->[1][0] eq "two",        "Array value sanity depth 1");
ok($cloned_array->[1][1][0] == 3,         "Array value sanity depth 2");
ok($cloned_array->[1][1][1][0] eq "four", "Array value sanity depth 3");

my $empty_array        = [];
my $cloned_empty_array = clone $empty_array;

ok(refaddr $empty_array != refaddr $cloned_empty_array, "Empty array clone");

done_testing;
