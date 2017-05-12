#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Convert::Color::ScaleModels' ) || print "Bail out!\n";
}

diag( "Testing Convert::Color::ScaleModels $Convert::Color::ScaleModels::VERSION, Perl $], $^X" );
