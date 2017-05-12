#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Convert::Ascii85' ) || print "Bail out!
";
}

diag( "Testing Convert::Ascii85 $Convert::Ascii85::VERSION, Perl $], $^X" );
