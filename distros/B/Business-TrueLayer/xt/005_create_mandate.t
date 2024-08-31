#!perl

use strict;
use warnings;

use FindBin qw/ $Bin /;
use lib $Bin;

use Test::Most;
use Test::Warnings;
use Test::Credentials;
use Business::TrueLayer;

plan skip_all => "set TRUELAYER_CREDENTIALS"
    if ! $ENV{TRUELAYER_CREDENTIALS};

my $TrueLayer = Business::TrueLayer->new(
    my $creds = Test::Credentials->new->TO_JSON,
);

# we're going to modify some of the value in the account
# data, hence having a hashref here that is then used
# in the base_data hash
my $account_data = {
	"type" => "sort_code_account_number",
	"sort_code" => "010101",
	"account_number" => "12345678"
};

my %base_data = (
	"mandate" => {
		"type" => "direct_debit",
		"remitter" => {
			"account_holder_name" => "Remy Turr",
			"account_identifier" => $account_data,
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
            "merchant_account_id" => "660ce241-9dfd-b67f-772e-79cca8995f8d",
		},
	},
	"currency" => "GBP",
	"user" => {
		"name" => "Remy Turr",
		"email" => 'remy.turr@yahoo.co.uk'
	}
);

subtest '->create_mandate' => sub {

	my $Mandate = $TrueLayer->create_mandate( \%base_data );

	isa_ok( $Mandate,'Business::TrueLayer::Mandate' );
	ok( $Mandate->id,'->id' );
	ok( $Mandate->status,'->status' );
	ok( $Mandate->user->id,'->user->id' );

	$Mandate = $TrueLayer->get_mandate( $Mandate->id );
	is( $Mandate->status,'authorizing','->get_mandate' );
	ok( $Mandate->authorizing,'->authorizing' );

	if ( $Mandate->authorized ) {
		my $Payment = $TrueLayer->create_payment_from_mandate(
			$Mandate,100
		);
		isa_ok( $Payment,'Business::TrueLayer::Payment' );
	}
};

TODO: subtest '500 error' => sub {

	local $TODO = 'awaiting sandbox implementation';

	# account ending in 2222 should return a 500 server error
	$account_data->{account_number} = '12342222';

	my $Mandate;

	throws_ok(
		sub { $Mandate = $TrueLayer->create_mandate( \%base_data ) },
		qr/unknown error/i,
	);

	note explain $Mandate;
	is( $Mandate,undef,'no mandate object created' );
};

done_testing();
