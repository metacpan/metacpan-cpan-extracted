#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::MockObject;
use Test::Exception;
use Mojo::JSON qw/ decode_json /;

# this makes Business::Monzo::Exception show a stack
# trace when any error is thrown so i don't have to keep
# wrapping stuff in this test in evals to debug
$ENV{MONZO_DEBUG} = 0;

use_ok( 'Business::Monzo' );
isa_ok(
    my $Monzo = Business::Monzo->new(
        token => 'MvYX0i6snRh/1PXfPoc6',
    ),
    'Business::Monzo'
);

can_ok(
    $Monzo,
    qw/
        token
        api_url
        client
        transactions
        transaction
        accounts
    /,
);

isa_ok( $Monzo->client,'Business::Monzo::Client' );

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

test_transaction( $Monzo,$mock );
test_account( $Monzo,$mock );
test_balance( $Monzo,$mock );
test_attachment( $Monzo,$mock );

*Business::Monzo::Client::_api_request = sub { shift; return shift };

is( $Monzo->client->api_get,'GET','api_get' );
is( $Monzo->client->api_post,'POST','api_post' );
is( $Monzo->client->api_delete,'DELETE','api_delete' );
is( $Monzo->client->api_patch,'PATCH','api_patch' );

done_testing();

sub test_transaction {

    my ( $Monzo,$mock ) = @_;

    note( "Transaction" );

    $mock->mock( 'json',sub { _transaction_json() } );

    isa_ok(
        my $Transaction = $Monzo->transaction( id => 1 ),
        'Business::Monzo::Transaction'
    );

    $mock->mock( 'json',sub { _transactions_json() } );

    isa_ok(
        $Transaction = ( $Monzo->transactions( account_id => 1 ) )[1],
        'Business::Monzo::Transaction'
    );
}

sub test_account {

    my ( $Monzo,$mock ) = @_;

    note( "Account" );

    $mock->mock( 'json',sub { _accounts_json() } );

    isa_ok(
        my $Account = ( $Monzo->accounts )[1],
        'Business::Monzo::Account'
    );
}

sub test_balance {

    my ( $Monzo,$mock ) = @_;

    $mock->mock( 'json',sub { _balance_json() } );

    isa_ok(
        $Monzo->balance( account_id => 1 ),
        'Business::Monzo::Balance'
    );
}

sub test_attachment {

    my ( $Monzo,$mock ) = @_;

    isa_ok(
        $Monzo->upload_attachment(
            file_name => 'foo.png',
            file_type => 'image/png',
        ),
        'Business::Monzo::Attachment'
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
