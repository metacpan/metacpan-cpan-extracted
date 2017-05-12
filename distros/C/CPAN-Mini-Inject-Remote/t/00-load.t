#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CPAN::Mini::Inject::Remote' );
}

diag( "Testing CPAN::Mini::Inject::Remote $CPAN::Mini::Inject::Remote::VERSION, Perl $], $^X" );
