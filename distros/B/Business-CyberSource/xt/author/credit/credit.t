use strict;
use warnings;
use Test::More;
use FindBin;
use Module::Runtime qw( use_module    );
use Test::Requires  qw( Path::FindDev );
use lib Path::FindDev::find_dev( $FindBin::Bin )->child('t', 'lib' )->stringify;

my $t = use_module('Test::Business::CyberSource')->new;

my $client = $t->resolve( service => '/client/object' );

my $creditc = use_module('Business::CyberSource::Request::Credit');

my $req
	= new_ok( $creditc => [{
		reference_code => 'test-credit-' . time,
		bill_to =>
			$t->resolve( service => '/helper/bill_to' ),
		purchase_totals =>
			$t->resolve( service => '/helper/purchase_totals'),
		card =>
			$t->resolve( service => '/helper/card' ),
		ship_to =>
			$t->resolve( service => '/helper/ship_to' ),
        invoice_header =>
            $t->resolve( service => '/helper/invoice_header' ),
        other_tax =>
            $t->resolve( service => '/helper/other_tax' ),
        ship_from =>
            $t->resolve( service => '/helper/ship_from' ),
	}]);

isa_ok $req, $creditc;

my $ret = $client->submit( $req );

isa_ok $ret, 'Business::CyberSource::Response';

is( $ret->decision,               'ACCEPT', 'check decision'       );
is( $ret->reason_code,             100,     'check reason_code'    );
is( $ret->currency,               'USD',    'check currency'       );
is( $ret->credit->amount,         '3000.00', 'check amount'        );

ok( $ret->request_id,            'check request_id exists'    );
ok( $ret->credit->datetime,      'check datetime exists'      );


done_testing;
