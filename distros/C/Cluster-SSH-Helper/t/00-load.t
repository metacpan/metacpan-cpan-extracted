#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Cluster::SSH::Helper' ) || print "Bail out!\n";
}

diag( "Testing Cluster::SSH::Helper $Cluster::SSH::Helper::VERSION, Perl $], $^X" );
