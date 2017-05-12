#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'App::aptperl' );
}

diag( "Testing App::aptperl $App::aptperl::VERSION, Perl $], $^X" );
done_testing();
