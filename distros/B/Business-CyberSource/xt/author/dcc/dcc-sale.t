#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Requires::Env qw(
	PERL_BUSINESS_CYBERSOURCE_DCC_CC_MM
	PERL_BUSINESS_CYBERSOURCE_DCC_CC_YYYY
	PERL_BUSINESS_CYBERSOURCE_DCC_VISA
);
use FindBin;
use Module::Runtime qw( use_module    );
use Test::Requires  qw( Path::FindDev );
use lib Path::FindDev::find_dev( $FindBin::Bin )->child('t', 'lib' )->stringify;

my $t = new_ok( use_module('Test::Business::CyberSource') );

my $card = $t->resolve(
		service => '/helper/card',
		parameters => {
			account_number => $ENV{PERL_BUSINESS_CYBERSOURCE_DCC_VISA},
			expiration     => {
				month => $ENV{PERL_BUSINESS_CYBERSOURCE_DCC_CC_MM},
				year  => $ENV{PERL_BUSINESS_CYBERSOURCE_DCC_CC_YYYY},
			},
		},
);

my $dcc_req
	= new_ok( use_module( 'Business::CyberSource::Request::DCC') => [{
		reference_code   => 'test-dcc-authorization-' . time,
		card             => $card,
		purchase_totals => {
			currency         => 'USD',
			total            => '1.00',
			foreign_currency => 'JPY',
		},
	}]);

my $client = $t->resolve( service => '/client/object' );

my $dcc = $client->submit( $dcc_req );

is( $dcc->purchase_totals->foreign_currency, 'JPY', 'check foreign currency' );
is( $dcc->purchase_totals->foreign_amount, 116, 'check foreign amount' );
is( $dcc->purchase_totals->currency, 'USD', 'check currency' );
is( $dcc->dcc->supported, 1, 'check dcc supported' );
is( $dcc->purchase_totals->exchange_rate, 116.4344, 'check exchange rate' );
is( $dcc->purchase_totals->exchange_rate_timestamp, '20090101 00:00', 'check exchange timestamp' );

my $sale_req
	= new_ok( use_module( 'Business::CyberSource::Request::Sale') => [{
		reference_code   => $dcc->reference_code,
		bill_to          => $t->resolve( service => '/helper/bill_to' ),
		card             => $card,
		purchase_totals => {
			total            => $dcc_req->purchase_totals->total,
			currency         => $dcc->purchase_totals->currency,
			foreign_currency => $dcc->purchase_totals->foreign_currency,
			foreign_amount   => $dcc->purchase_totals->foreign_amount,
			exchange_rate    => $dcc->purchase_totals->exchange_rate,
			exchange_rate_timestamp => $dcc->purchase_totals->exchange_rate_timestamp,
		},
		dcc_indicator    => 1,
		}]);

my $sale_res = $client->submit( $sale_req );

ok( $sale_res->is_accept, 'sale accepted' )
	or diag $sale_res->reason_text;

done_testing;
