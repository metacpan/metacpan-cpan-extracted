#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Config::FileManager' ) || print "Bail out!\n";
}

diag( "Testing Config::FileManager $Config::FileManager::VERSION, Perl $], $^X" );
