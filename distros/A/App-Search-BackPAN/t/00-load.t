#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN {
    use_ok('App::Search::BackPAN') || print "Bail out!\n";
}

diag( "Testing App::Search::BackPAN $App::Search::BackPAN::VERSION, Perl $], $^X" );
