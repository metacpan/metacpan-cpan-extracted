#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Test::MockModule;
use JSON::PP qw(decode_json);

use Business::Stripe::Webhook;

print "\n";

my $webhook = Business::Stripe::Webhook->new(
    api_secret => 'sk_test_123',
    payload    => '{}',
);

my $mock = Test::MockModule->new('HTTP::Tiny');

my %called;
$mock->redefine(
    request => sub {
        my ($self, $method, $url, $args) = @_;
        $called{method}  = $method;
        $called{url}     = $url;
        $called{headers} = $args->{headers};
        return {
            success => 1,
            status  => 200,
            reason  => 'OK',
            content => '{"id":"sub_123","status":"active"}',
            headers => { 'content-type' => 'application/json' },
        };
    },
);

my $response = $webhook->get_subscription('sub_123');

ok( $response->{success}, 'Successful response' );
is( $called{method}, 'GET', 'Uses GET method' );
is( $called{url}, 'https://api.stripe.com/v1/subscriptions/sub_123', 'Uses subscription endpoint' );
is( $called{headers}->{Authorization}, 'Bearer sk_test_123', 'Uses API secret header' );

my $data = decode_json($response->{content});
is( $data->{id}, 'sub_123', 'Parsed JSON subscription id' );
is( $data->{status}, 'active', 'Parsed JSON subscription status' );

$mock->redefine(
    request => sub {
        return {
            success => 0,
            status  => 400,
            reason  => 'Bad Request',
            content => '{"error":"invalid subscription"}',
            headers => { 'content-type' => 'application/json' },
        };
    },
);

my $fail_response = $webhook->get_subscription('sub_bad');

ok( !$fail_response->{success}, 'Failure response' );
like( $fail_response->{content}, qr/invalid subscription/, 'Failure surfaces error content' );

done_testing();
