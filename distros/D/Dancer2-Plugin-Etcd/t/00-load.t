#!perl

use Test::More tests => 1;

BEGIN {
    $ENV{PATH} = '/bin:/usr/bin';
    use_ok( 'Dancer2::Plugin::Etcd' ) || print "Bail out!
";
}

diag( "Testing Dancer2::Plugin::Etcd $Dancer2::Plugin::Etcd::VERSION, Perl $], $^X" );
