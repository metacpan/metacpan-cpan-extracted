#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'App::filewatch' );
}

diag( "Testing App::filewatch $App::filewatch::VERSION, Perl $], $^X" );
done_testing();
