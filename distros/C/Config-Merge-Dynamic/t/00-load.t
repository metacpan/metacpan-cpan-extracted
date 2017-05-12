#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Config::Merge::Dynamic' ) || print "Bail out!\n";
}

diag( "Testing Config::Merge::Dynamic $Config::Merge::Dynamic::VERSION, Perl $], $^X" );
