#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::Formatter' );
}

diag( "Testing Dancer::Plugin::Formatter $Dancer::Plugin::Formatter::VERSION, Perl $], $^X" );
