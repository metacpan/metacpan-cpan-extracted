#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bot::R9K' ) || print "Bail out!
";
}

diag( "Testing Bot::R9K $Bot::R9K::VERSION, Perl $], $^X" );
