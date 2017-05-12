#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'App::Devmode2' );
}

diag( "Testing App::Devmode2 $App::Devmode2::VERSION, Perl $], $^X" );
done_testing();
