#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Pwgen' ) || print "Bail out!
";
}

diag( "Testing Data::Pwgen $Data::Pwgen::VERSION, Perl $], $^X" );
