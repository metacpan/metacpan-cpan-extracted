#!/usr/bin/env perl
use warnings;
use strict;

# Test that using the module doesn't break normal use of glob

use Test::More tests => 1;

package First;

use Acme::Globule qw( Range );

package Second;

use Acme::Globule qw( Range );

package main;

ok("We imported Acme::Globule::Range twice without error");

