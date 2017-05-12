package Audio::Scrobbler2;

use strict;
use warnings;

use WWW::Curl::Easy;
use Digest::MD5 qw( md5_hex );
use JSON::XS qw( decode_json );
use URI::Escape qw( uri_escape );

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

    $VERSION     = '0.05';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

sub new {
    my ($class, $api_key, $api_secret) = @_;

    my $self = {
        "curl"       => WWW::Curl::Easy->new,
        "api_url"    => "http://ws.audioscrobbler.com/2.0/",
        "api_key"    => $api_key,
        "api_secret" => $api_secret
    };

    bless ($self, ref ($class) || $class);

    return $self;
}

sub _signature {
    my ($self, $params) = @_;
    my $signature = join("", map { $_ . $params->{$_} } sort keys %$params);

    return md5_hex( $signature . $self->{"api_secret"} );
}

sub _request {
    my ($self, $params, $method) = @_;
    my $response;
    my $fields = join("&", "format=json", map { join("=", $_, uri_escape($params->{$_})) } keys %$params);

    if ( $method and $method eq "POST" ) {
        $self->{"curl"}->setopt(CURLOPT_POST, 1);
        $self->{"curl"}->setopt(CURLOPT_POSTFIELDS, $fields);
        $self->{"curl"}->setopt(CURLOPT_URL, $self->{"api_url"});
    }
    else {
        $self->{"curl"}->setopt(CURLOPT_URL, join("?", $self->{"api_url"}, $fields));
    }

    $self->{"curl"}->setopt(CURLOPT_CONNECTTIMEOUT, 5);
    $self->{"curl"}->setopt(CURLOPT_TIMEOUT, 30);
    $self->{"curl"}->setopt(CURLOPT_WRITEDATA, \$response);
    $self->{"curl"}->perform;
    $self->{"curl"}->cleanup;

    return $response;
}

sub auth_getToken {
    my ($self) = @_;
    my $response = $self->_request({ method => "auth.getToken", api_key => $self->{"api_key"} });

    $self->{"api_token"} = decode_json($response)->{"token"} || 0;

    return $self->{"api_token"};
}

sub auth_getSession {
    my ($self) = @_;

    # TODO: token exception need place here

    my $sig_params = {
        api_key => $self->{"api_key"},
        method  => "auth.getSession",
        token   => $self->{"api_token"}
    };

    my $response = $self->_request({ %$sig_params, api_sig => $self->_signature($sig_params) });

    # TODO: error handling

    $self->{"api_session"} = decode_json($response)->{"session"}->{"key"} || 0;

    return $self->{"api_session"};
}

sub set_session_key {
    my ($self, $key) = @_;

    $self->{"api_session"} = $key;
}

sub track_updateNowPlaying {
    my ($self, $artist, $track) = @_;

    my $sig_params = {
        track   => $track,
        artist  => $artist,
        api_key => $self->{"api_key"},
        sk      => $self->{"api_session"},
        method  => "track.updateNowPlaying"
    };

    my $response = $self->_request({ %$sig_params, api_sig => $self->_signature($sig_params) }, "POST");

    return decode_json($response);
}

sub track_scrobble {
    my ($self, $artist, $track) = @_;

    my $sig_params = {
        track     => $track,
        artist    => $artist,
        api_key   => $self->{"api_key"},
        timestamp => time,
        sk        => $self->{"api_session"},
        method    => "track.scrobble"
    };

    my $response = $self->_request({ %$sig_params, api_sig => $self->_signature($sig_params) }, "POST");

    return decode_json($response);
}


=head1 NAME

Audio::Scrobbler2 - Interface to last.fm scrobbler API


=head1 SYNOPSIS

    use Audio::Scrobbler2;

    my $scrobbler = Audio::Scrobbler2->new($api_key, $api_secret);
    my $api_token = $scrobbler->auth_getToken();

    # web-auth required
    # http://www.last.fm/api/auth/?api_key=$api_key&token=$api_token
    my $api_session = $scrobbler->auth_getSession();

    $scrobbler->track_scrobble("Artist Name", "Track Name");


=head1 METHODS

=head2 new

    Create and return new Audio::Scrobbler2 object.


=head1 AUTHOR

    Roman (Ky6uk) Nuritdinov
    CPAN ID: BAGET
    baget@cpan.org
    http://ky6uk.org


=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=cut

1;