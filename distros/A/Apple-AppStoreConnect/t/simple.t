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

{
    package TestUA;

    sub new {
        my $class = shift;
        return bless {responses => [@_], calls => []}, $class;
    }

    sub get {
        my $self = shift;
        push @{$self->{calls}}, [@_];
        return HTTP::Response->new(200, 'SUCCESS', undef, shift @{$self->{responses}});
    }
}

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

    $out = $asc->get_apps(platform=>'IOS');
    is($out, $ref2, 'Received response');
    is(
        $mock->call_tracking->[7]->{args},
        array {
            item object {prop blessed => 'LWP::UserAgent'; etc};
            item "${base}apps?filter[platform]=IOS";
            item 'Authorization';
            item match(qr/^Bearer ey[^.]+\.ey[^.]+\.[^.]+/);
            end
        },
        'get_apps call correct with platform'
    );
};

subtest 'Optional parameters' => sub {
    my ($fh, $filename) = tempfile();
    print $fh $key;
    close $fh;
    my $ua = LWP::UserAgent->new();

    $asc = Apple::AppStoreConnect->new(
        %params,
        key_file    => $filename,
        timeout     => 10,
        expiration  => 1000,
        scope       => ["GET /v1/apps?filter[platform]=IOS"],
        ua          => $ua,
        jwt_payload => {bid => 'com.Id.Bundle'}
    );

    my $out = $asc->get(url => 'apps', raw => 1);
    is($out, $json, 'Received JSON response');
    is(
        $mock->call_tracking->[8]->{args},
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

subtest 'get_app_store_versions' => sub {
    my $ua = TestUA->new(
        '{"data":[{"type":"appStoreVersions","id":"v1","attributes":{"versionString":"1.0","platform":"IOS"}}],"links":{"next":"'.$base.'apps/1/appStoreVersions?cursor=abc"}}',
        '{"data":[{"type":"appStoreVersions","id":"v2","attributes":{"versionString":"1.1","platform":"IOS"}}]}',
        '{"data":[{"type":"appStoreVersionLocalizations","id":"l1","attributes":{"locale":"en-US","whatsNew":"One"}},{"type":"appStoreVersionLocalizations","id":"l2","attributes":{"locale":"fr-FR","whatsNew":"Un"}}]}',
        '{"data":[]}'
    );
    my $asc3 = Apple::AppStoreConnect->new(%params, key => $key, ua => $ua);

    my $out = $asc3->get_app_store_versions(
        id            => 1,
        platform      => 'IOS',
        localizations => 1,
    );

    is(
        $out,
        [
            {
                id            => 'v1',
                type          => 'appStoreVersions',
                versionString => '1.0',
                platform      => 'IOS',
                localizations => [
                    {
                        id       => 'l1',
                        type     => 'appStoreVersionLocalizations',
                        locale   => 'en-US',
                        whatsNew => 'One',
                    },
                    {
                        id       => 'l2',
                        type     => 'appStoreVersionLocalizations',
                        locale   => 'fr-FR',
                        whatsNew => 'Un',
                    },
                ],
            },
            {
                id            => 'v2',
                type          => 'appStoreVersions',
                versionString => '1.1',
                platform      => 'IOS',
                localizations => [],
            },
        ],
        'Versions and localizations returned'
    );

    like(
        $ua->{calls}->[0]->[0],
        qr#^\Q${base}apps/1/appStoreVersions\E\?(limit=200&filter\[platform\]=IOS|filter\[platform\]=IOS&limit=200)$#,
        'Version request uses platform filter and limit'
    );
    is(
        $ua->{calls}->[1]->[0],
        "${base}apps/1/appStoreVersions?cursor=abc",
        'Version request follows next link'
    );
    is(
        $ua->{calls}->[2]->[0],
        "${base}appStoreVersions/v1/appStoreVersionLocalizations?limit=200",
        'Localizations request fetches all locales'
    );
    is(
        $ua->{calls}->[3]->[0],
        "${base}appStoreVersions/v2/appStoreVersionLocalizations?limit=200",
        'Localizations request is made for each version'
    );
};

subtest 'get_app_store_versions with locale' => sub {
    my $ua = TestUA->new(
        '{"data":[{"type":"appStoreVersions","id":"v1","attributes":{"versionString":"1.0"}}]}',
        '{"data":[{"type":"appStoreVersionLocalizations","id":"l1","attributes":{"locale":"en-US","whatsNew":"One"}}]}'
    );
    my $asc3 = Apple::AppStoreConnect->new(%params, key => $key, ua => $ua);

    my $out = $asc3->get_app_store_versions(id => 1, localizations => 'en-US');

    is(
        $out->[0]->{localizations},
        [
            {
                id       => 'l1',
                type     => 'appStoreVersionLocalizations',
                locale   => 'en-US',
                whatsNew => 'One',
            },
        ],
        'Only requested locale returned'
    );
    like(
        $ua->{calls}->[1]->[0],
        qr#^\Q${base}appStoreVersions/v1/appStoreVersionLocalizations\E\?(limit=200&filter\[locale\]=en-US|filter\[locale\]=en-US&limit=200)$#,
        'Locale filter passed to localizations request'
    );
};

subtest 'get_app_store_versions localization fields' => sub {
    my $ua = TestUA->new(
        '{"data":[{"type":"appStoreVersions","id":"v1","attributes":{"versionString":"1.0"}}]}',
        '{"data":[{"type":"appStoreVersionLocalizations","id":"l1","attributes":{"locale":"en-US","whatsNew":"One"}}]}'
    );
    my $asc3 = Apple::AppStoreConnect->new(%params, key => $key, ua => $ua);

    my $out = $asc3->get_app_store_versions(
        id                  => 1,
        localization_fields => 'locale,whatsNew',
    );

    is(
        $out->[0]->{localizations},
        [
            {
                id       => 'l1',
                type     => 'appStoreVersionLocalizations',
                locale   => 'en-US',
                whatsNew => 'One',
            },
        ],
        'Localization fields imply localizations'
    );
    like(
        $ua->{calls}->[1]->[0],
        qr#^\Q${base}appStoreVersions/v1/appStoreVersionLocalizations\E\?(limit=200&fields\[appStoreVersionLocalizations\]=locale,whatsNew|fields\[appStoreVersionLocalizations\]=locale,whatsNew&limit=200)$#,
        'Localization fields passed to localizations request'
    );
};

subtest 'get_beta_feedback_screenshot_submissions' => sub {
    my $ua = TestUA->new(
        '{"data":[{"type":"betaFeedbackScreenshotSubmissions","id":"s1","attributes":{"createdDate":"2026-06-24T10:00:00Z","comment":"Looks wrong","appPlatform":"IOS","screenshots":[{"url":"https://example.com/shot.png","width":1170,"height":2532}]}}]}'
    );
    my $asc3 = Apple::AppStoreConnect->new(%params, key => $key, ua => $ua);

    my $out = $asc3->get_beta_feedback_screenshot_submissions(
        id       => 1,
        platform => 'IOS',
        params   => {
            'fields[betaFeedbackScreenshotSubmissions]' => 'createdDate,comment,appPlatform,screenshots',
        },
    );

    is(
        $out,
        [
            {
                id          => 's1',
                type        => 'betaFeedbackScreenshotSubmissions',
                createdDate => '2026-06-24T10:00:00Z',
                comment     => 'Looks wrong',
                appPlatform => 'IOS',
                screenshots => [
                    {
                        url    => 'https://example.com/shot.png',
                        width  => 1170,
                        height => 2532,
                    },
                ],
            },
        ],
        'Screenshot feedback returned'
    );

    my $url = $ua->{calls}->[0]->[0];
    like($url, qr#^\Q${base}apps/1/betaFeedbackScreenshotSubmissions\E\?#, 'Screenshot request URL');
    like($url, qr/(?:^|[?&])filter\[appPlatform\]=IOS(?:&|$)/, 'Screenshot request uses app platform filter');
    like($url, qr/(?:^|[?&])limit=50(?:&|$)/, 'Screenshot request defaults limit');
    like($url, qr/(?:^|[?&])sort=-createdDate(?:&|$)/, 'Screenshot request defaults newest first');
    like(
        $url,
        qr/(?:^|[?&])fields\[betaFeedbackScreenshotSubmissions\]=createdDate,comment,appPlatform,screenshots(?:&|$)/,
        'Screenshot request passes fields'
    );
};

subtest 'get_beta_feedback_crash_submissions' => sub {
    my $ua = TestUA->new(
        '{"data":[{"type":"betaFeedbackCrashSubmissions","id":"c1","attributes":{"createdDate":"2026-06-24T11:00:00Z","comment":"Crashed","deviceModel":"iPhone16,2"}}]}',
        '{"data":{"type":"betaCrashLogs","id":"cl1","attributes":{"logText":"stack trace"}}}'
    );
    my $asc3 = Apple::AppStoreConnect->new(%params, key => $key, ua => $ua);

    my %request_params = (
        'fields[betaFeedbackCrashSubmissions]' => 'createdDate,comment,deviceModel',
        'fields[betaCrashLogs]'                => 'logText',
    );
    my $out = $asc3->get_beta_feedback_crash_submissions(
        id        => 1,
        limit     => 25,
        crash_log => 1,
        params    => \%request_params,
    );

    is(
        $out,
        [
            {
                id          => 'c1',
                type        => 'betaFeedbackCrashSubmissions',
                createdDate => '2026-06-24T11:00:00Z',
                comment     => 'Crashed',
                deviceModel => 'iPhone16,2',
                crashLog    => {
                    id      => 'cl1',
                    type    => 'betaCrashLogs',
                    logText => 'stack trace',
                },
            },
        ],
        'Crash feedback with crash log returned'
    );

    my $list_url = $ua->{calls}->[0]->[0];
    like($list_url, qr#^\Q${base}apps/1/betaFeedbackCrashSubmissions\E\?#, 'Crash request URL');
    like($list_url, qr/(?:^|[?&])limit=25(?:&|$)/, 'Crash request uses limit');
    like($list_url, qr/(?:^|[?&])sort=-createdDate(?:&|$)/, 'Crash request defaults newest first');
    like(
        $list_url,
        qr/(?:^|[?&])fields\[betaFeedbackCrashSubmissions\]=createdDate,comment,deviceModel(?:&|$)/,
        'Crash request passes fields'
    );
    unlike($list_url, qr/fields\[betaCrashLogs\]/, 'Crash log fields not passed to list endpoint');
    is(
        $ua->{calls}->[1]->[0],
        "${base}betaFeedbackCrashSubmissions/c1/crashLog?fields[betaCrashLogs]=logText",
        'Crash log request passes crash log fields'
    );
    is(
        \%request_params,
        {
            'fields[betaFeedbackCrashSubmissions]' => 'createdDate,comment,deviceModel',
            'fields[betaCrashLogs]'                => 'logText',
        },
        'Caller params are not modified'
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
