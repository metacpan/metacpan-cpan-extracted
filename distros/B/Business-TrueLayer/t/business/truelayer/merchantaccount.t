#!perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

use_ok( 'Business::TrueLayer::MerchantAccount' );
use_ok( 'Business::TrueLayer::MerchantAccount::Identifier' );

# Using arrays rather than flattened hashes to keep the test order deterministic
my @first = (
    'account_number' => '00033171',
    'sort_code' => '040668',
    'type' => 'sort_code_account_number'
);
my @second = (
    'iban' => 'GB05CLRB04066800033171',
    'type' => 'iban'
);

my $MerchantAccount = Business::TrueLayer::MerchantAccount->new(
    'id' => '5b7adbf4-f289-48a7-b451-bc236443397c',
    'available_balance_in_minor' => 90000,
    'currency' => 'GBP',
    'current_balance_in_minor' => 100000,
    'account_holder_name' => 'btdt',
    'account_identifiers' => [

        # one an object, one a hashref to test coercion
        Business::TrueLayer::MerchantAccount::Identifier->new( @first ),
        { @second },
    ],
);

isa_ok(
    $MerchantAccount,
    'Business::TrueLayer::MerchantAccount',
);

is( $MerchantAccount->id,'5b7adbf4-f289-48a7-b451-bc236443397c','->id' );
is( $MerchantAccount->available_balance_in_minor,90000,'->available_balance_in_minor' );
is( $MerchantAccount->current_balance_in_minor,100000,'->current_balance_in_minor' );
is( $MerchantAccount->currency,'GBP','->currency' );
is( $MerchantAccount->account_holder_name,'btdt','->account_holder_name' );

cmp_deeply(
    $MerchantAccount->account_identifiers,
    [
        all(
            isa ( 'Business::TrueLayer::MerchantAccount::Identifier' ),
            methods( @first )
        ),
        all(
            isa ( 'Business::TrueLayer::MerchantAccount::Identifier' ),
            methods( @second )
        )
    ],
    '->account_identifiers'
);

done_testing();
