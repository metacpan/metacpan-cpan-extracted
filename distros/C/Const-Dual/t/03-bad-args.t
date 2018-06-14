#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 5;

use Const::Dual ();

ok(not(eval "use Const::Dual (1 => 2); 1"), "invalid constant name");
ok(not(eval "use Const::Dual [], (A => 2); 1"), "invalid storehash type (array)");
ok(not(eval "use Const::Dual \'a', (A => 2); 1"), "invalid storehash type (scalar)");
ok(not(eval "use Const::Dual (A => 2, B); 1"), "odd number of elements in import");
ok(not(eval "use Const::Dual (BEGIN => 2); 1"), "reserved word in constant name");
