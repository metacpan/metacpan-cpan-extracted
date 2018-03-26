#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 5;

BEGIN {
    use_ok( 'App::Netsync' ) || print "Bail out!\n";
    use_ok( 'App::Netsync::Network' ) || print "Bail out!\n";
    use_ok( 'App::Netsync::SNMP' ) || print "Bail out!\n";
    use_ok( 'App::Netsync::Configurator' ) || print "Bail out!\n";
    use_ok( 'App::Netsync::Scribe' ) || print "Bail out!\n";
}

diag( "Testing App::Netsync $App::Netsync::VERSION, Perl $], $^X" );
