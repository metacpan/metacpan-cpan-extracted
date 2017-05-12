#!/usr/bin/perl

use strict;
use warnings;

use autodie;

use File::Spec;

use Test::More tests => 6;

use Test::Differences qw( eq_or_diff );

use App::Du::Analyze::Filter;

# TEST:$test_filter_on_fc_solve=1;
sub test_filter_on_fc_solve
{
    my ($options, $expected_output, $blurb) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $obj = App::Du::Analyze::Filter->new($options);

    open my $in_fh, '<:encoding(utf8)', File::Spec->catfile(File::Spec->curdir, 't', 'data', 'fc-solve-git-du-output.txt');

    my $buffer = '';
    open my $out_fh, '>', \$buffer;

    $obj->filter($in_fh, $out_fh);

    close($in_fh);
    close($out_fh);

    return eq_or_diff(
        $buffer,
        $expected_output,
        $blurb,
    );
}

{

    # TEST*$test_filter_on_fc_solve
    test_filter_on_fc_solve(
        {
            prefix => '',
            depth => 0,
        },
        <<"EOF", "depth 0 and no prefix",
119224\t
EOF
    );

    # TEST*$test_filter_on_fc_solve
    test_filter_on_fc_solve(
        {
            prefix => 'fc-solve',
            depth => 0,
        },
        <<"EOF", "depth 0 and specified prefix",
52532\tfc-solve
EOF
    );

    # TEST*$test_filter_on_fc_solve
    test_filter_on_fc_solve(
        {
            prefix => 'fc-solve',
            depth => 1,
        },
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
        {
            prefix => '',
            depth => 1,
        },
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
        {
            prefix => '',
            depth => 2,
        },
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
        {
            prefix => 'fc-solve/source',
            depth => 2,
        },
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

