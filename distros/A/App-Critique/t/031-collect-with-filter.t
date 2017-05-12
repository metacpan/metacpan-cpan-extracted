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

my $test_repo = App::Critique::Tester::init_test_repo();
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

subtest '... testing collect' => sub {

    my ($out, $err) = App::Critique::Tester::test(
        [
            collect => (
                '-v',
                '--git-work-tree', $work_tree,
                '--filter', '^t\/',
            )
        ],
        [
            qr/Session file loaded/,
            qr/Matched\: keeping file \(bin\/my-app\)/,
            qr/Matched\: keeping file \(lib\/My\/Test\/WithoutViolations\.pm\)/,
            qr/Matched\: keeping file \(lib\/My\/Test\/WithViolations\.pm\)/,
            qr/Matched\: keeping file \(share\/debug.pl\)/,
            qr/Matched\: keeping file \(root\/app\.psgi\)/,
            qr/Not Matched\: skipping file \(t\/000\-test\-with\-violations\.t\)/,
            qr/Not Matched\: skipping file \(t\/001\-test\-without-violations\.t\)/,
            qr/Collected 5 perl file\(s\) for critique/,
            qr/Including bin\/my-app/,
            qr/Including lib\/My\/Test\/WithoutViolations\.pm/,
            qr/Including lib\/My\/Test\/WithViolations\.pm/,
            qr/Including share\/debug\.pl/,
            qr/Sucessfully added 5 file\(s\)/,
            qr/Session file stored successfully/,
            qr/\.critique\/$work_base\/master\/session\.json/,
        ],
        [
            qr/Unable to load session file/,
            qr/Unable to store session file/,
            qr/Shuffling file list/,
            qr/\[dry run\]/,
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
            qr/perl_critic_policy\s+\: Variables\:\:ProhibitUnusedVariables/,
            qr/git_work_tree\s*\: $work_tree/,
                qr/bin\/my-app/,
                qr/lib\/My\/Test\/WithoutViolations\.pm/,
                qr/lib\/My\/Test\/WithViolations\.pm/,
                qr/root\/app\.psgi/,
                qr/share\/debug\.pl/,
            qr/TOTAL\: 5 file\(s\)/,
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

