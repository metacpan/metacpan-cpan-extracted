#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'CPAN::Mini::Inject::Server' );
    use_ok( 'CPAN::Mini::Inject::Server::Dispatch' );
}

diag( "Testing CPAN::Mini::Inject::Server $CPAN::Mini::Inject::Server::VERSION, Perl $], $^X" );
