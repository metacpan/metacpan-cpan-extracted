#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 1;

BEGIN { use_ok('App::genstopwords') || print "Bail out!\n"; }
diag( "Testing App::genstopwords $App::genstopwords::VERSION, Perl $], $^X" );

done_testing;
