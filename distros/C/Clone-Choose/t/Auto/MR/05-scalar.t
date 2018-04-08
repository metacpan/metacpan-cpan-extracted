#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");

use Scalar::Util qw(refaddr);
use Test::More;

BEGIN
{
    $ENV{CLONE_CHOOSE_PREFERRED_BACKEND} and eval "use $ENV{CLONE_CHOOSE_PREFERRED_BACKEND}; 1;";
    $@ and plan skip_all => "No $ENV{CLONE_CHOOSE_PREFERRED_BACKEND} found.";
}

use Clone::Choose;

my $string = "Scalar";
$string = \$string;
my $cloned_string = clone $string;

ok(refaddr $string != refaddr $cloned_string, "Scalar String");

my $numeric = 3.141;
$numeric = \$numeric;
my $cloned_numeric = clone $numeric;

ok(refaddr $numeric != refaddr $cloned_numeric, "Scalar Numeric");

my $undef = undef;
$undef = \$undef;
my $cloned_undef = clone $undef;

ok(refaddr $undef != refaddr $cloned_undef, "Scalar Undef");

done_testing;


