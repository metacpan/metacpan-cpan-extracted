#!perl

use Test::More tests => 1;

BEGIN {
    $ENV{PATH} = '/bin:/usr/bin';
    use_ok( 'Dancer::Plugin::Nitesi' ) || print "Bail out!
";
}

diag( "Testing Dancer::Plugin::Nitesi $Dancer::Plugin::Nitesi::VERSION, Perl $], $^X" );
