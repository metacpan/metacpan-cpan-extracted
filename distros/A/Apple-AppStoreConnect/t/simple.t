BEGIN {
    # Mock backticks
    *CORE::GLOBAL::readpipe = sub {
        return '{"data":[{"type":"apps","id":"1","attributes":{"name":"appy"}}]}';
    };
}

use Test2::V0;

use JSON;
use HTTP::Response;
use LWP::UserAgent;
use Apple::AppStoreConnect;

use File::Temp qw/tempfile/;

my %params = (
    issuer => "XXXXXXXXXX",
    key_id => "QX0X0X00XX",
);

my $key = '-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgYirTZSx+5O8Y6tlG
cka6W6btJiocdrdolfcukSoTEk+hRANCAAQkvPNu7Pa1GcsWU4v7ptNfqCJVq8Cx
zo0MUVPQgwJ3aJtNM1QMOQUayCrRwfklg+D/rFSUwEUqtZh7fJDiFqz3
-----END PRIVATE KEY-----';

my $asc  = Apple::AppStoreConnect->new(%params, key => $key);
my $base = $asc->{base_url};

subtest 'base_url' => sub {
    like($base, qr#^http.*v1/#, "Object created with base url");
};

subtest 'jwt' => sub {
    my $jwt = $asc->jwt();

    like($jwt, qr/^ey.*/, 'JWT of expected form');

    my %opt = (
        iat => time(),
        exp => time()+300
    );
    my $jwt2 = $asc->jwt(%opt);

    isnt($jwt, $jwt2, 'Different JWT');
    like($jwt2, qr/^ey.*/, 'Still of expected form');
};

subtest '_build_url' => sub {

    is(Apple::AppStoreConnect::_build_url(url => $base), $base, "Correct URL");

    like(
        Apple::AppStoreConnect::_build_url(
            url    => $base,
            params => {
                p => 1,
                f => "b"
            }
        ),
        qr/$base\?(p=1&f=b|f=b&p=1)/,
        "Correct URL with params"
    );
};

my $json = '{"data":[{"type":"apps","id":"1","attributes":{"name":"appy"}}]}';
my $ref  = JSON::decode_json($json);
my $ref2 = Apple::AppStoreConnect::_process_data($ref);

subtest '_process_data' => sub {
    is($ref2, {1=>{name=>"appy",type=>"apps"}}, "Process data");
    my @tests = (undef, "test", {test=>1}, {data=>1}, {data=>[{}]}, {data=>[{id=>1}]});
    is(Apple::AppStoreConnect::_process_data($_), $_, "Incomplete process")
        for @tests;
};


my $mock = Test2::Mock->new(
    class => 'LWP::UserAgent',
    track => 1,
    override => [
        get => sub { return HTTP::Response->new(200, 'SUCCESS', undef, $json) },
    ],
);

my $expected_obj = array {
    item object {prop blessed => 'LWP::UserAgent'; etc};
    item "${base}apps";
    item 'Authorization';
    item match(qr/^Bearer ey[^.]+\.ey[^.]+\.[^.]+/);
    end
};

subtest 'get' => sub {
    my $out = $asc->get(url => 'apps');
    is($out, $ref, 'Received response');
    is(
        $mock->call_tracking->[0]->{args},
        $expected_obj,
        'get call correct'
    );

    $out = $asc->get(url => $base.'apps');
    is($out, $ref, 'Received response');
    is(
        $mock->call_tracking->[1]->{args},
        $expected_obj,
        'get call correct'
    );

    $out = $asc->get(url => 'apps', params => {foo=>"bar"});
    is($out, $ref, 'Received response');
    is(
        $mock->call_tracking->[2]->{args},
        array {
            item object {prop blessed => 'LWP::UserAgent'; etc};
            item "${base}apps?foo=bar";
            item 'Authorization';
            item match(qr/^Bearer ey[^.]+\.ey[^.]+\.[^.]+/);
            end
        },
        'get call correct with params'
    );

};

subtest 'get_apps' => sub {
    my $out = $asc->get_apps();
    is($out, $ref2, 'Received response');
    is(
        $mock->call_tracking->[3]->{args},
        $expected_obj,
        'get_apps call correct'
    );

    $out = $asc->get_apps(id=>1);
    is($out, $ref2, 'Received response');
    is(
        $mock->call_tracking->[4]->{args},
        array {
            item object {prop blessed => 'LWP::UserAgent'; etc};
            item "${base}apps/1";
            item 'Authorization';
            item match(qr/^Bearer ey[^.]+\.ey[^.]+\.[^.]+/);
            end
        },
        'get_apps call correct with id'
    );

    $out = $asc->get_apps(path=>'builds');
    is($out, $ref2, 'Received response');
    is(
        $mock->call_tracking->[5]->{args},
        array {
            item object {prop blessed => 'LWP::UserAgent'; etc};
            item "${base}apps/builds";
            item 'Authorization';
            item match(qr/^Bearer ey[^.]+\.ey[^.]+\.[^.]+/);
            end
        },
        'get_apps call correct with path'
    );

    $out = $asc->get_apps(id=>1, path=>'builds');
    is($out, $ref2, 'Received response');
    is(
        $mock->call_tracking->[6]->{args},
        array {
            item object {prop blessed => 'LWP::UserAgent'; etc};
            item "${base}apps/1/builds";
            item 'Authorization';
            item match(qr/^Bearer ey[^.]+\.ey[^.]+\.[^.]+/);
            end
        },
        'get_apps call correct with id and path'
    );
};

subtest 'Optional parameters' => sub {
    my ($fh, $filename) = tempfile();
    print $fh $key;
    close $fh;
    my $ua = LWP::UserAgent->new();

    $asc = Apple::AppStoreConnect->new(
        %params,
        key_file   => $filename,
        timeout    => 10,
        expiration => 1000,
        scope      => ["GET /v1/apps?filter[platform]=IOS"],
        ua         => $ua
    );

    my $out = $asc->get(url => 'apps', raw => 1);
    is($out, $json, 'Received JSON response');
    is(
        $mock->call_tracking->[7]->{args},
        array {
            item $ua;
            item "${base}apps";
            item 'Authorization';
            item match(qr/^Bearer ey[^.]+\.ey[^.]+\.[^.]+/);
            end
        },
        'get call correct'
    );
};

subtest 'Test cover' => sub {
    is(Apple::AppStoreConnect::_build_url(url => $base, params=>{}), $base, "Blank params");

    if ($] >= 5.012) {
        my $asc2 = Apple::AppStoreConnect->new(%params, key => $key, curl => 1);
        my $out  = $asc2->get_apps();
        is($out, $ref2, 'Received curl response');

        $json = '"test"';
        $out  = $asc->get_apps();
        is($out, "test", 'No ref response');
    }
};

done_testing;
