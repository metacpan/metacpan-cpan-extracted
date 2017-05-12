#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::Rad::Plugin::ValuePriority' );
}

diag( "Testing App::Rad::Plugin::ValuePriority $App::Rad::Plugin::ValuePriority::VERSION, Perl $], $^X" );
