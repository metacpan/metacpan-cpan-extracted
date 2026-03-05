package Amazon::CreatorsAPI::Auth;
use strict;
use warnings;
use Carp qw/croak/;
use JSON qw//;
use HTTP::Tiny;
use WWW::Form::UrlEncoded qw/build_urlencoded/;
use Class::Accessor::Lite (
    ro => [qw/
        credential_id
        credential_secret
        credential_version
        is_lwa
        auth_endpoint
        ua
        grant_type
    /],
    rw => [qw/
        access_token
        expires_at
    /],
);

our $JSON = JSON->new;

sub new {
    my $class              = shift;
    my $credential_id      = shift or croak 'credential_id is required';
    my $credential_secret  = shift or croak 'credential_secret is required';
    my $credential_version = shift or croak 'credential_version is required';
    my $opt                = shift || +{};

    return bless +{
        credential_id      => $credential_id,
        credential_secret  => $credential_secret,
        credential_version => $credential_version,
        is_lwa             => !!($credential_version =~ m!^3\.!),
        auth_endpoint      => $opt->{auth_endpoint} || _auth_endpoint($credential_version),
        ua                 => $opt->{ua} || HTTP::Tiny->new,
        grant_type         => $opt->{grant_type} || 'client_credentials',
        access_token       => '',
        expires_at         => 0,
    }, $class;
}

sub get_access_token {
    my $self = shift;

    if ($self->_is_valid_token) {
        return $self->access_token;
    }

    return $self->_refresh_token;
}

sub _is_valid_token {
    my $self = shift;

    return $self->access_token && $self->expires_at && time() < $self->expires_at;
}

sub _refresh_token {
    my $self = shift;

    my $res;
    if ($self->is_lwa) {
        $res = $self->ua->request(
            'POST',
            $self->auth_endpoint,
            {
                'headers' => {
                    'Content-Type' => 'application/json',
                },
                'content' => $JSON->encode({
                    'grant_type' => $self->grant_type,
                    'client_id'  => $self->credential_id,
                    'client_secret' => $self->credential_secret,
                    'scope' => 'creatorsapi::default',
                }),
            },
        );
    }
    else {
        $res = $self->ua->request(
            'POST',
            $self->auth_endpoint,
            {
                'headers' => {
                    'Content-Type' => 'application/x-www-form-urlencoded',
                },
                'content' => build_urlencoded(
                    'grant_type' => $self->grant_type,
                    'client_id'  => $self->credential_id,
                    'client_secret' => $self->credential_secret,
                    'scope' => 'creatorsapi/default',
                ),
            },
        );
    }

    if (!$res->{success}) {
        $self->_clear_token;
        croak "failed to get token status:$res->{status} "
            . ($res->{reason} || 'reason_unknown')
            . ", $res->{content}";
    }

    my $res_data = +{};
    eval {
        $res_data = $JSON->decode($res->{content});
    };
    if (my $e = $@) {
        $self->_clear_token;
        croak "could not JSON decode, $e : " . $res->{content};
    }

    $self->expires_at(time() + ($res_data->{expires_in} || 3600) - 30);
    $self->access_token($res_data->{access_token});

    return $self->access_token;
}

my $AUTH_ENDPOINT_MAP = {
    '2.1' => 'https://creatorsapi.auth.us-east-1.amazoncognito.com/oauth2/token',
    '2.2' => 'https://creatorsapi.auth.eu-south-2.amazoncognito.com/oauth2/token',
    '2.3' => 'https://creatorsapi.auth.us-west-2.amazoncognito.com/oauth2/token',
    '3.1' => 'https://api.amazon.com/auth/o2/token',
    '3.2' => 'https://api.amazon.co.uk/auth/o2/token',
    '3.3' => 'https://api.amazon.co.jp/auth/o2/token',
};

sub _auth_endpoint {
    my $version = shift;

    if (!$version || !exists $AUTH_ENDPOINT_MAP->{$version}) {
        croak "Unsupported version: "
            . ($version || 'unknown')
            . ", Supported: " . join(", ", sort keys %{$AUTH_ENDPOINT_MAP});
    }

    return $AUTH_ENDPOINT_MAP->{$version};
}

sub _clear_token {
    my $self = shift;

    $self->access_token(undef);
    $self->expires_at(undef);
}

1;

__END__

=encoding UTF-8

=head1 NAME

Amazon::CreatorsAPI::Auth - Handle to get auth token


=head1 DESCRIPTION

Amazon::CreatorsAPI::Auth handles to get auth token

The flow to fetch access token: https://affiliate-program.amazon.com/creatorsapi/docs/en-us/get-started/using-curl


=head1 METHODS

=head2 new($credential_id, $credential_secret, $credential_version, $opt)

Constructor

=head2 get_access_token()

get valid access token to call API


=head1 AUTHOR

Dai Okabayashi


=head1 LICENSE

C<Amazon::CreatorsAPI::Auth> is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. (Note that, unlike the Artistic License 1.0, version 2.0 is GPL compatible by itself, hence there is no benefit to having an Artistic 2.0 / GPL disjunction.) See the file LICENSE for details.

=cut
