#!/usr/bin/env perl
use warnings;
use strict;

# Test that using the module doesn't break normal use of glob

use Test::More tests => 1;

eval "use Acme::Globule qw( Invalid::Globule::Plugin )";

like($@, qr~Can't locate Acme/Globule/Invalid/Globule/Plugin.pm~,
     "die()s when given an invalid plugin");

