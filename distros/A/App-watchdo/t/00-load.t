#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'App::watchdo' );
}

diag( "Testing App::watchdo $App::watchdo::VERSION, Perl $], $^X" );
done_testing();
