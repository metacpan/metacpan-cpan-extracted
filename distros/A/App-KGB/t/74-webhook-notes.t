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
        'channel=test', 'network=dummy', 'use_color=0', 'shorten_urls=0' )
);

sub webhook_post {
    return $ua->post(
        $webhook_url,
        'Content-Type' => 'text/json',
        Content        => to_json( shift, { utf8 => 1 } ),
    );
}

my $resp = webhook_post(
    {   object_kind       => 'note',
        user              => { name => 'Test User' },
        project           => { name => 'test-repo', },
        object_attributes => {
            id     => 42,
            note   => "This is a commit comment",
            noteable_type => 'Commit',
            url    => 'http://git/commits/424242424242#note42',
        },
        commit => {
            id => '424242424242',
        },
    }
);

is( $resp->code, 202, 'commit note event response status is 202' ) or diag $resp->as_string;

TestBot->expect(
    join( ' ',
        'dummy/#test Test User',
        'test-repo',
        '42',
        '* commented commit 4242424',
        '* http://git/commits/424242424242#note42',
    )
);

$resp = webhook_post(
    {   object_kind       => 'note',
        user              => { name => 'Test User' },
        project           => { name => 'test-repo', },
        object_attributes => {
            id     => 42,
            note   => "This is a merge request comment",
            noteable_type => 'MergeRequest',
            url    => 'http://git/merge_requests/4242#note42',
        },
        merge_request => { id => 424242, iid => 4242 },
    }
);

is( $resp->code, 202, 'merge request note event response status is 202' ) or diag $resp->as_string;

TestBot->expect(
    join( ' ',
        'dummy/#test Test User',
        'test-repo',
        '42',
        '* commented merge request !4242',
        '* http://git/merge_requests/4242#note42',
    )
);

$resp = webhook_post(
    {   object_kind       => 'note',
        user              => { name => 'Test User' },
        project           => { name => 'test-repo', },
        object_attributes => {
            id     => 42,
            note   => "This is an issue comment",
            noteable_type => 'Issue',
            url    => 'http://git/issues/4242#note42',
        },
        issue => { id => 424242, iid => 4242 },
    }
);

is( $resp->code, 202, 'issue note event response status is 202' ) or diag $resp->as_string;

TestBot->expect(
    join( ' ',
        'dummy/#test Test User',
        'test-repo',
        '42',
        '* commented issue #4242',
        '* http://git/issues/4242#note42',
    )
);

$resp = webhook_post(
    {   object_kind       => 'note',
        user              => { name => 'Test User' },
        project           => { name => 'test-repo', },
        object_attributes => {
            id     => 42,
            note   => "This is a code snippet comment",
            noteable_type => 'Snippet',
            url    => 'http://git/snippets/4242#note42',
        },
        snippet => { id => 4242 },
    }
);

is( $resp->code, 202, 'code snippet note event response status is 202' ) or diag $resp->as_string;

TestBot->expect(
    join( ' ',
        'dummy/#test Test User',
        'test-repo',
        '42',
        '* commented snippet #4242',
        '* http://git/snippets/4242#note42',
    )
);

diag `cat t/bot/kgb-bot.log`;

$test_bot->stop;   # make sure all output is there

my $output = $test_bot->get_output;

eq_or_diff( $output, TestBot->expected_output );

done_testing();
