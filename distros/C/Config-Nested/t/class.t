#!perl

# Test the common fuction. Anthony Fletcher

use 5;
use warnings;
use strict;

use Test::More tests => 4;

# Tests
BEGIN { use_ok('Config::Nested'); }

my $c;

ok($c = new Config::Nested(), "constructor");

ok($c->initialise(), "init");

ok($c->configure(
        section => [qw( home work)],
	boolean => [qw( happy hungry alive)],
	variable => [qw( name flavour colour ) ],
	array => 'breed exercise owner',
), "configure");


