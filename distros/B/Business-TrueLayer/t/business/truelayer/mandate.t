#!perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

use_ok( 'Business::TrueLayer::Mandate' );

my $Mandate = Business::TrueLayer::Mandate->new(
    # taken from https://docs.truelayer.com/docs/direct-debits
	{
		"mandate" => {
			"type" => "direct_debit",
			"remitter" => {
				"account_holder_name" => "Remy Turr",
				"account_identifier" => {
					"type" => "sort_code_account_number",
					"sort_code" => "010101",
					"account_number" => "12345678"
				},
				"address" => {
					"address_line1" => "1 Hardwick St",
					"city" => "London",
					"state" => "London",
					"zip" => "EC1R 4RB",
					"country_code" => "GB"
				},
			},
			"beneficiary" => {
				"type" => "merchant_account",
				"merchant_account_id" => "b8d4dda0-ff2c-4d77-a6da-4615e4bad941"
			},
		},
		"id" => "2d63c89b-4755-473c-ace1-12c099a903fe",
		"status" => "authorizing",
		"currency" => "GBP",
		"user" => {
			"name" => "Remy Turr",
			"email" => 'remy.turr@yahoo.co.uk'
		}
	}
);

isa_ok(
    $Mandate,
    'Business::TrueLayer::Mandate',
);

is( $Mandate->currency,'GBP','->currency' );
is( $Mandate->id,'2d63c89b-4755-473c-ace1-12c099a903fe','->id' );
is( $Mandate->status,'authorizing','->status' );

isa_ok( $Mandate->user,'Business::TrueLayer::User' );
isa_ok( $Mandate->beneficiary,'Business::TrueLayer::Beneficiary' );
isa_ok( $Mandate->remitter,'Business::TrueLayer::Remitter' );
isa_ok(
	$Mandate->remitter->account_identifier,
	'Business::TrueLayer::Account::Identifier',
);
isa_ok(
	$Mandate->remitter->address,
	'Business::TrueLayer::Address',
);

done_testing();
