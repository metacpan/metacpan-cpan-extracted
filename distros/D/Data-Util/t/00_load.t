#!perl -wT

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::Util' );
}

my $backend = $Data::Util::TESTING_PERL_ONLY ? 'PurePerl' : 'XS';
diag( "Testing Data::Util $Data::Util::VERSION ($backend)" );
