#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    use_ok( 'App::MFILE' ) || print "Bail out!\n";
    use_ok( 'App::MFILE::HTTP' ) || print "Bail out!\n";
}

done_testing;

