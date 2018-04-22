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
my $webhook_url = sprintf(
    'http://%s:%d/webhook/?%s',
    $test_bot->addr,
    $test_bot->port,
    join( '&',
        'channel=test',   'network=local',
        'shorten_urls=0', 'only_branch=master',
        "only_branch=old_branch" )
);

sub webhook_post {
    my $response = $ua->post(
        $webhook_url,
        'Content-Type' => 'text/json',
        Content        => to_json(shift, {utf8=>1}),
    );
}

my $resp = webhook_post(
    {   object_kind   => 'push',
        ref           => 'refs/heads/master',
        user_name     => 'Unused Test User',
        user_username => 'ser',
        project       => { name => 'test-repo', },
        after         => '284ffdd4c525547f6ae848d768fff92ff9a89743',
        commits       => [
            {   id      => 'b9b55876e288bba29d1579d308eea5758bc148ef',
                message => "Commit three files (add, mod, rm)",
                url => "http://git/b9b55876e288bba29d1579d308eea5758bc148ef",
                author => { name => 'Test User', },
                added    => [ 'file-one' ],
                modified => [ 'mod-one' ],
                removed  => [ 'rm-one' ],
            },
            {   id      => '284ffdd4c525547f6ae848d768fff92ff9a89743',
                message => "Commit six files (2×(add, mod, rm))\n\nThese were all needed",
                url => "http://git/284ffdd4c525547f6ae848d768fff92ff9a89743",
                author => { name => 'Test User', },
                added    => [ 'file-one', 'file-two.txt' ],
                modified => [ 'mod-one',  'mod-two.txt' ],
                removed  => [ 'rm-one',   'rm-two.txt' ],
            },
        ],
    }
);

is( $resp->code, 202, 'response status is 202' ) or diag $resp->as_string;

TestBot->expect(
    join( ' ',
        '#test 03Test User',
        '05master b9b5587 06test-repo',
        '10mod-one 03file-one 04rm-one',
        '* Commit three files (add, mod, rm)',
        '* 14http://git/b9b5587' )
);

TestBot->expect(
    join( ' ',
        '#test 03Test User',
        '05master 284ffdd 06test-repo',
        '10(6 files)',
        '* Commit six files (2×(add, mod, rm))',
        '* 14http://git/284ffdd' )
);

$resp = webhook_post(
    {   object_kind   => 'push',
        ref           => 'refs/heads/old_branch',
        user_name     => 'Test User',
        user_username => 'ser',
        project       => { name => 'test-repo', },
        before        => '284ffdd4c525547f6ae848d768fff92ff9a89743',
        after         => '0000000000000000000000000000000000000000',
        commits       => [ ],
    }
);

is( $resp->code, 202, 'response status is 202' ) or diag $resp->as_string;

TestBot->expect(
    join( ' ',
        '#test 03Test User',
        '05old_branch 284ffdd 06test-repo',
        '04.',
        '* branch deleted' )
);

# a push outside the designated branch

$resp = webhook_post(
    {   object_kind   => 'push',
        ref           => 'refs/heads/random-branch',
        user_name     => 'Test User',
        user_username => 'ser',
        project       => { name => 'test-repo', },
        before        => '284ffdd4c525547f6ae848d768fff92ff9a89743',
        after         => '2189572634934075403487349534879534875349',
        commits       => [
            {   id      => 'b9b55876e288bba29d1579d308eea5758bc148ef',
                message => "Commit three files (add, mod, rm)",
                url => "http://git/b9b55876e288bba29d1579d308eea5758bc148ef",
                author => { name => 'Test User', },
                added    => [ 'file-one' ],
                modified => [ 'mod-one' ],
                removed  => [ 'rm-one' ],
            },
            {   id      => '284ffdd4c525547f6ae848d768fff92ff9a89743',
                message => "Commit six files (2×(add, mod, rm))\n\nThese were all needed",
                url => "http://git/284ffdd4c525547f6ae848d768fff92ff9a89743",
                author => { name => 'Test User', },
                added    => [ 'file-one', 'file-two.txt' ],
                modified => [ 'mod-one',  'mod-two.txt' ],
                removed  => [ 'rm-one',   'rm-two.txt' ],
            },
        ],
    }
);

is( $resp->code, 202, 'response status is 202' ) or diag $resp->as_string;

diag `cat t/bot/kgb-bot.log`;

my $output = $test_bot->get_output;

undef($test_bot);   # make sure all output us there

eq_or_diff( $output, TestBot->expected_output );

done_testing();
