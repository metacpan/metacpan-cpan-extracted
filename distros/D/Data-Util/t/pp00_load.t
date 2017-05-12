#!perl -wT

use Test::More tests => 2;

BEGIN {
	$Data::Util::TESTING_PERL_ONLY = 1;
	use_ok( 'Data::Util' );
}

my $backend = $Data::Util::TESTING_PERL_ONLY ? 'PurePerl' : 'XS';

is $backend, 'PurePerl';
