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
diag "Temp directory $dir will pe kept" unless $tmp_cleanup;

my $test_bot = TestBot->start;

use Cwd;
my $R = getcwd;

my $ua = LWP::UserAgent->new();
my $webhook_url = sprintf(
    'http://%s:%d/webhook/?%s',
    $test_bot->addr,
    $test_bot->port,
    join( '&',
        'channel=test', 'network=local',
        'use_color=0',  'pipeline_only_status=success',
        'pipeline_only_status=failure' )
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

my $resp = webhook_post(
    {   object_kind => 'pipeline',
        user        => { name => 'Test User' },
        project     => { name => 'test-repo', },
        object_attributes =>
            { id => 42, status => 'success', duration => 3665, },
    }
);

is( $resp->code, 202, 'pipeline event response status is 202' ) or diag $resp->as_string;

TestBot->expect(
    join( ' ',
        '#test Test User',
        'pipeline',
        'test-repo',
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
        '#test Test User',
        'pipeline',
        'test-rep',
        '43',
        '* [1 hour, 1 minute and 6 seconds] success (staging: created; build-image: success)',
    )
);

$resp = webhook_post(
    {   object_kind => 'pipeline',
        user        => { name => 'Test User' },
        project     => { name => 'test-rep', },
        object_attributes =>
            { id => 43, status => 'failure' },
    }
);

is( $resp->code, 202, 'pipeline event response status is 202' ) or diag $resp->as_string;

TestBot->expect(
    join( ' ',
        '#test Test User',
        'pipeline',
        'test-rep',
        '43',
        '* failure',
    )
);


diag `cat t/bot/kgb-bot.log`;

$test_bot->stop;   # make sure all output is there

my $output = $test_bot->get_output;

eq_or_diff( $output, TestBot->expected_output );

done_testing();
