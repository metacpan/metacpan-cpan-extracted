#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Crypt::Unsnoopable' ) || print "Bail out!
";
}

diag( "Testing Crypt::Unsnoopable $Crypt::Unsnoopable::VERSION, Perl $], $^X" );
