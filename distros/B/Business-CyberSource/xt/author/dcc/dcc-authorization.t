use strict;
use warnings;
use Test::More;
use Test::Requires::Env qw(
	PERL_BUSINESS_CYBERSOURCE_DCC_CC_MM
	PERL_BUSINESS_CYBERSOURCE_DCC_CC_YYYY
	PERL_BUSINESS_CYBERSOURCE_DCC_MASTERCARD
);
use FindBin;
use Module::Runtime qw( use_module    );
use Test::Requires  qw( Path::FindDev );
use lib Path::FindDev::find_dev( $FindBin::Bin )->child('t', 'lib' )->stringify;

my $t = new_ok( use_module('Test::Business::CyberSource') );

my $billto = $t->resolve( service => '/helper/bill_to');
my $card
	= $t->resolve(
		service => '/helper/card',
		parameters => {
			account_number => $ENV{PERL_BUSINESS_CYBERSOURCE_DCC_MASTERCARD},
			expiration     => {
				month => $ENV{PERL_BUSINESS_CYBERSOURCE_DCC_CC_MM},
				year  => $ENV{PERL_BUSINESS_CYBERSOURCE_DCC_CC_YYYY},
			},
		},
);

my $dcc_req
	= new_ok( use_module( 'Business::CyberSource::Request::DCC') => [{
		reference_code  => 'test-dcc-authorization-' . time,
		card            => $card,
		purchase_totals => {
			currency         => 'USD',
			total            => '1.00',
			foreign_currency => 'EUR',
		},
	}]);


my $client = $t->resolve( service => '/client/object' );

my $res = $client->submit( $dcc_req );

my $dcc = $res->dcc;
my $ptotals = $res->purchase_totals;

is $ptotals->foreign_currency, 'EUR', 'dcc response foreign_currency';
is $ptotals->foreign_amount,  '0.88', 'dcc response foreign_amount'  ;
is $ptotals->exchange_rate, '0.8810', 'dcc response exchange_rate'   ;
is $dcc->supported,                1, 'dcc response dcc_supported'   ;

my $authc = use_module('Business::CyberSource::Request::Authorization');

my $auth_req
	= new_ok( $authc => [{
		reference_code   => $res->reference_code,
		bill_to          => $billto,
		card             => $card,
		dcc_indicator    => 1,
		purchase_totals  => {
			total            => $dcc_req->purchase_totals->total,
			currency         => $res->purchase_totals->currency,
			foreign_currency => $res->purchase_totals->foreign_currency,
			foreign_amount   => $res->purchase_totals->foreign_amount,
			exchange_rate    => $res->purchase_totals->exchange_rate,
			exchange_rate_timestamp => $res->purchase_totals->exchange_rate_timestamp,
		},
	}]);

my $auth_res = $client->submit( $auth_req );

ok $auth_res->is_accept, 'card authorized'
	or diag $auth_res->reason_text;


my $cap_req
	= new_ok( use_module( 'Business::CyberSource::Request::Capture') => [{
		reference_code   => $auth_res->reference_code,
		purchase_totals  => $auth_req->purchase_totals,
		dcc_indicator    => 1,
		service          => {
			request_id => $auth_res->request_id,
		},
	}]);

my $cap_res = $client->submit( $cap_req );

my $cred_req
	= new_ok( use_module( 'Business::CyberSource::Request::FollowOnCredit') => [{
		bill_to          => $billto,
		card             => $card,
		reference_code   => $cap_res->reference_code,
		purchase_totals  => $auth_req->purchase_totals,
		dcc_indicator    => 1,
		service  => { request_id => $cap_res->request_id },
	}]);

my $cred_res = $client->submit( $cred_req );

is( $cred_res->is_accept, 1, 'check that credit decicion is ACCEPT')
	or diag $cred_res->reason_text;

is( $cred_res->credit->amount, '1.00', 'check that credit amount is 1.00' );

done_testing;
