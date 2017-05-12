#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;

use_ok('Acme::24');

my $fact = Acme::24->random_jackbauer_fact();

ok(defined $fact && $fact ne '', 'Random Jack Bauer fact: ' . $fact);

