#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Any::Renderer::Data::Printer' ) || print "Bail out!
";
}

diag( "Testing Any::Renderer::Data::Printer $Any::Renderer::Data::Printer::VERSION, Perl $], $^X" );
