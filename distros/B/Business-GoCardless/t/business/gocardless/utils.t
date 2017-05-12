#!perl

use strict;
use warnings;

package Utils::Tester;

use Moo;
with 'Business::GoCardless::Utils';

package main;

use Test::Most;
use Test::Deep;
use Test::Exception;
use MIME::Base64 qw/ decode_base64 /;

use Business::GoCardless::Utils;

my $Utils = Utils::Tester->new;

# examples taken from gocardless API docs:
# https://developer.gocardless.com/#constructing-the-parameter-array
foreach my $test (
    [
        { cars => [ 'BMW','Fiat','VW' ] },
        [
            [ 'cars[]','BMW' ],
            [ 'cars[]','Fiat'],
            [ 'cars[]','VW'  ]
        ],
    ],
    [
        { user => { name => 'Fred', age => 30 } },
        [
            [ 'user[age]' ,'30'   ],
            [ 'user[name]','Fred' ],
        ],
    ],
    [
        { user => { name => 'Fred', cars => ['BMW', 'Fiat'] } },
        [
            [ 'user[cars][]','BMW'  ],
            [ 'user[cars][]','Fiat' ],
            [ 'user[name]'  ,'Fred' ],
        ]
    ],
) {
    cmp_deeply(
        $Utils->flatten_params( $test->[0] ),
        $test->[1],
        'flatten_params',
    );
}

# example from output from the ruby library to check complex params
# see: https://github.com/gocardless/api-docs/issues/19#issuecomment-55751695
my $params = {
    resource_type => "bill",
    action        => "paid",
    bills         => [
        {
            id                => "AKJ398H8KA",
            status            => "paid",
            source_type       => "subscription",
            source_id         => "KKJ398H8K8",
            amount            => "20.0",
            amount_minus_fees => "19.8",
            paid_at           => "2011-12-01T12:00:00Z",
            uri               => "https://gocardless.com/api/v1/bills/AKJ398H8KA"
        },
        {
            id                => "AKJ398H8KB",
            status            => "paid",
            source_type       => "subscription",
            source_id         => "8AKJ398H78",
            amount            => "40.0",
            amount_minus_fees => "19.8",
            paid_at           => "2011-12-09T12:00:00Z",
            uri               => "https://gocardless.com/api/v1/bills/AKJ398H8KB"
        }
    ],
};

my $normalized = 'action=paid&bills%5B%5D%5Bamount%5D=20.0&bills%5B%5D%5Bamount%5D=40.0&bills%5B%5D%5Bamount_minus_fees%5D=19.8&bills%5B%5D%5Bamount_minus_fees%5D=19.8&bills%5B%5D%5Bid%5D=AKJ398H8KA&bills%5B%5D%5Bid%5D=AKJ398H8KB&bills%5B%5D%5Bpaid_at%5D=2011-12-01T12%3A00%3A00Z&bills%5B%5D%5Bpaid_at%5D=2011-12-09T12%3A00%3A00Z&bills%5B%5D%5Bsource_id%5D=8AKJ398H78&bills%5B%5D%5Bsource_id%5D=KKJ398H8K8&bills%5B%5D%5Bsource_type%5D=subscription&bills%5B%5D%5Bsource_type%5D=subscription&bills%5B%5D%5Bstatus%5D=paid&bills%5B%5D%5Bstatus%5D=paid&bills%5B%5D%5Buri%5D=https%3A%2F%2Fgocardless.com%2Fapi%2Fv1%2Fbills%2FAKJ398H8KA&bills%5B%5D%5Buri%5D=https%3A%2F%2Fgocardless.com%2Fapi%2Fv1%2Fbills%2FAKJ398H8KB&resource_type=bill';

is(
	$Utils->normalize_params( $params ),
	$normalized,
	'normalize_params with complex params'
);

my $test_params = {
    user => {
        age   => 30,
        email => 'fred@example.com',
    }
};

my $app_secret = 
    '5PUZmVMmukNwiHc7V/TJvFHRQZWZumIpCnfZKrVYGpuAdkCcEfv3LIDSrsJ+xOVH';

is(
    $Utils->sign_params( $test_params,$app_secret ),
    '763f02cb9f998a5e06fda2b790bedd503ba1a34fd7cbf9e22f8ce562f73f0470',
    'sign_params'
);

ok(
    $Utils->signature_valid(
        {
            %{ $test_params },
            signature => $Utils->sign_params( $test_params,$app_secret ),
        },
        $app_secret
    ),
    'signature_valid',
);

my ( $time,$rand ) = ( split( '\|',decode_base64( $Utils->generate_nonce ) ) );
ok( length( $time ) == 10,'nonce has time' );
ok( $rand < 257,'nonce rand < 257' );

done_testing();
