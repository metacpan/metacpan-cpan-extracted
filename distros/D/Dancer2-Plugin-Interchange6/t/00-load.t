#!perl

use Test::More tests => 1;

BEGIN {
    $ENV{PATH} = '/bin:/usr/bin';
    use_ok( 'Dancer2::Plugin::Interchange6' ) || print "Bail out!
";
}

diag( "Testing Dancer2::Plugin::Interchange6 $Dancer2::Plugin::Interchange6::VERSION, Perl $], $^X" );
