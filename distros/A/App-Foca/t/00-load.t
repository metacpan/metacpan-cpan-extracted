#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::Foca::Server' ) || print "Bail out!
";
}

diag( "Testing App::Foca::Server $App::Foca::Server::VERSION, Perl $], $^X" );
