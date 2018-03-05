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
my $webhook_url =
    sprintf( 'http://%s:%d/webhook/?channel=test&network=local&use_color=0',
    $test_bot->addr, $test_bot->port );

sub webhook_post {
    my $response = $ua->post(
        $webhook_url,
        'Content-Type' => 'text/json',
        Content        => to_json(shift, {utf8=>1}),
    );
}

my $resp = webhook_post(
    {   object_kind   => 'push',
        before        => 'before',
        after         => 'after',
        ref           => 'refs/heads/master',
        checkout_sha  => 'checkout',
        user_name     => 'Test User',
        user_username => 'ser',
        user_email    => 'test@user',
        project       => {
            name => 'test-repo',
            homepage => 'http://git/test',
        },
        commits       => [
            {   id      => 'b9b55876e288bba29d1579d308eea5758bc148ef',
                message => "Commit three files (add, mod, rm)",
                url => "http://git/b9b55876e288bba29d1579d308eea5758bc148ef",
                author => { name => 'Test Author', email => 'test@author' },
                added    => [ 'file-one' ],
                modified => [ 'mod-one' ],
                removed  => [ 'rm-one' ],
            },
        ],
    }
);

is( $resp->code, 202, 'response status is 202' ) or diag $resp->as_string;

TestBot->expect(
    join( ' ',
        '#test Test Author (via Test User)',
        'master b9b5587 test-repo',
        'mod-one file-one rm-one',
        '* Commit three files (add, mod, rm)',
        '* http://git/b9b5587' )
);

diag `cat t/bot/kgb-bot.log`;

my $output = $test_bot->get_output;

undef($test_bot);   # make sure all output us there

eq_or_diff( $output, TestBot->expected_output );

done_testing();
