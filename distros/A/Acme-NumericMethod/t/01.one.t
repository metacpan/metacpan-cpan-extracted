#!/usr/bin/perl
use strict;
use Test::More tests => 1;
use Acme::NumericMethod;

ok(one()==1, "One");
