#!/usr/bin/perl
use lib '.';
use Test::More tests => 1;

ok !eval { require t::t2::Dies }, 'Unrelated dies';
