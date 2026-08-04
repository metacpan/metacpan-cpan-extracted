use 5.026;
use strict;
use warnings;
use utf8;

use HTTP::Tiny 0.084;
use JSON::PP qw(encode_json);
use Test::More;

use Audio::Scrobbler2;

{
    package Local::FakeHTTP;

    use parent 'HTTP::Tiny';

    sub new {
        return bless {
            calls         => [],
            encoded_forms => [],
            responses     => [],
        }, shift;
    }

    sub enqueue {
        my ($self, @responses) = @_;
        push @{$self->{responses}}, @responses;
    }

    sub get {
        my ($self, $url) = @_;
        push @{$self->{calls}}, {
            method => 'GET',
            url    => $url,
        };

        return shift @{$self->{responses}};
    }

    sub post_form {
        my ($self, $url, $form) = @_;
        push @{$self->{encoded_forms}}, $self->www_form_urlencode($form);
        push @{$self->{calls}}, {
            form   => {%{$form}},
            method => 'POST',
            url    => $url,
        };

        return shift @{$self->{responses}};
    }
}

{
    package Local::Scrobbler;

    use parent 'Audio::Scrobbler2';

    our $HTTP;

    sub _build_http_client {
        return $HTTP;
    }
}

sub successful_response {
    my ($data) = @_;

    return {
        content => encode_json($data),
        headers => {},
        reason  => 'OK',
        status  => 200,
        success => 1,
    };
}

sub new_client {
    my $http = Local::FakeHTTP->new;
    $Local::Scrobbler::HTTP = $http;

    return (Local::Scrobbler->new('key', 'secret'), $http);
}

my ($client, $http) = new_client();

is(
    $client->_signature({
        api_key => 'key',
        format  => 'json',
        method  => 'auth.getToken',
    }),
    'b4705499705a550b07ca058a15bde9b0',
    'signature excludes format',
);

is(
    $client->_signature({
        api_key => 'key',
        artist  => 'Би-2',
        method  => 'track.updateNowPlaying',
        sk      => 'session',
        track   => 'Metsatöll',
    }),
    '899f569545184a75096e2a05af0f6417',
    'signature uses UTF-8 bytes',
);

$http->enqueue(successful_response({token => 'token'}));
is($client->auth_getToken, 'token', 'auth_getToken returns the token');
is_deeply(
    $http->{calls}[0],
    {
        method => 'GET',
        url    => 'https://ws.audioscrobbler.com/2.0/'
            . '?api_key=key'
            . '&api_sig=b4705499705a550b07ca058a15bde9b0'
            . '&format=json'
            . '&method=auth.getToken',
    },
    'auth.getToken is signed and sent as a JSON GET request',
);

$http->enqueue(successful_response({session => {key => 'session'}}));
is($client->auth_getSession, 'session', 'auth_getSession returns the session key');
is_deeply(
    $http->{calls}[1],
    {
        method => 'GET',
        url    => 'https://ws.audioscrobbler.com/2.0/'
            . '?api_key=key'
            . '&api_sig=9ac306496295a8866c4a8673395540eb'
            . '&format=json'
            . '&method=auth.getSession'
            . '&token=token',
    },
    'auth.getSession includes the token and exact signature',
);

$http->enqueue(successful_response({nowplaying => {artist => 'Би-2'}}));
is_deeply(
    $client->track_updateNowPlaying('Би-2', 'Metsatöll'),
    {nowplaying => {artist => 'Би-2'}},
    'track_updateNowPlaying returns decoded JSON',
);
is_deeply(
    $http->{calls}[2],
    {
        form => {
            api_key => 'key',
            api_sig => '899f569545184a75096e2a05af0f6417',
            artist  => 'Би-2',
            format  => 'json',
            method  => 'track.updateNowPlaying',
            sk      => 'session',
            track   => 'Metsatöll',
        },
        method => 'POST',
        url    => 'https://ws.audioscrobbler.com/2.0/',
    },
    'now-playing POST keeps Unicode values and exact signature',
);
is(
    $http->{encoded_forms}[0],
    'api_key=key'
        . '&api_sig=899f569545184a75096e2a05af0f6417'
        . '&artist=%D0%91%D0%B8-2'
        . '&format=json'
        . '&method=track.updateNowPlaying'
        . '&sk=session'
        . '&track=Metsat%C3%B6ll',
    'POST form values are UTF-8 encoded',
);

$http->enqueue(successful_response({scrobbles => {accepted => 1}}));
is_deeply(
    $client->track_scrobble('Би-2', 'Metsatöll', 1_700_000_000),
    {scrobbles => {accepted => 1}},
    'track_scrobble returns decoded JSON',
);
is_deeply(
    $http->{calls}[3],
    {
        form => {
            api_key   => 'key',
            api_sig   => 'f37bea080e9e5c68c56ffb49c5da7cb4',
            artist    => 'Би-2',
            format    => 'json',
            method    => 'track.scrobble',
            sk        => 'session',
            timestamp => 1_700_000_000,
            track     => 'Metsatöll',
        },
        method => 'POST',
        url    => 'https://ws.audioscrobbler.com/2.0/',
    },
    'scrobble POST preserves the supplied start timestamp',
);

$http->enqueue(successful_response({ok => 1}));
$client->_request({
    artist => 'Би-2',
    method => 'test.get',
    track  => 'Metsatöll',
});
is(
    $http->{calls}[4]{url},
    'https://ws.audioscrobbler.com/2.0/'
        . '?artist=%D0%91%D0%B8-2'
        . '&format=json'
        . '&method=test.get'
        . '&track=Metsat%C3%B6ll',
    'GET query values are UTF-8 encoded',
);

my $real_client = Audio::Scrobbler2->new('key', 'secret');
is($real_client->{http}->agent, 'Audio-Scrobbler2/1.00', 'client identifies itself');
is($real_client->{http}->keep_alive, 1, 'client enables keep-alive');
is($real_client->{http}->timeout, 30, 'client uses a 30 second timeout');
is($real_client->{http}->verify_SSL, 1, 'client verifies TLS certificates');

done_testing;
