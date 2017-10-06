#!perl

use strict;
use warnings;
use Test::More;

eval "use Clone::PP;";
$@ and plan skip_all => "No Clone::PP found. Can't prove load successfull with :Clone::PP.";

use_ok("Clone::Choose", qw(:Clone::PP)) || plan skip_all => "Couldn't use Clone::Choose qw(:Clone::PP).";

done_testing;
