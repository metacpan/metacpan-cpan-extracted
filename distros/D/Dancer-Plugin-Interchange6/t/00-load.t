#!perl

use Test::More tests => 1;

BEGIN {
    $ENV{PATH} = '/bin:/usr/bin';
    use_ok( 'Dancer::Plugin::Interchange6' ) || print "Bail out!
";
}

diag( "Testing Dancer::Plugin::Interchange6 $Dancer::Plugin::Interchange6::VERSION, Perl $], $^X" );
