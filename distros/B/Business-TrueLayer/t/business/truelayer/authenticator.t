#!perl

use strict;
use warnings;
use feature qw/ signatures postderef /;

use Test::Most;
use Test::Warnings;
use Test::MockObject;
use JSON qw/ decode_json encode_json /;
no warnings qw/ experimental::signatures experimental::postderef /;

use_ok( 'Business::TrueLayer::Authenticator' );

isa_ok(
    my $Authenticator = Business::TrueLayer::Authenticator->new(
        _ua => my $ua = Test::MockObject->new,
        client_id => 'TL-CLIENT-ID',
        client_secret => 'super-secret-client-secret',
        host => '/dev/null',
    ),
    'Business::TrueLayer::Authenticator',
);

my @testcases = ({
    name => 'payments',
    desc => 'successful authentication',
    code => 200,
    type => 'application/json',
    body => {
        access_token  => "AAABBBCCCDDD",
        expires_in    => 3600,
        token_type    => "Bearer",
    }
}, {
    name => 'wrong',
    desc => 'wrong MIME type',
    code => 200,
    type => 'text/plain',
    body => 'https://humanstate.bamboohr.com/careers',
    want => qr!\bTrueLayer POST .* returned 200 text/plain not JSON\b!,
}, {
    name => 'missing',
    desc => 'no MIME type',
    code => 200,
    body => 'https://youtu.be/gJPbuNtH8aQ',
    want => qr!\bTrueLayer POST .* returned 200 with no MIME type\b!,
}, {
    name => 'empty',
    desc => 'empty JSON',
    code => 200,
    type => 'application/json',
    body => "",
    # Implication of this message is that it was declared to be JSON:
    want => qr!\bTrueLayer POST .* returned 200 with an empty body\b!,
}, {
    name => 'not',
    desc => 'not JSON',
    code => 200,
    type => 'application/json',
    body => 'https://youtu.be/t0UwYMDeTjI',
    want => qr!\bTrueLayer POST .* returned 200 with malformed JSON length 28: malformed JSON\b!,
}, {
    name => 'array',
    desc => 'JSON array',
    code => 200,
    type => 'application/json',
    body => [],
    # Implication of this message is that it was declared to be JSON:
    want => qr!\bTrueLayer POST .* returned 200 JSON ARRAY\(!,
}, {
    name => 'error',
    desc => 'access token simple error',
    code => 400,
    type => 'application/json',
    body => {
        error => 'invalid_client'
    },
    want => qr!\bTrueLayer POST .* returned 400 'invalid_client'!
}, {
    name => 'deteail',
    desc => 'access token error with detail',
    code => 500,
    type => 'application/json',
    body => {
        error => 'internal_server_error',
        error_description => 'Sorry, we are experiencing technical difficulties. Please try again later.',
    },
    want => qr!\bTrueLayer POST .* returned 500 'internal_server_error' - Sorry!
}, {
    name => 'bearer',
    desc => 'Bearer token missing',
    code => 401,
    type => 'application/problem+json',
    body => {
        type => "https://docs.truelayer.com/docs/error-types#unauthenticated",
        title => "Unauthenticated",
        status => 401,
        detail => "A valid Bearer token must be provided in the Authorization header.",
        trace_id => "f4d057158ded560d336571800c7a054d",
    },
    want => qr!\bTrueLayer POST .* returned 401: Unauthenticated - A valid Bearer token !
}, {
    name => 'TI',
    desc => 'TI signature missing',
    code => 401,
    type => 'application/problem+json',
    body => {
        type => "https://docs.truelayer.com/docs/error-types#unauthenticated",
        title => "Unauthenticated",
        status => 401,
        detail => "Invalid header `Tl-Signature`. Invalid signature",
        trace_id => "96ce50247f87f540bb2d86771b3728b8",
    },
    want => qr!\bTrueLayer POST .* returned 401: Unauthenticated - Invalid header `Tl-Signature`!
}, {
    # Strictly it says CAN, so {} is technically valid as per the RFC.
    # But that's not very useful, so let's be a bit more stringent...
    name => 'duff',
    desc => 'not RFC-7807 JSON',
    code => 417,
    message => 'Expectation Failed',
    type => 'application/problem+json',
    body => {
        RFC => 'https://datatracker.ietf.org/doc/html/rfc7807',
        spec => 'https://datatracker.ietf.org/doc/html/rfc6919',
    },
    want => qr!\bTrueLayer POST .* returned 417 with JSON keys 'RFC', 'spec' and status line: Expectation Failed\b!
}, {
    name => 'nowt',
    desc => 'empty problem JSON',
    code => 411,
    type => 'application/problem+json',
    body => "",
    want => qr!\bTrueLayer POST .* returned 411 with an empty body\b!,
}, {
    name => 'rickroll',
    desc => 'not problem JSON',
    code => 406,
    type => 'application/problem+json',
    body => 'https://youtu.be/mASABAVRVDc',
    want => qr!\bTrueLayer POST .* returned 406 with malformed JSON length 28: malformed JSON\b!,
}, {
    name => 'brew',
    desc => 'wrong MIME type for error',
    code => 418,
    message => "I'm a teapot",
    type => 'text/plain',
    body => "short and stout",
    want => qr!\bTrueLayer POST .* returned 418 text/plain not JSON, status line: I'm a teapot\b!,
}, {
    name => 'snafu',
    desc => 'POSTing to the hosted payment pages',
    code => 405,
    message => 'Method Not Allowed',
    type => 'text/html',
    body => <<'EOT',
<head><title>405 Not Allowed</title></head>
<body>
<center><h1>405 Not Allowed</h1></center>
<hr><center>nginx</center>
</body>
</html>
EOT
    want => qr!\bTrueLayer POST .* returned 405 text/html not JSON, status line: Method Not Allowed\b!,
});

my %responses;
my %cache;

for my $testcase ( @testcases ) {
    my $type = $testcase->{type};
    my $headers = $cache{$type // ""}
        //= Test::MockObject->new->set_always( content_type => $type );
    $responses{$testcase->{name}} = {
        desc => $testcase->{desc},
        code => $testcase->{code},
        headers => $headers,
        body => ref $testcase->{body}
            ? encode_json( $testcase->{body} ) : $testcase->{body},
        message => $testcase->{message}
            // "testcase '$testcase->{name}' should not have called ->message",
    };
}

$ua->mock(
    build_tx => sub($self, $method, $url, $headers, $body) {
        # We aren't going to get unique diagnostics on this, but likely in the
        # context of the verbose test output it will help with the problems
        is( $method, 'POST', 'mocked UA called correctly' );
        # This is a bit of a hack, but we know that we can control this value
        # from our constructor, so we can cheat and use it to choose our poison:
        my $json = decode_json( $body );
        my $name = $json->{scope};
        my $results = $responses{$name};
        # This isn't going to end well. This test script is borked.
        # BAIL_OUT seems a bit overkill, but this script should abort right now:
        isnt( $results, undef, "No canned response found for $name" )
            or exit 1;
        note( "Sending the canned response for $name: $results->{desc}" );
        my $response = Test::MockObject->new( \$results );
        $response->mock(
            result => sub($self) {
                my $result = Test::MockObject->new();
                while ( my ($method, $return) = each $$self->%* ) {
                    # Uncomment this when you have no idea what is failing:
                    # note( "Mock $method to $return" );
                    $result->set_always( $method, $return );
                }
                $result->mock( is_success => sub($self) {
                                   $self->code =~ /\A2/;
                               } );
                return $result;
            }
        );
        return $response;
    }
);
$ua->mock( start => sub($self, $tx) { return $tx } );

isa_ok(
    $Authenticator->_authenticate,
    'Business::TrueLayer::Authenticator',
);

is( $Authenticator->access_token,'AAABBBCCCDDD','->access_token' );
is( $Authenticator->_auth_token,'AAABBBCCCDDD','->_auth_token' );
ok( ! $Authenticator->_refresh_token,'! ->_refresh_token' );
is( $Authenticator->_token_type,'Bearer','->_token_type' );
cmp_ok( $Authenticator->_expires_at,'>',time + 3595,'->_expires_at' );
ok( ! $Authenticator->_token_is_expired,'! ->_token_is_expired' );

# First entry is the happy path we tested just above
shift @testcases;

for my $testcase ( @testcases ) {
    subtest "Failure $testcase->{desc}" => sub {
        # Re-use the cooked user agent we created above
        my $Authenticator = Business::TrueLayer::Authenticator->new(
            _ua => $ua,
            client_id => 'TL-CLIENT-ID',
            client_secret => 'super-secret-client-secret',
            host => '/dev/null',
            # This selects the failure response:
            scope => [ $testcase->{name} ],
        );
        isa_ok( $Authenticator, 'Business::TrueLayer::Authenticator' );
        throws_ok( sub { $Authenticator->_authenticate }, $testcase->{want},
                   'meaningful error reported' );
    };
}

done_testing();
