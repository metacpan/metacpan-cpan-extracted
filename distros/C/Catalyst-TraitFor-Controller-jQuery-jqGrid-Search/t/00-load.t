#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Catalyst::TraitFor::Controller::jQuery::jqGrid::Search' ) || print "Bail out!\n";
}

diag( "Testing Catalyst::TraitFor::Controller::jQuery::jqGrid::Search $Catalyst::TraitFor::Controller::jQuery::jqGrid::Search::VERSION, Perl $], $^X" );
