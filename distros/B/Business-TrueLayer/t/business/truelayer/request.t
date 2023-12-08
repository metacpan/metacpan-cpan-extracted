#!perl

use strict;
use warnings;
use feature qw/ signatures postderef /;

use Test::MockObject;
use Test::Most;
use Test::Warnings;
no warnings qw/ experimental::signatures experimental::postderef /;

use_ok( 'Business::TrueLayer::Request' );
isa_ok(
    my $Request = Business::TrueLayer::Request->new(
        _ua           => my $ua     = Test::MockObject->new,
        signer        => my $signer = Test::MockObject->new,
        authenticator => my $auth   = Test::MockObject->new,

        client_id => 'TL-CLIENT-ID',
        client_secret => 'super-secret-client-secret',
        host => '/dev/null',
    ),
    'Business::TrueLayer::Request'
);

subtest '->idempotency_key' => sub {
    my %unique_keys;
    for ( 1 .. 10 ) {

        is(
            ++$unique_keys{ $Request->idempotency_key }, 1,
            '->idempotency_key is unique'
        );
    }
};


$signer->mock( sign_request => sub { 'A..B' } );

$auth->mock( 'access_token' => sub { 'XYZ' } );

my %status = (
    code => 200,
);

$ua->mock( build_tx => sub($self, $method, $url, $headers, @ ) {
    is( ref $headers, 'HASH', 'headers are a hashdef' );
    # Yes, strictly these are case insenstive. This test is good enough:
    like( $headers->{Authorization}, qr/\ABearer /, 'Authorisation header' );
    if( $method eq 'POST' ) {
        is( $headers->{'Tl-Signature'}, 'A..B', 'JWT in Tl-Signature' );
        isnt( $headers->{'Idempotency-Key'}, undef, 'Idempotency Key' );
    }

    my $response = Test::MockObject->new();
    $response->mock(
        result => sub {
            my $result = Test::MockObject->new();

            $result->mock( is_success => sub($self) {
                               $self->code =~ /\A2/;
                           } );
            $result->mock( is_error => sub($self) {
                               $self->code =~ /\A[45]/;
                           } );
            $result->set_always(
                body => $method eq 'POST' ? '{"p":{}}' : '{"g":[]}'
            );
            my $headers = Test::MockObject->new();
            $headers->set_always( content_type => 'application/json' );
            $headers->set_always( location => 'behind the sofa' );
            $result->set_always( headers => $headers );
            # This can actually override the previous "defaults"
            while ( my ($method, $return) = each %status ) {
                $result->set_always( $method, $return );
            }

            return $result;
        } );
});
$ua->mock( start => sub($self, $tx) { return $tx } );

lives_ok(
    sub {
        cmp_deeply( $Request->api_post( '/foo',{} ), { p => {} }, 'post result' );
    },
    '->api_post',
);
lives_ok(
    sub {
        cmp_deeply( $Request->api_get( '/foo' ), { g => [] }, 'get result' );
    },
    '->api_get',
);
lives_ok(
    sub {
        %status = (
            code => 200,
            body => ' [ {}, {} ] '
        );
        cmp_deeply( $Request->api_get( '/foo', 0 ), ' [ {}, {} ] ', 'get result' );
    },
    '->api_get, not JSON',
);

lives_ok(
    sub {
        %status = (
            code => 204,
            body => undef,
        );
        $Request->api_post( '/foo',{} );
    },
    '->api_post, no content',
);

subtest 'failures' => sub {
    %status = (
        code => 400,
        message => "error message"
    );

    throws_ok(
        sub { $Request->api_post( '/foo',{} ) },
        qr/TrueLayer POST .* returned 400 with JSON keys 'p' and status line: error message/,
    );

    throws_ok(
        sub { $Request->api_get( '/foo', ) },
        qr/TrueLayer GET .* returned 400 with JSON keys 'g' and status line: error message/,
    );

    %status = (
        code => 301,
    );

    throws_ok(
        sub { $Request->api_post( '/foo',{} ) },
        qr/\ATrueLayer POST .* failed > 5 levels of redirect /,
    );

    %status = (
        code => 0,
        message => "nothing of value",
        body => '{"error":"out of cheese"}',
    );

    throws_ok(
        sub { $Request->api_post( '/foo',{} ) },
        qr/TrueLayer POST .* returned 0 'out of cheese' /,
    );
};

done_testing();
