#!perl -I./t

use strict;
use warnings;
use Test::More tests => 1;
use My_Test();

ok unlink $My_Test::File,'unlink';
