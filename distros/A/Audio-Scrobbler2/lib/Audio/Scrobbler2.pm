package Audio::Scrobbler2;

use 5.026;
use strict;
use warnings;

use Carp qw(croak);
use Digest::MD5 qw(md5_hex);
use Encode qw(encode_utf8);
use HTTP::Tiny 0.084;
use JSON::PP qw(decode_json);

our $VERSION = '1.00';

my $API_URL = 'https://ws.audioscrobbler.com/2.0/';

sub new {
    my ($class, $api_key, $api_secret) = @_;

    _require_value($api_key, 'API key');
    _require_value($api_secret, 'API secret');

    my $self = bless {
        api_key    => $api_key,
        api_secret => $api_secret,
        api_url    => $API_URL,
    }, ref($class) || $class;

    $self->{http} = $self->_build_http_client;

    return $self;
}

sub _build_http_client {
    return HTTP::Tiny->new(
        agent      => "Audio-Scrobbler2/$VERSION",
        keep_alive => 1,
        timeout    => 30,
        verify_SSL => 1,
    );
}

sub _signature {
    my ($self, $params) = @_;

    my $signature = join '',
        map { $_ . $params->{$_} }
        sort grep { $_ ne 'api_sig' && $_ ne 'callback' && $_ ne 'format' }
        keys %{$params};

    return md5_hex(encode_utf8($signature . $self->{api_secret}));
}

sub _signed_params {
    my ($self, $params) = @_;
    my %signed_params = %{$params};

    $signed_params{api_sig} = $self->_signature(\%signed_params);

    return \%signed_params;
}

sub _request {
    my ($self, $params, $method) = @_;
    $method //= 'GET';

    my %fields = (%{$params}, format => 'json');
    my $response;

    if ($method eq 'POST') {
        $response = $self->{http}->post_form($self->{api_url}, \%fields);
    }
    elsif ($method eq 'GET') {
        my $query = $self->{http}->www_form_urlencode(\%fields);
        $response = $self->{http}->get("$self->{api_url}?$query");
    }
    else {
        croak "Unsupported HTTP method: $method";
    }

    my $content = $response->{content} // '';
    my ($data, $json_error);

    if (length $content) {
        local $@;
        $data = eval { decode_json($content) };
        $json_error = $@;
    }

    if (ref($data) eq 'HASH' && exists $data->{error}) {
        my $message = $data->{message} // 'Unknown error';
        croak "Last.fm API error $data->{error}: $message";
    }

    if (!$response->{success}) {
        my $status = $response->{status} // 'unknown';
        my $reason = $response->{reason} // 'Unknown error';
        my $kind = $status eq '599' ? 'transport' : 'HTTP';
        croak "Last.fm $kind error $status: $reason";
    }

    croak 'Last.fm returned an empty response' unless length $content;
    croak "Last.fm returned invalid JSON: $json_error" if $json_error;
    croak 'Last.fm returned an unexpected JSON value' unless ref($data) eq 'HASH';

    return $data;
}

sub auth_getToken {
    my ($self) = @_;

    my $params = $self->_signed_params({
        api_key => $self->{api_key},
        method  => 'auth.getToken',
    });
    my $response = $self->_request($params);
    my $token = $response->{token};

    _require_value($token, 'Token in Last.fm response');
    $self->{api_token} = $token;

    return $token;
}

sub auth_getSession {
    my ($self) = @_;

    _require_value($self->{api_token}, 'API token');

    my $params = $self->_signed_params({
        api_key => $self->{api_key},
        method  => 'auth.getSession',
        token   => $self->{api_token},
    });
    my $response = $self->_request($params);
    my $session = $response->{session};
    my $session_key = ref($session) eq 'HASH' ? $session->{key} : undef;

    _require_value($session_key, 'Session key in Last.fm response');
    $self->{api_session} = $session_key;

    return $session_key;
}

sub set_session_key {
    my ($self, $key) = @_;

    _require_value($key, 'Session key');
    $self->{api_session} = $key;

    return $key;
}

sub track_updateNowPlaying {
    my ($self, $artist, $track) = @_;

    _require_value($artist, 'Artist');
    _require_value($track, 'Track');
    _require_value($self->{api_session}, 'Session key');

    my $params = $self->_signed_params({
        api_key => $self->{api_key},
        artist  => $artist,
        method  => 'track.updateNowPlaying',
        sk      => $self->{api_session},
        track   => $track,
    });

    return $self->_request($params, 'POST');
}

sub track_scrobble {
    my ($self, $artist, $track, $timestamp) = @_;

    _require_value($artist, 'Artist');
    _require_value($track, 'Track');
    _require_value($self->{api_session}, 'Session key');
    croak 'Timestamp must be a positive integer'
        unless defined $timestamp && $timestamp =~ /\A[1-9][0-9]*\z/;

    my $params = $self->_signed_params({
        api_key   => $self->{api_key},
        artist    => $artist,
        method    => 'track.scrobble',
        sk        => $self->{api_session},
        timestamp => $timestamp,
        track     => $track,
    });

    return $self->_request($params, 'POST');
}

sub _require_value {
    my ($value, $name) = @_;

    croak "$name is required" unless defined $value && length $value;

    return $value;
}

=head1 NAME

Audio::Scrobbler2 - Interface to the Last.fm scrobbling API

=head1 SYNOPSIS

    use Audio::Scrobbler2;

    my $scrobbler = Audio::Scrobbler2->new($api_key, $api_secret);
    my $api_token = $scrobbler->auth_getToken;

    # Ask the user to authorize the token:
    # https://www.last.fm/api/auth/?api_key=$api_key&token=$api_token
    my $api_session = $scrobbler->auth_getSession;

    $scrobbler->track_updateNowPlaying('Artist Name', 'Track Name');
    $scrobbler->track_scrobble('Artist Name', 'Track Name', $started_at);

=head1 DESCRIPTION

Audio::Scrobbler2 implements the desktop authentication flow and the two
Last.fm track submission methods needed by a basic scrobbler. Requests use
HTTPS, UTF-8 form encoding, and verified TLS certificates.

All validation, transport, HTTP, JSON, and Last.fm API failures throw an
exception. The module does not retry requests because retrying a submission
could create a duplicate scrobble.

=head1 METHODS

=head2 new

    my $scrobbler = Audio::Scrobbler2->new($api_key, $api_secret);

Creates a client. Both credentials are required.

=head2 auth_getToken

    my $token = $scrobbler->auth_getToken;

Requests and stores an unauthorized desktop application token.

=head2 auth_getSession

    my $session_key = $scrobbler->auth_getSession;

Exchanges the authorized token for a session key and stores it.

=head2 set_session_key

    $scrobbler->set_session_key($session_key);

Stores an existing non-empty session key.

=head2 track_updateNowPlaying

    my $response = $scrobbler->track_updateNowPlaying($artist, $track);

Updates the currently playing track and returns the decoded Last.fm response.

=head2 track_scrobble

    my $response = $scrobbler->track_scrobble(
        $artist,
        $track,
        $started_at,
    );

Scrobbles a track and returns the decoded Last.fm response. C<$started_at>
must be a positive integer Unix timestamp for when playback started.

=head1 MIGRATING FROM 0.05

Version 1.00 requires a playback start timestamp in C<track_scrobble>. All
failures now throw exceptions instead of returning C<0> or inconsistent error
structures.

=head1 AUTHOR

Pier Dolique (L<Perdolique|https://github.com/Perdolique>),
C<baget@cpan.org>

CPAN ID: BAGET

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2026 Pier Dolique.

This software is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
