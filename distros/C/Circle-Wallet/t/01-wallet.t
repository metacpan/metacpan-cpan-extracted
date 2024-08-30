#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Try::Tiny;
use JSON;
use Carp;
use Circle::Wallet;

# 1. create wallet using anonymous user.
try {
    my $result = create_wallet();
    carp encode_json($result);
    my $status = $result->{status};
    is( $status, 20000, 'create wallet not login' );

    $result = list_wallet();
    carp encode_json($result);
    $status = $result->{status};
    is( $status, 20000, 'list wallet not login' );

    $result = balance_of_address("ssssss");
    carp encode_json($result);
    $status = $result->{status};
    is( $status, 20000, 'balance of address not login' );

    $result = balance_of_wallet();
    carp encode_json($result);
    $status = $result->{status};
    is( $status, 20000, 'balance of wallet not login' );

    $result = assets_of_address( 'ssssss', 1 );
    carp encode_json($result);
    $status = $result->{status};
    is( $status, 20000, 'assets of address not login' );

    $result = assets_of_wallet();
    carp encode_json($result);
    $status = $result->{status};
    is( $status, 20000, 'assets of wallet not login' );

    $result = send_to(
        {
            from         => 'sssss',
            address      => 'rrrrr',
            email        => 'test@gmail.com',
            transContent => {
                type     => 1,
                valueHex => 'e45095ee5edd11efb6994bdea9d4f576'
            }
        }
    );
    $status = $result->{status};
    carp encode_json($result);
    is( $status, 20000, 'send to api not login' );

    $result = pay(
        {
            from       => 'ssss',
            to         => "rrrrr",
            value      => 1000,
            payPayword => '<secret payPassword>'
        }
    );
    carp encode_json($result);
    $status = $result->{status};
    is( $status, 20000, 'pay api not login' );

    $result = let_me_try();
    carp encode_json($result);
    $status = $result->{status};
    is( $status, 20000, 'let me try api not login' );
}
catch {
    carp "cannot create wallet: $_";
};

my $result = public_address_of_uid("85bc7ccf950e45f28784104a048c87d926fea2c715cf00ddd0fe55b50fab761b");
# carp encode_json($result);
is( $result->{status}, 200, 'public_address_of_uid' );

my $addresses_ref = $result->{data};
foreach my $address ( @{$addresses_ref} ) {
    my $balance_result = public_balance_of_address($address);
    # carp encode_json($balance_result);
    is( $balance_result->{status}, 200, 'public_balance_of_address' );

    my $assets_result = public_assets_of_address( $address, 1 );
    # carp encode_json($assets_result);
    is( $assets_result->{status}, 200, 'public_assets_of_address' );
}


$result = public_search_transaction(
    {
        address            => '1APGzvGwcDKWDobEEDiHtEehVz4G4jWeoR',
        inOut              => 'IN',
        transactionContent => {
            type => 0
        }
    }
);
# carp encode_json($result);
is( $result->{status}, 200 );

done_testing();
