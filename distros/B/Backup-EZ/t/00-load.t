#!/usr/bin/env perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Backup::EZ' ) || print "Bail out!\n";
}

diag( "Testing Backup::EZ $Backup::EZ::VERSION, Perl $], $^X" );
