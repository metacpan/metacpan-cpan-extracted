#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Template::TemplateSandbox' ) || print "Bail out!
";
}

diag( "Testing Dancer::Template::TemplateSandbox $Dancer::Template::TemplateSandbox::VERSION, Perl $], $^X" );
