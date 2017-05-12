#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::Prove::Plugin::Idempotent' ) || print "Bail out!\n";
}

diag( "Testing App::Prove::Plugin::Idempotent $App::Prove::Plugin::Idempotent::VERSION, Perl $], $^X" );
