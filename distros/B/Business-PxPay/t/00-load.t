#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Business::PxPay' );
}

diag( "Testing Business::PxPay $Business::PxPay::VERSION, Perl $], $^X" );

1;