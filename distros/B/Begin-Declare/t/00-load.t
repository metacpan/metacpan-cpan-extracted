#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Begin::Declare' ) || print "Bail out!
";
}

diag( "Testing Begin::Declare $Begin::Declare::VERSION, Perl $], $^X" );
