#!perl -w
use strict;
use warnings;
use CHI::Driver::Redis::t::CHIDriverTests;

use Test::More;

CHI::Driver::Redis::t::CHIDriverTests->runtests;
