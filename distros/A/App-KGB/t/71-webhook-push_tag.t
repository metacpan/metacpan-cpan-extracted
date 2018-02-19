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
my $dir = tempdir( 'kgb-XXXXXXX', CLEANUP => $tmp_cleanup, DIR => File::Spec->tmpdir );
diag "Temp directory $dir will pe kept" unless $tmp_cleanup;

my $test_bot = TestBot->start;

use Cwd;
my $R = getcwd;

my $ua = LWP::UserAgent->new();
my $webhook_url = sprintf( 'http://%s:%d/webhook/?channel=test&network=local&use_color=0',
    $test_bot->addr, $test_bot->port );

sub webhook_post {
    my $response = $ua->post(
        $webhook_url,
        'Content-Type' => 'text/json',
        Content        => to_json(shift, {utf8=>1}),
    );
}

my $resp = webhook_post(
    {   object_kind => 'tag_push',
        ref         => 'refs/tags/v5.6-plus',
        after       => '27d883571554c18752189ae4394b3640239b4fc9',
        user_name   => 'Test User',
        project     => { name => 'test-repo', },
    }
);

is( $resp->code, 202, 'response status is 202' ) or diag $resp->as_string;

TestBot->expect(
    join( ' ',
        '#test Test User',
        'tags 27d8835 test-repo',
        'v5.6-plus',
    )
);

$resp = webhook_post(
    {   object_kind => 'tag_push',
        ref         => 'refs/tags/v5.8-plus',
        after       => '470fc2f92766368cd72e2796db89360fe8e81637',
        message     => <<EOT,
Tagging v5.8-plus
-----BEGIN PGP SIGNATURE-----

adjlidwelifdjelifjselijflseif
EOT
        user_name => 'Test User',
        project => { name => 'test-repo', homepage => 'http://git/project', },
    }
);

TestBot->expect(
    join( ' ',
        '#test Test User',
        'signed-tags 470fc2f test-repo',
        'v5.8-plus',
        '* Tagging v5.8-plus',
        '* http://git/project/tags/v5.8-plus',
    )
);

is( $resp->code, 202, 'response status is 202' ) or diag $resp->as_string;

diag `cat t/bot/kgb-bot.log`;

my $output = $test_bot->get_output;

undef($test_bot);   # make sure all output us there

eq_or_diff( $output, TestBot->expected_output );

done_testing();
