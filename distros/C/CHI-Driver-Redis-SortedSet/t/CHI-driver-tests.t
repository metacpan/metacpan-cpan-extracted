#!perl -w
use strict;
use warnings;
use CHI::Driver::Redis::t::CHIDriverTests;

use Test::More;

# disable as tests would otherwise exceed imposed time limit
local $ENV{AUTHOR_TESTING} = 0;

CHI::Driver::Redis::t::CHIDriverTests->runtests;
