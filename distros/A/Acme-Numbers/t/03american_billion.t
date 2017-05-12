#!perl 

use strict;
use Test::More tests => 1;
use Acme::Numbers billion => 10**9;

is(one.billion."", 1_000_000_000, "Got American billion");
