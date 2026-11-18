#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS qw( decode_json );
use MIME::Base64 qw( decode_base64 );

use API::Docker;

# The encoder is API::Docker::Role::RegistryAuth::_registry_auth_header,
# composed into API::Docker::API::Images -- it used to be a bare sub in
# Images.pm called as a function, and Plugins.pm carried a copy. It is
# exercised here through the class that consumes it, which is what a caller
# reaches, and the shared role itself is covered in t/registry_auth.t.
my $client = API::Docker->new(
    host        => 'unix:///dev/null',
    api_version => '1.47',
);
my $images = $client->images;

# No padding is added back here on purpose. The previous version of this
# helper computed the missing '=' and appended it before decoding, which made
# every assertion below pass whether or not the header carried its own -- it
# repaired the defect it was supposed to catch. See the padding subtest.
sub b64url_decode {
    my ($s) = @_;
    $s =~ tr{-_}{+/};
    return decode_base64($s);
}

# The engine decodes X-Registry-Auth with Go's base64.URLEncoding, which
# requires padding; RawURLEncoding is what accepts it without. Measured, not
# deduced: with the '=' stripped, a push against a local registry answers
# 400 'failed to parse "X-Registry-Auth" header ... unexpected EOF', and the
# anonymous case is the shortest and most certain to need a pad -- '{}'
# encodes to three characters plus one '='.
subtest 'the header carries its base64 padding' => sub {
    my $hdr = $images->_registry_auth_header(undef);
    is $hdr, 'e30=', 'anonymous auth is exactly the padded encoding of {}';
    is length($hdr) % 4, 0, 'length is a multiple of four';

    my $creds = $images->_registry_auth_header(
        { username => 'me', password => 'secret' });
    is length($creds) % 4, 0, 'credentials are padded too';
};

subtest 'empty/undef auth -> base64url("{}")' => sub {
    my $hdr = $images->_registry_auth_header(undef);
    ok length($hdr), 'header is non-empty for undef';
    is_deeply(decode_json(b64url_decode($hdr)), {},
        'decodes to empty JSON object');
};

subtest 'hashref auth -> JSON-encoded credentials' => sub {
    my $auth = {
        username      => 'me',
        password      => 'secret',
        serveraddress => 'https://index.docker.io/v1/',
    };
    my $hdr = $images->_registry_auth_header($auth);
    is_deeply(decode_json(b64url_decode($hdr)), $auth,
        'header roundtrips through base64url + JSON');
};

subtest 'identitytoken auth' => sub {
    my $auth = { identitytoken => 'tok-123', serveraddress => 'ghcr.io' };
    my $hdr = $images->_registry_auth_header($auth);
    is_deeply(decode_json(b64url_decode($hdr)), $auth,
        'identitytoken roundtrips');
};

subtest 'pre-encoded base64-like string passes through' => sub {
    my $pre = 'eyJ1IjoibWUifQ';
    is $images->_registry_auth_header($pre), $pre,
        'string passed through unchanged';
};

subtest 'push() sends X-Registry-Auth via _request' => sub {
    my $docker = $client;

    my $captured;
    my $mock = sub {
        my ($self, $method, $path, %opts) = @_;
        $captured = { method => $method, path => $path, %opts };
        return [];
    };

    no warnings 'redefine';
    local *API::Docker::_request = $mock;

    $docker->images->push(
        'raudssus/karr:user',
        auth => { username => 'u', password => 'p' },
        tag  => 'user',
    );

    is $captured->{method}, 'POST', 'POST issued';
    like $captured->{path}, qr{^/images/raudssus/karr:user/push}, 'push path';
    ok exists $captured->{headers}{'X-Registry-Auth'},
        'X-Registry-Auth header present';
    is_deeply(
        decode_json(b64url_decode($captured->{headers}{'X-Registry-Auth'})),
        { username => 'u', password => 'p' },
        'header decodes to passed credentials',
    );
    is $captured->{params}{tag}, 'user', 'tag param present';
};

done_testing;
