#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'App::used' );
}

diag( "Testing App::used $App::used::VERSION, Perl $], $^X" );
done_testing();
