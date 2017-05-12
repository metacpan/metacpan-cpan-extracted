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
#is_deeply($c1, bless([undef, undef], "Local::C1"));

$c1->foo(1980);
$c1->bar(12);
is_deeply($c1, bless([1980, 12], "Local::C1"));

my $c2 = Local::C2->spawn;

$c2->foo(1981);
$c2->bar(11);
is_deeply($c2, bless([1981, 11], "Local::C2"));

done_testing;
