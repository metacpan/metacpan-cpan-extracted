package Akamai::Open::Request::EdgeGridV1;
BEGIN {
  $Akamai::Open::Request::EdgeGridV1::AUTHORITY = 'cpan:PROBST';
}
# ABSTRACT: Creates the signed authentication header for the Akamai Open API Perl clients
$Akamai::Open::Request::EdgeGridV1::VERSION = '0.03';
use strict;
use warnings;

use Moose;
use Digest::SHA qw(sha256 hmac_sha256 hmac_sha256_base64);
use MIME::Base64;
use URL::Encode qw/:all/;
use URI;

use constant {
    EDGEGRIDV1ALGO  => 'EG1-HMAC-SHA256',
    HEADER_NAME     => 'Authorization',
    CLIENT_TOKEN    => 'client_token=',
    ACCESS_TOKEN    => 'access_token=',
    TIMESTAMP_TOKEN => 'timestamp=',
    NONCE_TOKEN     => 'nonce=',
    SIGNATURE_TOKEN => 'signature='
};

extends 'Akamai::Open::Request';

has 'client'         => (is => 'rw', trigger => \&Akamai::Open::Debug::debugger);
has 'signed_headers' => (is => 'rw', trigger => \&Akamai::Open::Debug::debugger);
has 'signature'      => (is => 'rw', trigger => \&Akamai::Open::Debug::debugger);
has 'signing_key'    => (is => 'rw', isa => 'Str', trigger => \&Akamai::Open::Debug::debugger);

before 'sign_request' => sub {
    my $self = shift;
    my $tmp_key;
    $self->debug->logger->debug(sprintf('Calculating signing key from %s and %s', $self->timestamp(),$self->client->client_secret()));
    $tmp_key = encode_base64(hmac_sha256($self->timestamp(),$self->client->client_secret()));
    chomp($tmp_key);
    $self->signing_key($tmp_key);
    return;
};

after 'sign_request' => sub {
    my $self = shift;

    if(defined($self->signature)) {
        my $header_name = HEADER_NAME;
        my $auth_header = sprintf('%s %s', EDGEGRIDV1ALGO,
                                           join(';', CLIENT_TOKEN . $self->client->client_token(),
                                                     ACCESS_TOKEN . $self->client->access_token(),
                                                     TIMESTAMP_TOKEN . $self->timestamp(),
                                                     NONCE_TOKEN . $self->nonce(),
                                                     SIGNATURE_TOKEN . $self->signature()));

        $self->debug->logger->debug("Setting Authorization header to $auth_header");
        $self->request->header($header_name => $auth_header);
    }

    if(defined($self->signed_headers)) {
        my $headers = $self->signed_headers;
        $self->request->header($_ => $headers->{$_}) foreach(keys(%{$headers}));
    }
};


sub sign_request {
    my $self = shift;

    # to create a valid auth header, we'll need
    # the http request method (i.e. GET, POST, PUT)
    my $http_method  = $self->request->method;
    # the http scheme in lowercases (i.e. http or https)
    my $http_scheme  = $self->request->uri->scheme;
    # the http host header 
    my $http_host    = $self->request->uri->host;
    # the encoded uri including the query string if present
    my $http_uri     = $self->request->uri->path_query;
    # the canonicalized headers which are choosed for signing
    my $http_headers = $self->canonicalize_headers;
    # the content hash for POST/PUT requests
    my $content_hash = $self->content_hash;
    # and the authorization header content
    my $auth_header  = sprintf('%s %s;', EDGEGRIDV1ALGO,
                                         join(';', CLIENT_TOKEN . $self->client->client_token,
                                                   ACCESS_TOKEN . $self->client->access_token,
                                                   TIMESTAMP_TOKEN . $self->timestamp,
                                                   NONCE_TOKEN . $self->nonce));
    # now create the token to sign
    my $token = join("\t", $http_method, $http_scheme, $http_host, $http_uri, $http_headers, $content_hash, $auth_header);

    $self->debug->logger->info("Signing token is $token");
    if($self->debug->logger->is_debug()) {
        my $dbg = $token;
        $dbg =~ s#\t#\\t#g;
        $self->debug->logger->debug("Quoted sigining token is $dbg");
    }

    # and sign the token
    $self->debug->logger->info(sprintf('signing with key %s', $self->signing_key()));
    my $tmp_stoken = encode_base64(hmac_sha256($token, $self->signing_key()));
    chomp($tmp_stoken);
    $self->signature($tmp_stoken);
    return;
}

sub content_hash {
    my $self = shift;
    my $content_hash = '';

    if($self->request->method eq 'POST' && length($self->request->content) > 0) {
        $content_hash = encode_base64(sha256($self->request->content));
        chomp($content_hash);
    }

    return($content_hash);
}

sub canonicalize_headers {
    my $self = shift;
    my $sign_headers = $self->signed_headers || {};
    return(join("\t", map {
        my $header = lc($_);
        my $value  = $sign_headers->{$_};

        # trim leading and trailing whitespaces
        $value =~ s{^\s+}{};
        $value =~ s{\s$}{};
        # replace repeated whitespaces
        $value =~ s/\s{2,}/ /g;

        "$header:$value";
    } sort(keys(%{$sign_headers}))));
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Akamai::Open::Request::EdgeGridV1 - Creates the signed authentication header for the Akamai Open API Perl clients

=head1 VERSION

version 0.03

=head1 ABOUT

I<Akamai::Open::Request::EdgeGridV1> provides the signing functionality, 
which is needed to authenticated the client against the I<Akamai::Open> 
API.

The algorithm to sign a header for a request against the API, is 
provided and described by Akamai and can be found L<here|https://developer.akamai.com/stuff/Getting_Started_with_OPEN_APIs/Client_Auth.html>.

=head1 AUTHOR

Martin Probst <internet+cpan@megamaddin.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Martin Probst.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
