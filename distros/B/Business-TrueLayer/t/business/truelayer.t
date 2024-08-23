#!perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

use_ok( 'Business::TrueLayer' );
isa_ok(
    my $TrueLayer = Business::TrueLayer->new(
        client_id => 'TL-CLIENT-ID',
        client_secret => 'super-secret-client-secret',
        host => '/dev/null',
        payment_host => '/dev/random',
    ),
    'Business::TrueLayer'
);

isa_ok(
    $TrueLayer->authenticator,
    'Business::TrueLayer::Authenticator'
);

subtest '->merchant_accounts' => sub {

    no warnings qw/ once redefine /;
    local *Business::TrueLayer::Request::api_get = sub {
        return {
            items => [ {
                'id' => '5b7adbf4-f289-48a7-b451-bc236443397c',
                'available_balance_in_minor' => 90000,
                'currency' => 'GBP',
                'current_balance_in_minor' => 100000,
                'account_holder_name' => 'btdt',
                'account_identifiers' => [
                    {
                        'account_number' => '00033171',
                        'sort_code' => '040668',
                        'type' => 'sort_code_account_number'
                    },
                    {
                        'iban' => 'GB05CLRB04066800033171',
                        'type' => 'iban'
                    },
                ],
            }
        ] };
    };

    isa_ok(
        ( $TrueLayer->merchant_accounts )[0],
        'Business::TrueLayer::MerchantAccount',
    );
};

subtest '->create_payment' => sub {

    no warnings qw/ once redefine /;
    local *Business::TrueLayer::Request::api_post = sub {
        return {
            "id" => "SOMEID",
            "user" => {
                "id" => "ABABAB-CDCDCD-EFEFEF-GHGHGH"
            },
            "resource_token" => "a-secret-token",
            "status" => "authorization_required"
        };
    };

    my $args = _payment_args();

    isa_ok(
        my $Payment = $TrueLayer->create_payment( $args ),
        'Business::TrueLayer::Payment',
    );

    is( $Payment->id,'SOMEID','payment->id' );
    is( $Payment->status,'authorization_required','payment->status' );
    is( $Payment->resource_token,'a-secret-token','payment->resource_token' );
    is( $Payment->user->id,'ABABAB-CDCDCD-EFEFEF-GHGHGH','payment->user->id' );
    is( $Payment->host,'/dev/null','->host passed to Payment object' );
    is( $Payment->payment_host,'/dev/random','->payment_host passed to Payment object' );
};

subtest '->get_payment' => sub {

    no warnings qw/ once redefine /;
    *Business::TrueLayer::Request::api_get = sub {
        return _payment_args();
    };

    isa_ok(
        my $Payment = $TrueLayer->get_payment( 'SOMEID' ),
        'Business::TrueLayer::Payment',
    );

    is( $Payment->id,'SOMEID','payment->id' );
    is( $Payment->status,'authorization_required','payment->status' );
    is( $Payment->resource_token,'a-secret-token','payment->resource_token' );
    is( $Payment->user->id,'ABABAB-CDCDCD-EFEFEF-GHGHGH','payment->user->id' );
    is( $Payment->host,'/dev/null','->host passed to Payment object' );
    is( $Payment->payment_host,'/dev/random','->payment_host passed to Payment object' );
};

# taken from https://docs.truelayer.com/docs/create-a-payment
sub _payment_args {
    return {
        "id" => "SOMEID",
        "currency"       => "GBP",
        "payment_method" => {
            "type"               => "bank_transfer",
            "provider_selection" => {
                "type"   => "user_selected",
                "filter" => {
                    "countries"         => ["DE"],
                    "release_channel"   => "general_availability",
                    "customer_segments" => ["retail"]
                },
                "scheme_selection" => {
                    "type"               => "instant_only",
                    "allow_remitter_fee" => 0,
                }
            },
            "beneficiary" => {
                "type"                => "merchant_account",
                "verification"        => { "type" => "automated" },
                "merchant_account_id" => "AB8FA060-3F1B-4AE8-9692-4AA3131020D0",
                "account_holder_name" => "Ben Eficiary",
                "reference"           => "payment-ref"
            }
        },
        "user" => {
            "id"            => "ABABAB-CDCDCD-EFEFEF-GHGHGH",
            "name"          => "Remi Terr",
            "email"         => 'remi.terr@aol.com',
            "phone"         => "+447777777777",
            "date_of_birth" => "1990-01-31"
        },
        "amount_in_minor" => 1,
        "resource_token" => "a-secret-token",
        "status" => "authorization_required"
    };
}

subtest '->test_signature' => sub {

    # "no content"
    no warnings qw/ once redefine /;
    local *Business::TrueLayer::Request::api_post = sub {
        return;
    };

    ok( $TrueLayer->test_signature,'->test_signature' );
};

subtest '->create_mandate' => sub {

    no warnings qw/ once redefine /;
    local *Business::TrueLayer::Request::api_post = sub {
		return {
			"id" => "be6db706-68f1-4e9c-ab09-b83d8e3ea60d",
			"user" => {
				"id" => "b8d4dda0-ff2c-4d77-a6da-4615e4bad941"
			},
			"status" => "authorization_required",
			"resource_token" => "string"
		};
    };

    my $args = _mandate_args();

    isa_ok(
        my $Payment = $TrueLayer->create_mandate( $args ),
        'Business::TrueLayer::Mandate',
    );

};

subtest '->get_mandate' => sub {

    no warnings qw/ once redefine /;
    *Business::TrueLayer::Request::api_get = sub {
		my $mandate = _mandate_args();
        return {
			delete( $mandate->{mandate} )->%*,
			$mandate->%*,
            "resource_token" => "a-secret-token",
		};
    };

    isa_ok(
        my $Mandate = $TrueLayer->get_mandate( 'SOMEID' ),
        'Business::TrueLayer::Mandate',
    );

    is( $Mandate->id,'SOMEID','mandate->id' );
    is( $Mandate->status,'authorization_required','mandate->status' );
    is( $Mandate->user->id,'ABABAB-CDCDCD-EFEFEF-GHGHGH','mandate->user->id' );
    is( $Mandate->host,'/dev/null','->host passed to Mandate object' );
    is( $Mandate->payment_host,'/dev/random','->payment_host passed to Mandate object' );

	subtest '->create_payment_from_mandate' => sub {

		local *Business::TrueLayer::Request::api_post = sub {
			return {
				"id" => "be6db706-68f1-4e9c-ab09-b83d8e3ea60d",
				"user" => {
					"id" => "b8d4dda0-ff2c-4d77-a6da-4615e4bad941"
				},
				"status" => "authorized",
			};
		};

		isa_ok(
			my $Payment = $TrueLayer->create_payment_from_mandate( $Mandate,100 ),
			'Business::TrueLayer::Payment',
			'->create_payment_from_mandate'
		);

		ok( $Payment->authorized,'->authorized' );
	};
};

# taken from https://docs.truelayer.com/docs/create-mandate
sub _mandate_args {
    return {
        "mandate" => {
            "type"     => "direct_debit",
            "remitter" => {
                "account_holder_name" => "Remy Turr",
                "account_identifier"  => {
                    "type"           => "sort_code_account_number",
                    "sort_code"      => "010101",
                    "account_number" => "12345678"
                },
                "address" => {
                    "address_line1" => "1 Hardwick St",
                    "city"          => "London",
                    "state"         => "London",
                    "zip"           => "EC1R 4RB",
                    "country_code"  => "GB"
                },
            },
            "beneficiary" => {
                "type"                => "merchant_account",
                "merchant_account_id" => "b8d4dda0-ff2c-4d77-a6da-4615e4bad941"
            },
        },
        "currency" => "GBP",
        "user"     => {
            "id"    => "ABABAB-CDCDCD-EFEFEF-GHGHGH",
            "name"  => "Remy Turr",
            "email" => 'remy.turr@yahoo.co.uk'
        },

        # response data
        "id"                 => "SOMEID",
        "provider_selection" => {
            "type"        => "user_selected",
            "provider_id" => ["eg-provider"],
            "filter"      => {
                "countries"         => ["GB"],
                "release_channel"   => "general_availability",
                "customer_segments" => ["retail"],
                "provider_ids"      => ["mock-payments-gb-redirect"],
                "excludes"          => {
                    "provider_ids" => ["ob-exclude-this-bank"]
                }
            }
        },
        "created_at"  => "string",
        "constraints" => {
            "valid_from"                => "2022-01-01T00:00:00.000Z",
            "valid_to"                  => "2022-12-31T23:59:59.999Z",
            "maximum_individual_amount" => 0,
            "periodic_limits"           => {
                "day" => {
                    "maximum_amount"   => 0,
                    "period_alignment" => "consent"
                },
                "week" => {
                    "maximum_amount"   => 0,
                    "period_alignment" => "consent"
                },
                "fortnight" => {
                    "maximum_amount"   => 0,
                    "period_alignment" => "consent"
                },
                "month" => {
                    "maximum_amount"   => 0,
                    "period_alignment" => "consent"
                },
                "half_year" => {
                    "maximum_amount"   => 0,
                    "period_alignment" => "consent"
                },
                "year" => {
                    "maximum_amount"   => 0,
                    "period_alignment" => "consent"
                }
            }
        },
        "metadata" => {
            "prop1" => "value1",
            "prop2" => "value2"
        },
        "status" => "authorization_required"
    };
}

done_testing();
