#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Abilities' ) || print "Bail out!\n";
    use_ok( 'Abilities::Features' ) || print "Bail out!\n";
}

diag( "Testing Abilities $Abilities::VERSION, Perl $], $^X" );
diag( "Testing Abilities::Features $Abilities::Features::VERSION, Perl $], $^X" );
