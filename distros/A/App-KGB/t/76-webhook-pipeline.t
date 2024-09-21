use strict;
use warnings;
use utf8;

use autodie qw(:all);
use Test::More;
use Test::Exception;

BEGIN {
    eval { require LWP::UserAgent; 1 }
        or plan skip_all => "LWP::UserAgent is required for testing webhooks";
}

use lib 't';
use TestBot;

use App::KGB::Change;
use File::Temp qw(tempdir);
use File::Spec;
use JSON qw(to_json);
use Test::Differences;

unified_diff();

use utf8;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my $tmp_cleanup = not $ENV{TEST_KEEP_TMP};
my $dir = tempdir(
    'kgb-XXXXXXX',
    CLEANUP => $tmp_cleanup,
    DIR     => File::Spec->tmpdir
);
diag "Temp directory $dir will be kept" unless $tmp_cleanup;

my $test_bot = TestBot->start;

use Cwd;
my $R = getcwd;

my $ua = LWP::UserAgent->new();
my $webhook_url = sprintf(
    'http://%s:%d/webhook/?%s',
    $test_bot->addr,
    $test_bot->port,
    join( '&',
        'channel=test', 'network=dummy',
        'use_color=0',  'pipeline_only_status=success',
        'pipeline_only_status=failed' )
);

sub webhook_post {
    return $ua->post(
        $webhook_url,
        'Content-Type' => 'text/json',
        Content        => to_json( shift, { utf8 => 1 } ),
    );
}

my $resp = webhook_post(
    {   object_kind => 'pipeline',
        user        => { name => 'Test User' },
        project     => { name => 'test-repo', },
        object_attributes =>
            { id => 42, status => 'created' },
    }
);

is( $resp->code, 202, 'pipeline event response status is 202' )
    or diag $resp->as_string;

$resp = webhook_post(
    {   object_kind => 'pipeline',
        user        => { name => 'Test User' },
        project     => { name => 'test-repo', },
        object_attributes =>
            { id => 42, status => 'success', duration => 3665, },
    }
);

is( $resp->code, 202, 'pipeline event response status is 202' )
    or diag $resp->as_string;

TestBot->expect(
    join( ' ',
        'dummy/#test test-repo',
        'pipeline',
        'Test User',
        '42',
        '* [1 hour, 1 minute and 5 seconds] success',
    )
);

$resp = webhook_post(
    {   object_kind => 'pipeline',
        user        => { name => 'Test User' },
        project     => { name => 'test-rep', },
        object_attributes =>
            { id => 43, status => 'success', duration => 3666, },
        builds => [
            { name => 'staging',     status => 'created' },
            { name => 'build-image', status => 'success' },
        ],
    }
);

is( $resp->code, 202, 'pipeline event response status is 202' ) or diag $resp->as_string;

TestBot->expect(
    join( ' ',
        'dummy/#test test-rep',
        'pipeline',
        'Test User',
        '43',
        '* [1 hour, 1 minute and 6 seconds] success (staging: created; build-image: success)',
    )
);

$resp = webhook_post(
    {   object_kind => 'pipeline',
        user        => { name => 'Test User' },
        project     => { name => 'test-rep', },
        object_attributes =>
            { id => 44, status => 'failed' },
    }
);

is( $resp->code, 202, 'pipeline event response status is 202' ) or diag $resp->as_string;

TestBot->expect(
    join( ' ',
        'dummy/#test test-rep',
        'pipeline',
        'Test User',
        '44',
        '* failed',
    )
);

$resp = webhook_post(
    {   object_kind => 'pipeline',
        user        => { name => 'Test User' },
        project     => { name => 'test-rep', namespace => 'TestBot' },
        object_attributes =>
            { id => 45, status => 'failed', duration => 3666, },
        builds => [
            { name => 'pad',                     status => 'success' },
            { name => 'staging',                 status => 'created' },
            { name => 'build-image',             status => 'success' },
            { name => 'flake8',                  status => 'success' },
            { name => 'check-salsaci-overrides', status => 'success' },
            { name => 'extract-source',          status => 'success' },
            { name => 'nosetests',               status => 'success' },
            { name => 'piuparts',                status => 'skipped' },
            { name => 'blhc',                    status => 'skipped' },
            { name => 'black',                   status => 'success' },
            { name => 'mypy',                    status => 'failed' },
            { name => 'test-build-any',          status => 'skipped' },
            { name => 'build source',            status => 'success' },
            { name => 'build i386',              status => 'failed' },
            { name => 'test-build-all',          status => 'skipped' },
            { name => 'reprotest',               status => 'skipped' },
            { name => 'lintian',                 status => 'skipped' },
            { name => 'autopkgtest',             status => 'skipped' },
            { name => 'build',                   status => 'failed' },
        ],
    }
);

is( $resp->code, 202, 'pipeline event response status is 202' ) or diag $resp->as_string;

TestBot->expect(
    join( ' ',
        'dummy/#test test-rep',
        'pipeline',
        'Test User',
        '45',
        '* [1 hour, 1 minute and 6 seconds] failed (pad: success; staging: created; build-image: success; flake8: success; check-salsaci-overrides: success; extract-source: success; nosetests: success; piuparts: skipped; blhc: skipped; black: success; mypy: failed; test-build-any: skipped; build source: success; build i386: failed; test-build-all: skipped; reprot'
    )
);
TestBot->expect(
    join( ' ',
        'dummy/#test',
        'est: skipped; lintian: skipped; autopkgtest: skipped; build: failed)',
    )
);

diag `cat t/bot/kgb-bot.log`;

$test_bot->stop;   # make sure all output is there

my $output = $test_bot->get_output;

eq_or_diff( $output, TestBot->expected_output );

done_testing();
