#!/usr/bin/perl

use strict;
use warnings;

use autodie;

use File::Spec;

use Test::More tests => 12;

use Test::Differences qw( eq_or_diff );

use Test::Trap qw( trap $trap :flow:stderr(systemsafe):stdout(systemsafe):warn );

use App::Du::Analyze;
my $input_filename = File::Spec->catfile(File::Spec->curdir, 't', 'data', 'fc-solve-git-du-output.txt');

# TEST:$test_filter_on_fc_solve__proto=1;
sub test_filter_on_fc_solve__proto
{
    my ($args, $expected_output, $blurb) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    trap
    {
        App::Du::Analyze->new({argv => [@$args]})->run();
    };

    my $got_output = $trap->stdout;

    return eq_or_diff(
        $got_output,
        $expected_output,
        $blurb,
    );
}

# TEST:$test_filter_on_fc_solve=0;
sub test_filter_on_fc_solve
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($args, $expected_output, $blurb) = @_;

    {
        local $ENV{ANALYZE_DU_INPUT_FN} = $input_filename;
        # TEST:$test_filter_on_fc_solve+=$test_filter_on_fc_solve__proto;
        test_filter_on_fc_solve__proto(
            $args,
            $expected_output,
            "$blurb - ENV",
        );
    }

    {
        # TEST:$test_filter_on_fc_solve+=$test_filter_on_fc_solve__proto;
        test_filter_on_fc_solve__proto([ @$args, $input_filename],
            $expected_output,
            "$blurb - arg",
        );
    }
}

{

    # TEST*$test_filter_on_fc_solve
    test_filter_on_fc_solve(
        [ '-p', '', '-d', 0, ],
        <<"EOF", "depth 0 and no prefix",
119224\t
EOF
    );

    # TEST*$test_filter_on_fc_solve
    test_filter_on_fc_solve(
        [ '-p', 'fc-solve', '-d', 0, ],
        <<"EOF", "depth 0 and specified prefix",
52532\tfc-solve
EOF
    );

    # TEST*$test_filter_on_fc_solve
    test_filter_on_fc_solve(
        [ '-p', 'fc-solve', '-d', 1, ],
        <<"EOF", "depth 1 and specified prefix",
16\tfc-solve/tests
120\tfc-solve/docs
172\tfc-solve/scripts
232\tfc-solve/arch_doc
276\tfc-solve/rejects
392\tfc-solve/benchmarks
2920\tfc-solve/site
4192\tfc-solve/source
44208\tfc-solve/presets
EOF
    );

    # TEST*$test_filter_on_fc_solve
    test_filter_on_fc_solve(
        [ '-p', '', '-d', 1, ],
        <<"EOF", "depth 1 and an empty prefix",
72\tTask-FreecellSolver-Testing
172\text-ifaces
6900\twww-solitaire
7512\tcpan
52012\t.git
52532\tfc-solve
EOF
    );

    # TEST*$test_filter_on_fc_solve
    test_filter_on_fc_solve(
        [ '-p', '', '-d', 2, ],
        <<"EOF", "depth greater than 1 and an empty prefix",
4\t.git/branches
8\t.git/info
16\text-ifaces/kpat
16\tfc-solve/tests
16\tTask-FreecellSolver-Testing/lib
28\tTask-FreecellSolver-Testing/t
40\t.git/hooks
120\tfc-solve/docs
152\text-ifaces/FC-Pro
168\tcpan/AI-Pathfinding-OptimizeMultiple
172\tfc-solve/scripts
232\tfc-solve/arch_doc
276\tfc-solve/rejects
392\tfc-solve/benchmarks
868\tcpan/Games-Solitaire-Verify
944\t.git/logs
980\t.git/refs
2920\tfc-solve/site
4192\tfc-solve/source
6472\tcpan/temp-AI-Pathfinding-OptimizeMultiple-system-tests
6892\twww-solitaire/js-freecell
44208\tfc-solve/presets
49780\t.git/objects
EOF
    );

    # TEST*$test_filter_on_fc_solve
    test_filter_on_fc_solve(
        [ '-p', 'fc-solve/source', '-d', 2, ],
        <<"EOF", "depth greater than 1 and a prefix",
8\tfc-solve/source/t/dbm
8\tfc-solve/source/t/old-t
8\tfc-solve/source/t/scripts
8\tfc-solve/source/t/config
8\tfc-solve/source/scripts/gdb
8\tfc-solve/source/scripts/cmake_pgo_wrapper
24\tfc-solve/source/scripts/old
32\tfc-solve/source/scripts/parallel-solve-setup-here
64\tfc-solve/source/Presets/testing-presets
116\tfc-solve/source/Presets/presets
1008\tfc-solve/source/t/t
EOF
    );
}

