#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::PGMultiDeploy' ) || print "Bail out!\n";
}

diag( "Testing App::PGMultiDeploy $App::PGMultiDeploy::VERSION, Perl $], $^X" );
