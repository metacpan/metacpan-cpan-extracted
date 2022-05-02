#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More tests => 1;

BEGIN { use_ok('App::Timer') || print "Bail out!\n"; }
diag( "Testing App::Timer $App::Timer::VERSION, Perl $], $^X" );
