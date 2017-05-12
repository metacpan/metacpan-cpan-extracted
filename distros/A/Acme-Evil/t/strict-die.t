#!/usr/bin/perl
use lib '.';
use Test::More tests => 4;

require_ok 't::t1::Evil';
require_ok 't::t1::Direct';
require_ok 't::t1::Indirect';
ok !eval { require t::t1::Unrelated }, 'Unrelated dies';
