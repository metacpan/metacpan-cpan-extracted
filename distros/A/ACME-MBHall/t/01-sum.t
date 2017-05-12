#!perl -T
use strict;
use warnings;

use Test::More tests => 1;
use ACME::MBHall;

is(ACME::MBHall::sum(7,12),19,'sum works properly');
