#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::MockObject;
use Test::Exception;
use Mojo::JSON qw/ decode_json /;

# this makes Business::Mondo::Exception show a stack
# trace when any error is thrown so i don't have to keep
# wrapping stuff in this test in evals to debug
$ENV{MONDO_DEBUG} = 0;

use_ok( 'Business::Mondo' );
isa_ok(
    my $Mondo = Business::Mondo->new(
        token => 'MvYX0i6snRh/1PXfPoc6',
    ),
    'Business::Mondo'
);

can_ok(
    $Mondo,
    qw/
        token
        api_url
        client
        transactions
        transaction
        accounts
    /,
);

isa_ok( $Mondo->client,'Business::Mondo::Client' );

# monkey patching Mojo::UserAgent here to make this test work without
# having to actually hit the endpoints or use credentials
no warnings 'redefine';
no warnings 'once';
my $mock = Test::MockObject->new;
$mock->mock( 'success',sub { 1 } );
$mock->mock( 'headers',sub { $mock } );
$mock->mock( 'res',sub { $mock } );
$mock->mock( 'json',sub { $mock } );
*Mojo::UserAgent::post = sub { $mock };
*Mojo::UserAgent::put = sub { $mock };
*Mojo::UserAgent::patch = sub { $mock };
*Mojo::UserAgent::get = sub { $mock };

test_transaction( $Mondo,$mock );
test_account( $Mondo,$mock );
test_balance( $Mondo,$mock );
test_attachment( $Mondo,$mock );

*Business::Mondo::Client::_api_request = sub { shift; return shift };

is( $Mondo->client->api_get,'GET','api_get' );
is( $Mondo->client->api_post,'POST','api_post' );
is( $Mondo->client->api_delete,'DELETE','api_delete' );
is( $Mondo->client->api_patch,'PATCH','api_patch' );

done_testing();

sub test_transaction {

    my ( $Mondo,$mock ) = @_;

    note( "Transaction" );

    $mock->mock( 'json',sub { _transaction_json() } );

    isa_ok(
        my $Transaction = $Mondo->transaction( id => 1 ),
        'Business::Mondo::Transaction'
    );

    $mock->mock( 'json',sub { _transactions_json() } );

    isa_ok(
        $Transaction = ( $Mondo->transactions( account_id => 1 ) )[1],
        'Business::Mondo::Transaction'
    );
}

sub test_account {

    my ( $Mondo,$mock ) = @_;

    note( "Account" );

    $mock->mock( 'json',sub { _accounts_json() } );

    isa_ok(
        my $Account = ( $Mondo->accounts )[1],
        'Business::Mondo::Account'
    );
}

sub test_balance {

    my ( $Mondo,$mock ) = @_;

    $mock->mock( 'json',sub { _balance_json() } );

    isa_ok(
        $Mondo->balance( account_id => 1 ),
        'Business::Mondo::Balance'
    );
}

sub test_attachment {

    my ( $Mondo,$mock ) = @_;

    isa_ok(
        $Mondo->upload_attachment(
            file_name => 'foo.png',
            file_type => 'image/png',
        ),
        'Business::Mondo::Attachment'
    );
}

sub _transaction_json {

    return decode_json( qq{{
    "transaction": {
        "account_balance": 13013,
        "amount": -510,
        "created": "2015-08-22T12:20:18Z",
        "currency": "GBP",
        "description": "THE DE BEAUVOIR DELI C LONDON        GBR",
        "id": "tx_00008zIcpb1TB4yeIFXMzx",
        "merchant": {
            "address": {
                "address": "98 Southgate Road",
                "city": "London",
                "country": "GB",
                "latitude": 51.54151,
                "longitude": -0.08482400000002599,
                "postcode": "N1 3JD",
                "region": "Greater London"
            },
            "created": "2015-08-22T12:20:18Z",
            "group_id": "grp_00008zIcpbBOaAr7TTP3sv",
            "id": "merch_00008zIcpbAKe8shBxXUtl",
            "logo": "https://pbs.twimg.com/profile_images/527043602623389696/68_SgUWJ.jpeg",
            "emoji": "🍞",
            "name": "The De Beauvoir Deli Co.",
            "category": "eating_out"
        },
        "metadata": {},
        "notes": "Salmon sandwich 🍞",
        "is_load": false,
        "settled": "2015-08-23T12:20:18Z"
    }
}} );

}

sub _transactions_json {

    return decode_json( qq{{
    "transactions": [
        {
        "account_balance": 13013,
        "amount": -510,
        "created": "2015-08-22T12:20:18Z",
        "currency": "GBP",
        "description": "THE DE BEAUVOIR DELI C LONDON        GBR",
        "id": "tx_00008zIcpb1TB4yeIFXMzx",
        "merchant": "merch_00008zIcpbAKe8shBxXUtl",
        "metadata": {},
        "notes": "Salmon sandwich 🍞",
        "is_load": false,
        "settled": "2015-08-23T12:20:18Z"
        },
        {
        "account_balance": 13013,
        "amount": -510,
        "created": "2015-08-22T12:20:18Z",
        "currency": "GBP",
        "description": "THE DE BEAUVOIR DELI C LONDON        GBR",
        "id": "tx_00008zIcpb1TB4yeIFXMzx",
        "merchant": "merch_00008zIcpbAKe8shBxXUtl",
        "metadata": {},
        "notes": "Salmon sandwich 🍞",
        "is_load": false,
        "settled": "2015-08-23T12:20:18Z"
        }
    ]
}} );

}

sub _accounts_json {

    return decode_json( qq{{
    "accounts": [
        {
            "id": "acc_00009237aqC8c5umZmrRdh",
            "description": "Peter Pan's Account",
            "created": "2015-11-13T12:17:42Z"
        },
        {
            "id": "acc_00009238aqC8c5umZmrRdh",
            "description": "Wendy's Account",
            "created": "2015-11-13T12:17:42Z"
        }
    ]
}} );

}

sub _balance_json {

    return decode_json( qq{{
        "balance" : 5000,
        "currency" : "GBP",
        "soend_today" : 0
    }} );
}

# vim: ts=4:sw=4:et
