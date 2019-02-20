#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Convert::Base85' ) || print "Bail out!
";
}

diag( "Testing Convert::Base85 $Convert::Base85::VERSION, Perl $], $^X" );
