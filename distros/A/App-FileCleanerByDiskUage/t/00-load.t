#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::FileCleanerByDiskUage' ) || print "Bail out!\n";
}

diag( "Testing App::FileCleanerByDiskUage $App::FileCleanerByDiskUage::VERSION, Perl $], $^X" );
