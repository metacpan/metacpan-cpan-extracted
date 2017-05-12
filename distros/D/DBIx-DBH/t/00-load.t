#! /usr/bin/env perl

use Test::More tests => 1;

use_ok( 'DBIx::DBH' );
diag( "Testing DBIx::DBH $DBIx::DBH::VERSION, Perl $], $^X" );
