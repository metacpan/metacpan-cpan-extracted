#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok('App::diffdir');
}

diag( "Testing App::diffdir $App::diffdir::VERSION, Perl $], $^X" );
done_testing();
