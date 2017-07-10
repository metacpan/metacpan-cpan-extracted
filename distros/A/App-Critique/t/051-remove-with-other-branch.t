#!perl

use strict;
use warnings;
use FindBin;

use lib "$FindBin::Bin/lib";

use Test::More;

use App::Critique::Tester;

BEGIN {
    use_ok('App::Critique');
}

my $test_repo = App::Critique::Tester::init_test_env();
my $work_tree = $test_repo->dir;
my $work_base = Path::Tiny::path( $work_tree )->basename;

subtest '... testing init' => sub {

    my ($out, $err) = App::Critique::Tester::test(
        [
            init => (
                '-v',
                '--git-work-tree', $work_tree,
                '--perl-critic-policy', 'Variables::ProhibitUnusedVariables'
            )
        ],
        [
            qr/Attempting to initialize session file/,
            qr/\-\-perl\-critic\-policy\s+\= Variables\:\:ProhibitUnusedVariables/,
            qr/Successuflly created session/,
            qr/perl_critic_policy\s+\= Variables\:\:ProhibitUnusedVariables/,
            qr/git_branch\s+\= master/,
            qr/git_work_tree\s+\= $work_tree/,
            qr/Session file \(.*\) initialized successfully/,
            qr/\.critique\/$work_base\/master\/session\.json/,
        ],
        [
            qr/Overwriting session file/,
            qr/Unable to overwrite session file/,
            qr/Unable to store session file/,
        ]
    );

    # warn '-' x 80;
    # warn $out;
    # warn '-' x 80;
    # warn $err;
    # warn '-' x 80;
};

$test_repo->checkout({ b => 'test-branch-001' });

subtest '... testing init on new branch' => sub {

    my ($out, $err) = App::Critique::Tester::test(
        [
            init => (
                '-v',
                '--git-work-tree', $work_tree,
                '--perl-critic-policy', 'Variables::ProhibitReusedNames'
            )
        ],
        [
            qr/Attempting to initialize session file/,
            qr/\-\-perl\-critic\-policy\s+\= Variables\:\:ProhibitReusedNames/,
            qr/Successuflly created session/,
            qr/perl_critic_policy\s+\= Variables\:\:ProhibitReusedNames/,
            qr/git_branch\s+\= test-branch-001/,
            qr/git_work_tree\s+\= $work_tree/,
            qr/Session file \(.*\) initialized successfully/,
            qr/\.critique\/$work_base\/test-branch-001\/session\.json/,
        ],
        [
            qr/Overwriting session file/,
            qr/Unable to overwrite session file/,
            qr/Unable to store session file/,
        ]
    );

    # warn '-' x 80;
    # warn $out;
    # warn '-' x 80;
    # warn $err;
    # warn '-' x 80;
};

subtest '... testing remove' => sub {

    my ($out, $err) = App::Critique::Tester::test(
        [
            remove => (
                '-v',
                '--git-work-tree', $work_tree,
            )
        ],
        [
            qr/Attempting to remove session file/,
            qr/Successfully removed session file/,
                qr/\.critique\/$work_base\/test-branch-001\/session\.json/,
            qr/Attempting to remove empty branch directory/,
            qr/Successfully removed empty branch directory/,
                qr/\.critique\/$work_base\/test-branch-001/,
            qr/Branch directory (.*) is not empty, it will not be removed/,
            qr/Repo directory (.*) contains\:/,
                qr/\.critique\/$work_base\/master/,
        ],
        [
            qr/Unable to load session file/,
            qr/Unable to store session file/,
        ]
    );

    # warn '-' x 80;
    # warn $out;
    # warn '-' x 80;
    # warn $err;
    # warn '-' x 80;
};

$test_repo->checkout('master');

subtest '... testing remove' => sub {

    my ($out, $err) = App::Critique::Tester::test(
        [
            remove => (
                '-v',
                '--git-work-tree', $work_tree,
            )
        ],
        [
            qr/Attempting to remove session file/,
            qr/Successfully removed session file/,
                qr/\.critique\/$work_base\/master\/session\.json/,
            qr/Attempting to remove empty branch directory/,
            qr/Successfully removed empty branch directory/,
                qr/\.critique\/$work_base\/master/,
            qr/Attempting to remove empty repo directory/,
            qr/Successfully removed empty repo directory/,
                qr/\.critique\/$work_base/,
        ],
        [
            qr/Unable to load session file/,
            qr/Unable to store session file/,
        ]
    );

    # warn '-' x 80;
    # warn $out;
    # warn '-' x 80;
    # warn $err;
    # warn '-' x 80;
};


App::Critique::Tester::teardown_test_repo( $test_repo );

done_testing;

