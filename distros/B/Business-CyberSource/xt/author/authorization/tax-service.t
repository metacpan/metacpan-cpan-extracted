use strict;
use warnings;
use Test::More;

use FindBin;
use Module::Runtime qw( use_module    );
use Test::Requires  qw( Path::FindDev );
use lib Path::FindDev::find_dev( $FindBin::Bin )->child('t', 'lib' )->stringify;

my $t = use_module('Test::Business::CyberSource')->new;

my $client = $t->resolve( service => '/client/object'    );

my $authc = use_module('Business::CyberSource::Request::Authorization');
my $ptc   = use_module('Business::CyberSource::RequestPart::PurchaseTotals');

my $req
	= new_ok( $authc => [{
		reference_code  => $t->resolve( service => '/request/reference_code' ),
		bill_to         => $t->resolve( service => '/helper/bill_to' ),
		card            => $t->resolve( service => '/helper/card' ),
		purchase_totals => new_ok( $ptc => [{ currency => 'USD' }]),
		tax_service     => {
			nexus => [ 'TX', 'FL' ],
		},
	}]);

my @items = (
	{
		unit_price => '10.0',
	},
);

foreach my $item ( @items ) {
	$req->add_item( $item );
}

my $ret = $client->submit( $req );

isa_ok $ret, 'Business::CyberSource::Response';

is( $ret->decision,             'ACCEPT', 'check decision'       );
is( $ret->reason_code,           100,     'check reason_code'    );
is( $ret->currency,             'USD',    'check currency'       );
is( $ret->auth->amount,         '10.03',    'check amount'     );
is( $ret->auth->avs_code,       'Y',       'check avs_code'      );
is( $ret->auth->avs_code_raw,   'Y',       'check avs_code_raw'  );
is( $ret->auth->processor_response, '00',  'check processor_response');
is( $ret->reason_text, 'Successful transaction', 'check reason_text' );
is( $ret->auth->auth_code, '831000',     'check auth_code exists');

ok( $ret->request_id,          'check request_id exists'    );
ok( $ret->request_token,       'check request_token exists' );
ok( $ret->auth->datetime,      'check datetime exists'      );
ok( $ret->auth->auth_record,   'check auth_record exists'   );

done_testing;
