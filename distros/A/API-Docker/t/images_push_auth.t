use strict;
use warnings;
use Test::More;
use JSON::MaybeXS qw( decode_json );
use MIME::Base64 qw( decode_base64 decode_base64url );

use API::Docker::API::Images;

sub b64url_decode {
    my ($s) = @_;
    $s =~ tr{-_}{+/};
    my $pad = (4 - length($s) % 4) % 4;
    $s .= '=' x $pad;
    return decode_base64($s);
}

subtest 'empty/undef auth -> base64url("{}")' => sub {
    my $hdr = API::Docker::API::Images::_build_registry_auth_header(undef);
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
    my $hdr = API::Docker::API::Images::_build_registry_auth_header($auth);
    is_deeply(decode_json(b64url_decode($hdr)), $auth,
        'header roundtrips through base64url + JSON');
};

subtest 'identitytoken auth' => sub {
    my $auth = { identitytoken => 'tok-123', serveraddress => 'ghcr.io' };
    my $hdr = API::Docker::API::Images::_build_registry_auth_header($auth);
    is_deeply(decode_json(b64url_decode($hdr)), $auth,
        'identitytoken roundtrips');
};

subtest 'pre-encoded base64-like string passes through' => sub {
    my $pre = 'eyJ1IjoibWUifQ';
    is API::Docker::API::Images::_build_registry_auth_header($pre), $pre,
        'string passed through unchanged';
};

subtest 'push() sends X-Registry-Auth via _request' => sub {
    require API::Docker;
    my $docker = API::Docker->new(
        host        => 'unix:///dev/null',
        api_version => '1.47',
    );

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
