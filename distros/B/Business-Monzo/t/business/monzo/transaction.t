#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use Mojo::JSON;

use Business::Monzo::Client;

use_ok( 'Business::Monzo::Transaction' );
isa_ok(
    my $Transaction = Business::Monzo::Transaction->new(
        'id'              => 1,
        'client'          => Business::Monzo::Client->new(
            token      => 'foo',
        ),
    ),
    'Business::Monzo::Transaction'
);

can_ok(
    $Transaction,
    qw/
        url
        get
        to_hash
        as_json
        TO_JSON

        account_balance
        account_id
        amount
        attachments
        category
        counterparty
        created
        currency
        dedupe_id
        description
        id
        is_load
        local_amount
        local_currency
        merchant
        metadata
        notes
        originator
        scheme
        settled
        updated
    /,
);

is( $Transaction->url,'https://api.monzo.com/transactions/1','url' );

no warnings 'redefine';

*Business::Monzo::Client::api_get = sub { _transaction() };

ok( $Transaction = $Transaction->get,'->get' );
isa_ok( $Transaction->merchant,'Business::Monzo::Merchant' );
isa_ok( $Transaction->merchant->address,'Business::Monzo::Address' );
isa_ok( $Transaction->currency,'Data::Currency' );
isa_ok( $Transaction->created,'DateTime' );

*Business::Monzo::Client::api_patch = sub { _transaction( $_[2] ) };
ok( $Transaction = $Transaction->annotate( foo => 1, bar => 2 ),'->annotate' );
cmp_deeply(
    $Transaction->annotations,
    { foo => 1, bar => 2 },
    '->annotations'
);

isa_ok(
    $Transaction->attachments->[1],
    'Business::Monzo::Attachment',
);

ok( $Transaction->to_hash,'to_hash' );
ok( $Transaction->as_json,'as_json' );
ok( $Transaction->TO_JSON,'TO_JSON' );

done_testing();

sub _transaction {
    my ( $metadata ) = @_;

    $metadata = { map {
        my $key = $_;
        $key =~ s/^metadata\[(\w+)\]$/$1/;
        $key => $metadata->{$_};
    } keys %{ $metadata // {} } };

    return {
        "transaction" => {
            "account_balance" => 13013,
            "amount"          => -510,
            "created"         => "2015-08-22T12:20:18Z",
            "currency"        => "GBP",
            "description"     => "THE DE BEAUVOIR DELI C LONDON        GBR",
            "id"              => "tx_00008zIcpb1TB4yeIFXMzx",
            "merchant"        => {
                "address" => {
                    "address"   => "98 Southgate Road",
                    "city"      => "London",
                    "country"   => "GB",
                    "latitude"  => 51.54151,
                    "longitude" => -0.08482400000002599,
                    "postcode"  => "N1 3JD",
                    "region"    => "Greater London"
                },
                "created"  => "2015-08-22T12:20:18Z",
                "group_id" => "grp_00008zIcpbBOaAr7TTP3sv",
                "id"       => "merch_00008zIcpbAKe8shBxXUtl",
                "logo"  => "https://pbs.twimg.com/profile_images/527043602623389696/68_SgUWJ.jpeg",
                "emoji" => "🍞",
                "name"  => "The De Beauvoir Deli Co.",
                "category" => "eating_out"
            },
            "attachments" => [
                {
                    "created" => "2016-04-23T12:46:41Z",
                    "external_id" => "tx_0000...",
                    "file_type" => "image/jpeg",
                    "file_url" => "https://...",
                    "id" => "attach_0000...",
                    "type" => "image/jpeg",
                    "url" => "https://...",
                    "user_id" => "user_0000..."
                },
                {
                    "created" => "2016-04-23T12:46:41Z",
                    "external_id" => "tx_0000...",
                    "file_type" => "image/jpeg",
                    "file_url" => "https://...",
                    "id" => "attach_0000...",
                    "type" => "image/jpeg",
                    "url" => "https://...",
                    "user_id" => "user_0000..."
                },
            ],
            "metadata" => $metadata // {},
            "notes"    => "Salmon sandwich 🍞",
            "is_load"  => Mojo::JSON::false,
            "settled"  => "2015-08-22T12:20:18Z",
        }
    };
}

# vim: ts=4:sw=4:et
