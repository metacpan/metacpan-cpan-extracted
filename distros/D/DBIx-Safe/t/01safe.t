#!/usr/bin/perl -- -*-cperl-*-

use strict;
use warnings;
use Test::More  tests => 1;
use Data::Dumper;

eval { require DBIx::Safe; };
$@ and BAIL_OUT qq{Could not load the DBIx::Safe module: $@};
pass("DBIx::Safe module loaded");

