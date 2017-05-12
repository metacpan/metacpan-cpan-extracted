use Test::More tests => 1;
use lib qw{lib};

BEGIN {
use_ok( 'Business::CCProcessor' );
# use_ok( 'Business::CCProcessor::PayPal' );
# use_ok( 'Business::CCProcessor::Verisign' );
# use_ok( 'Business::CCProcessor::DiA' );
}

diag( "Testing Business::CCProcessor $Business::CCProcessor::VERSION" );
