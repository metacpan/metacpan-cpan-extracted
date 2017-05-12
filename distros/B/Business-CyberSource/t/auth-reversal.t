use strict;
use warnings;
use Test::More;
use Test::Method;

use Module::Runtime qw( use_module );

my $authrevc = use_module('Business::CyberSource::Request::AuthReversal');

my $dto
	= new_ok( $authrevc => [{
		reference_code => 'notarealcode',
		service => {
			request_id => 'notarealid',
		},
		purchase_totals => {
			total    => '3000.00',
			currency => 'USD',
		},
	}]);

can_ok $dto, 'serialize';

my %expected = (
	merchantReferenceCode => 'notarealcode',
	ccAuthReversalService => {
		run           => 'true',
		authRequestID => 'notarealid',
	},
	purchaseTotals => {
		grandTotalAmount => '3000.00',
		currency         => 'USD',
	},
);

method_ok $dto, serialize => [], \%expected;

done_testing;
