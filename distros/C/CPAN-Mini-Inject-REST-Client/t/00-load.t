#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CPAN::Mini::Inject::REST::Client' ) || print "Bail out!\n";
}

diag( "Testing CPAN::Mini::Inject::REST::Client $CPAN::Mini::Inject::REST::Client::VERSION, Perl $], $^X" );
