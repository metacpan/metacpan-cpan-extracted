use strict;
use warnings;
use Test::More;
use Module::Runtime qw( use_module );

my $res
	= new_ok( use_module('Business::CyberSource::Response') => [{
		decision              => 'ACCEPT',
		reasonCode            => '100',
		requestID             => '3497847984891076056428',
		merchantReferenceCode => 'test-1349678423',
		purchaseTotals        => {
			'currency' => 'USD'
		},
		requestToken => 'Ahj/7omgletsmakesurethisissecurebychangingitsguts'
			. '/Imnotgivingyouarealcode/Icanthearyouu2AAAA/QAO',
		ccAuthReply => {
			processorResponse  => '00',
			authorizedDateTime => '2012-10-08T06:40:27Z',
			reasonCode         => '100',
			authorizationCode  => '831000',
			amount             => '3000.00',
			avsCodeRaw         => 'Y',
			avsCode            => 'Y',
			reconciliationID   => 'YY7YW81HRK4P',
			authRecord => '0110322000000E10003840979308471907091389487900270'
				. '728165933335487401834987091873407037490173409710734104400'
				. '18349839749037947073094710974070173405303730333830323'
				. '03934734070970137490713904709',
		},
	}]);

ok ! $res->can('serialize'), 'can not serialize';

done_testing;
