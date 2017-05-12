#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    use_ok( 'App::MFILE::WWW' ) || print "Bail out!\n";
}

done_testing;

