#!perl

use strict;
use warnings;
use FindBin;

use lib "$FindBin::Bin/lib";

use Test::More;

use Path::Tiny ();

use App::Critique::Tester;

BEGIN {
    use_ok('App::Critique');
    use_ok('App::Critique::Session');
}

my $TEST_REPO = App::Critique::Tester::init_test_repo();

subtest '... testing session with a simple git repo' => sub {

    my $s = App::Critique::Session->new(
        git_work_tree => $TEST_REPO->dir
    );
    isa_ok($s, 'App::Critique::Session');

    isa_ok($s->git_work_tree, 'Path::Tiny');
    is($s->git_work_tree->stringify, $TEST_REPO->dir, '... got the git work tree we expected');

    is($s->git_branch, 'master', '... got the git branch we expected');

    is($s->perl_critic_policy,  undef, '... no perl critic policy');
    is($s->perl_critic_theme,   undef, '... no perl critic theme');
    is($s->perl_critic_profile, undef, '... no perl critic profile');

    is_deeply([$s->tracked_files], [], '... no tracked files');

    is($s->current_file_idx, 0, '... current file index is 0');

    ok(!$s->session_file_exists, '... the session file does not yet exist');

    isa_ok($s->session_file_path, 'Path::Tiny');
    is(
        $s->session_file_path->stringify,
        Path::Tiny::path( $App::Critique::CONFIG{'HOME'} )
            ->child( '.critique' )
            ->child( Path::Tiny::path( $TEST_REPO->dir )->basename )
            ->child( 'master' )
            ->child( 'session.json' )
            ->stringify,
        '... got the expected session file path'
    );

    is_deeply(
        $s->pack,
        {
            perl_critic_profile => undef,
            perl_critic_theme   => undef,
            perl_critic_policy  => undef,
            git_work_tree       => $TEST_REPO->dir,
            git_branch          => 'master',
            current_file_idx    => 0,
            tracked_files       => [],
            file_criteria       => {},
        },
        '... got the expected values from pack'
    );

};

App::Critique::Tester::teardown_test_repo( $TEST_REPO );

done_testing;

