use strict;
use warnings;

use Test::More tests => 4;
use Acme::Currency;

my €test = 1;
ok(€test == 1);

my @ary = 1..10;
ok(€ary[2] == 3);

no Acme::Currency;
  
ok($test == 1);

use Acme::Currency '¥';
  
my ¥scalar = '¥test';

no Acme::Currency;

ok($scalar eq '¥test');

