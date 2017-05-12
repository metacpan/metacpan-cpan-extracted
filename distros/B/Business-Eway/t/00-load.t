#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Business::Eway' );
}

diag( "Testing Business::Eway $Business::Eway::VERSION, Perl $], $^X" );

1;