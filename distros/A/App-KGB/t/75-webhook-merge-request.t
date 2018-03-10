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
my $webhook_url =
    sprintf( 'http://%s:%d/webhook/?channel=test&network=local&use_color=0',
    $test_bot->addr, $test_bot->port );

sub webhook_post {
    return $ua->post(
        $webhook_url,
        'Content-Type' => 'text/json',
        Content        => to_json( shift, { utf8 => 1 } ),
    );
}

my $resp = webhook_post(
    {   object_kind       => 'merge_request',
        user              => { name => 'Test User' },
        project           => { name => 'test-repo', },
        object_attributes => {
            id            => 4242,
            iid           => 42,
            target_branch => "nevermore",
            action        => 'open',
            url           => 'http://git/merge_requests/42',
        },
    }
);

is( $resp->code, 202, 'commit note event response status is 202' ) or diag $resp->as_string;

TestBot->expect(
    join( ' ',
        '#test Test User',
        'nevermore test-repo',
        '!42',
        '* open of merge request !42',
        '* http://git/merge_requests/42',
    )
);

diag `cat t/bot/kgb-bot.log`;

$test_bot->stop;   # make sure all output is there

my $output = $test_bot->get_output;

eq_or_diff( $output, TestBot->expected_output );

done_testing();
