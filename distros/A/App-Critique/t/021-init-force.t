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
            qr/perl_critic_policy\s+\= Variables\:\:ProhibitUnusedVariables/,
            qr/Successuflly created session/,
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

subtest '... testing status' => sub {

    my ($out, $err) = App::Critique::Tester::test(
        [
            status => (
                '-v',
                '--git-work-tree', $work_tree,
            )
        ],
        [
            qr/Session file loaded/,
            qr/perl_critic_policy\s+\= Variables\:\:ProhibitUnusedVariables/,
            qr/git_work_tree\s*\= $work_tree/,
            qr/TOTAL\: 0 file\(s\)/,
            qr/\.critique\/$work_base\/master\/session\.json/,
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

subtest '... testing init (w/out force)' => sub {

    my ($out, $err) = App::Critique::Tester::test(
        [
            init => (
                '-v',
                '--git-work-tree', $work_tree,
                '--perl-critic-policy', 'Variables::ProhibitReusedNames' # << this is different
            )
        ],
        [
            qr/Attempting to initialize session file/,
            qr/\-\-perl\-critic\-policy\s+\= Variables\:\:ProhibitReusedNames/,
            qr/perl_critic_policy\s+\= Variables\:\:ProhibitReusedNames/,
            qr/Successuflly created session/,
            qr/git_work_tree\s+\= $work_tree/,
            qr/Unable to overwrite session file \(.*\) without \-\-force option/,
            qr/\.critique\/$work_base\/master\/session\.json/,
        ],
        [
            qr/Overwriting session file/,
            qr/Session file \(.*\) initialized successfully/,
            qr/Unable to store session file/,
        ]
    );

    # warn '-' x 80;
    # warn $out;
    # warn '-' x 80;
    # warn $err;
    # warn '-' x 80;
};

subtest '... testing init (w/ force)' => sub {

    my ($out, $err) = App::Critique::Tester::test(
        [
            init => (
                '-v',
                '--git-work-tree', $work_tree,
                '--perl-critic-policy', 'Variables::ProhibitReusedNames', # << this is different
                '--force'
            )
        ],
        [
            qr/Attempting to initialize session file/,
            qr/\-\-perl\-critic\-policy\s+\= Variables\:\:ProhibitReusedNames/,
            qr/perl_critic_policy\s+\= Variables\:\:ProhibitReusedNames/,
            qr/Successuflly created session/,
            qr/git_work_tree\s+\= $work_tree/,
            qr/Session file \(.*\) initialized successfully/,
            qr/Overwriting session file \(.*\) with \-\-force option/,
            qr/\.critique\/$work_base\/master\/session\.json/,
        ],
        [
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

subtest '... testing status' => sub {

    my ($out, $err) = App::Critique::Tester::test(
        [
            status => (
                '-v',
                '--git-work-tree', $work_tree,
            )
        ],
        [
            qr/Session file loaded/,
            qr/perl_critic_policy\s+\= Variables\:\:ProhibitReusedNames/,
            qr/git_work_tree\s*\= $work_tree/,
            qr/TOTAL\: 0 file\(s\)/,
            qr/\.critique\/$work_base\/master\/session\.json/,
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

