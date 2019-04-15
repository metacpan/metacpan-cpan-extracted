#!perl -T
use 5.016;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'App::WatchLater' ) || print "Bail out!\n";
    use_ok( 'App::WatchLater::Browser' ) || print "Bail out!\n";
    use_ok( 'App::WatchLater::YouTube' ) || print "Bail out!\n";
}

diag( "Testing App::WatchLater $App::WatchLater::VERSION, Perl $], $^X" );
