#!perl -T

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Astro::Utils') || print "Bail out!\n"; }

diag( "Testing Astro::Utils $Astro::Utils::VERSION, Perl $], $^X" );
