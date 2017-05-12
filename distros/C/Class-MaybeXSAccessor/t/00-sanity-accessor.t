#!perl

use 5.010001;
use strict;
use warnings;

use lib::disallow 'Class::XSAccessor';

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More 0.98;

use Local::C1;

my $c1 = Local::C1->new;
$c1->foo(1980);
$c1->bar(12);
is_deeply($c1, bless({foo=>1980, bar=>12}, "Local::C1"));

done_testing;
