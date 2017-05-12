#!/usr/bin/perl
use lib '.';
use Test::More tests => 1;

ok !eval {require t::t3::IntermediateDirect }, 'Direct intermediate dies';
