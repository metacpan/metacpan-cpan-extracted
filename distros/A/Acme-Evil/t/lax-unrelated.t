#!/usr/bin/perl
use lib '.';
use Test::More tests => 2;

require_ok 't::t3::Evil';
require_ok 't::t3::UnrelatedLax';
