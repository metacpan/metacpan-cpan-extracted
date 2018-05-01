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
        'channel=test', 'network=local', 'squash_threshold=1',
        'use_color=0',  'shorten_urls=0' ),
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
        before        => 'before',
        after         => 'after',
        ref           => 'refs/heads/master',
        checkout_sha  => 'checkout',
        user_name     => 'Test User',
        user_username => 'ser',
        project       => {
            name => 'test-repo',
            homepage => 'http://git/test',
        },
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
        '#test Test User',
        'master checkou test-repo',
        '* pushed 2 commits (first 1 follow)',
        '* http://git/test/compare/before...after' )
);

TestBot->expect(
    join( ' ',
        '#test Test User',
        'master b9b5587 test-repo',
        'mod-one file-one rm-one',
        '* Commit three files (add, mod, rm)',
        '* http://git/b9b5587' )
);

$resp = webhook_post(
    {   object_kind   => 'push',
        before        => 'before',
        after         => 'after6',
        ref           => 'refs/heads/master',
        checkout_sha  => 'checkout',
        user_name     => 'Test User',
        user_username => 'ser',
        project       => {
            name => 'test-repo',
            homepage => 'http://git/test',
        },
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
        total_commits_count => 6,
    }
);

is( $resp->code, 202, 'response status is 202' ) or diag $resp->as_string;

TestBot->expect(
    join( ' ',
        '#test Test User',
        'master checkou test-repo',
        '* pushed 6 commits (first 1 follow)',
        '* http://git/test/compare/before...after6' )
);

TestBot->expect(
    join( ' ',
        '#test Test User',
        'master b9b5587 test-repo',
        'mod-one file-one rm-one',
        '* Commit three files (add, mod, rm)',
        '* http://git/b9b5587' )
);

$resp = webhook_post(
    {   object_kind   => 'push',
        before        => 'before',
        after         => 'after6',
        ref           => 'refs/heads/upstream',
        checkout_sha  => 'checkout',
        user_name     => 'Test User',
        user_username => 'ser',
        project       => {
            name => 'test-repo',
            homepage => 'http://git/test',
        },
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
        total_commits_count => 6,
    }
);

is( $resp->code, 202, 'response status is 202' ) or diag $resp->as_string;

TestBot->expect(
    join( ' ',
        '#test Test User',
        'upstream checkou test-repo',
        '* pushed 6 commits',
        '* http://git/test/compare/before...after6' )
);

$webhook_url = sprintf(
    'http://%s:%d/webhook/?%s',
    $test_bot->addr,
    $test_bot->port,
    join( '&',
        'channel=test', 'network=local',
        'use_color=0',  'shorten_urls=0',
        'always_squash_outside_dir=dir', ),
);

$resp = webhook_post(
    {   object_kind   => 'push',
        before        => 'after6',
        after         => 'after7',
        ref           => 'refs/heads/master',
        checkout_sha  => 'checkout',
        user_name     => 'Test User',
        user_username => 'ser',
        project       => {
            name => 'test-repo',
            homepage => 'http://git/test',
        },
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
                added    => [ 'some/file-one', 'file-two.txt' ],
                modified => [ 'some/mod-one',  'mod-two.txt' ],
                removed  => [ 'some/rm-one',   'rm-two.txt' ],
            },
        ],
        total_commits_count => 2,
    }
);

is( $resp->code, 202, 'response status is 202' ) or diag $resp->as_string;

TestBot->expect(
    join( ' ',
        '#test Test User',
        'master test-repo',
        '* 2 commits touching only files outside monitored directories omitted',
    )
);

$resp = webhook_post(
    {   object_kind   => 'push',
        before        => 'after7',
        after         => '284ffdd4c525547f6ae848d768fff92ff9a89743',
        ref           => 'refs/heads/master',
        checkout_sha  => 'checkout',
        user_name     => 'Test User',
        user_username => 'ser',
        project       => {
            name => 'test-repo',
            homepage => 'http://git/test',
        },
        commits       => [
            {   id      => 'b9b55876e288bba29d1579d308eea5758bc148ef',
                message => "Commit three files (add, mod, rm)",
                url => "http://git/b9b55876e288bba29d1579d308eea5758bc148ef",
                author => { name => 'Test User', },
                added    => [ 'dir/file-one' ],
                modified => [ 'dir/mod-one' ],
                removed  => [ 'dir/rm-one' ],
            },
            {   id      => '284ffdd4c525547f6ae848d768fff92ff9a89743',
                message => "Commit six files in dir/ (2×(add, mod, rm))\n\nThese were all needed",
                url => "http://git/284ffdd4c525547f6ae848d768fff92ff9a89743",
                author => { name => 'Test User', },
                added    => [ 'dir/file-one', 'dir/file-two.txt' ],
                modified => [ 'dir/mod-one',  'mod-two.txt' ],
                removed  => [ 'dir/rm-one',   'dir/rm-two.txt' ],
            },
            {   id      => 'a2a7fe7f2d12ee7a1c57ab2f60847778baf66f93',
                message => "This should be omitted",
                url => "http://git/a2a7fe7f2d12ee7a1c57ab2f60847778baf66f93",
                author => { name => 'Test User', },
                added    => [ 'not-dir/file-one', 'file-two.txt' ],
                modified => [ 'mod-one',  'not-dir/mod-two.txt' ],
                removed  => [ 'rm-one',   'rm-two.txt' ],
            },
        ],
        total_commits_count => 3,
    }
);

is( $resp->code, 202, 'response status is 202' ) or diag $resp->as_string;

TestBot->expect(
    join( ' ',
        '#test Test User',
        'master b9b5587 test-repo',
        'dir/ mod-one file-one rm-one * Commit three files (add, mod, rm)',
        '* http://git/b9b5587' )
);

TestBot->expect(
    join( ' ',
        '#test Test User',
        'master 284ffdd test-repo',
        '(6 files in 2 dirs)',
        '* Commit six files in dir/ (2×(add, mod, rm))',
        '* http://git/284ffdd',
    )
);

TestBot->expect(
    join( ' ',
        '#test Test User',
        'master test-repo',
        '* 1 commit touching only files outside monitored directories omitted',
    )
);


diag `cat t/bot/kgb-bot.log`;

my $output = $test_bot->get_output;

undef($test_bot);   # make sure all output us there

eq_or_diff( $output, TestBot->expected_output,
    'bot output matches expecattions' );

done_testing();
