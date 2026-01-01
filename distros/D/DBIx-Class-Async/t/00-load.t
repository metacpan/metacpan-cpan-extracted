#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN {
    use_ok('DBIx::Class::Async') || print "Bail out!\n";
}

diag( "Testing DBIx::Class::Async $DBIx::Class::Async::VERSION, Perl $], $^X" );
