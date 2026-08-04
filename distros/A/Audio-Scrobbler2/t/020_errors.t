use 5.026;
use strict;
use warnings;

use HTTP::Tiny 0.084;
use JSON::PP qw(encode_json);
use Test::More;

use Audio::Scrobbler2;

{
    package Local::ErrorHTTP;

    use parent 'HTTP::Tiny';

    sub new {
        return bless {responses => []}, shift;
    }

    sub enqueue {
        my ($self, @responses) = @_;
        push @{$self->{responses}}, @responses;
    }

    sub get {
        my ($self) = @_;
        return shift @{$self->{responses}};
    }

    sub post_form {
        my ($self) = @_;
        return shift @{$self->{responses}};
    }
}

{
    package Local::ErrorScrobbler;

    use parent 'Audio::Scrobbler2';

    our $HTTP;

    sub _build_http_client {
        return $HTTP;
    }
}

sub dies_like {
    my ($code, $pattern, $name) = @_;

    local $@;
    eval { $code->() };
    like($@, $pattern, $name);
}

sub response {
    my (%args) = @_;

    return {
        content => '',
        headers => {},
        reason  => 'OK',
        status  => 200,
        success => 1,
        %args,
    };
}

sub new_client {
    my $http = Local::ErrorHTTP->new;
    $Local::ErrorScrobbler::HTTP = $http;

    return (Local::ErrorScrobbler->new('key', 'secret'), $http);
}

dies_like(
    sub { Audio::Scrobbler2->new(undef, 'secret') },
    qr/\AAPI key is required/,
    'constructor requires an API key',
);
dies_like(
    sub { Audio::Scrobbler2->new('key', '') },
    qr/\AAPI secret is required/,
    'constructor requires an API secret',
);

my ($client, $http) = new_client();

dies_like(
    sub { $client->auth_getSession },
    qr/\AAPI token is required/,
    'auth_getSession requires a token',
);
dies_like(
    sub { $client->set_session_key('') },
    qr/\ASession key is required/,
    'set_session_key rejects an empty key',
);
dies_like(
    sub { $client->track_updateNowPlaying('Artist', 'Track') },
    qr/\ASession key is required/,
    'track methods require a session key',
);

$client->set_session_key('session');

for my $case (
    [undef, 'Track', 1, qr/\AArtist is required/, 'artist is required'],
    ['Artist', undef, 1, qr/\ATrack is required/, 'track is required'],
    ['Artist', 'Track', undef, qr/\ATimestamp must be a positive integer/, 'timestamp is required'],
    ['Artist', 'Track', 0, qr/\ATimestamp must be a positive integer/, 'timestamp must be positive'],
    ['Artist', 'Track', '1.5', qr/\ATimestamp must be a positive integer/, 'timestamp must be an integer'],
) {
    my ($artist, $track, $timestamp, $pattern, $name) = @{$case};
    dies_like(
        sub { $client->track_scrobble($artist, $track, $timestamp) },
        $pattern,
        $name,
    );
}

$http->enqueue(response(
    content => encode_json({error => 13, message => 'Invalid method signature supplied'}),
    reason  => 'Forbidden',
    status  => 403,
    success => 0,
));
dies_like(
    sub { $client->auth_getToken },
    qr/\ALast\.fm API error 13: Invalid method signature supplied/,
    'Last.fm API errors take precedence over HTTP status',
);

$http->enqueue(response(
    content => 'TLS handshake failed',
    reason  => 'Internal Exception',
    status  => 599,
    success => 0,
));
dies_like(
    sub { $client->auth_getToken },
    qr/\ALast\.fm transport error 599: Internal Exception/,
    'transport errors are identified',
);

$http->enqueue(response(
    content => '<html>unavailable</html>',
    reason  => 'Service Unavailable',
    status  => 503,
    success => 0,
));
dies_like(
    sub { $client->auth_getToken },
    qr/\ALast\.fm HTTP error 503: Service Unavailable/,
    'HTTP errors are identified before malformed bodies',
);

$http->enqueue(response(content => 'not json'));
dies_like(
    sub { $client->auth_getToken },
    qr/\ALast\.fm returned invalid JSON:/,
    'malformed successful response is rejected',
);

$http->enqueue(response());
dies_like(
    sub { $client->auth_getToken },
    qr/\ALast\.fm returned an empty response/,
    'empty successful response is rejected',
);

$http->enqueue(response(content => '[]'));
dies_like(
    sub { $client->auth_getToken },
    qr/\ALast\.fm returned an unexpected JSON value/,
    'non-object JSON response is rejected',
);

$http->enqueue(response(content => encode_json({status => 'ok'})));
dies_like(
    sub { $client->auth_getToken },
    qr/\AToken in Last\.fm response is required/,
    'auth.getToken requires a token field',
);

my ($session_client, $session_http) = new_client();
$session_http->enqueue(response(content => encode_json({token => 'token'})));
$session_client->auth_getToken;
$session_http->enqueue(response(content => encode_json({session => {}})));
dies_like(
    sub { $session_client->auth_getSession },
    qr/\ASession key in Last\.fm response is required/,
    'auth.getSession requires a nested session key',
);

dies_like(
    sub { $client->_request({}, 'PUT') },
    qr/\AUnsupported HTTP method: PUT/,
    'unsupported internal HTTP methods are rejected',
);

done_testing;
