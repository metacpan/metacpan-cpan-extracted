#!perl

use 5.010001;
use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More 0.98;

use Local::C1;
use Local::C2;

my $c1 = Local::C1->new;
$c1->baz([1]);

is_deeply($c1, bless([undef, undef, [1]], "Local::C1"))
    or diag explain $c1;

my $c2 = Local::C2->new;
$c2->foo(1);
$c2->bar("two");
$c2->baz([3]);
$c2->quux([10,11,12]);

is_deeply($c2, bless([1, "two", [3], undef, 10, 11, 12], "Local::C2"))
    or diag explain $c2;

done_testing;
