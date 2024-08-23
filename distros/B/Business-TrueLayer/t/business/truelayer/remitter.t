#!perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

use_ok( 'Business::TrueLayer::Remitter' );

my $Remitter = Business::TrueLayer::Remitter->new(
	{
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
	}
);

isa_ok( $Remitter,'Business::TrueLayer::Remitter' );
isa_ok( $Remitter->account_identifier,'Business::TrueLayer::Account::Identifier' );
isa_ok( $Remitter->address,'Business::TrueLayer::Address' );

is(
	$Remitter->account_holder_name,
	'Remy Turr',
	'->account_holder_name'
);

done_testing();
