use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/optimize-game-ai-multi-tasking',
    'lib/AI/Pathfinding/OptimizeMultiple.pm',
    'lib/AI/Pathfinding/OptimizeMultiple/App/CmdLine.pm',
    'lib/AI/Pathfinding/OptimizeMultiple/DataInputObj.pm',
    'lib/AI/Pathfinding/OptimizeMultiple/IterState.pm',
    'lib/AI/Pathfinding/OptimizeMultiple/PostProcessor.pm',
    'lib/AI/Pathfinding/OptimizeMultiple/Scan.pm',
    'lib/AI/Pathfinding/OptimizeMultiple/ScanRun.pm',
    'lib/AI/Pathfinding/OptimizeMultiple/SimulationResults.pm',
    't/00-compile.t',
    't/cmdline-app.t',
    't/optimize-multiple-full-test.t',
    't/style-trailing-space.t'
);

notabs_ok($_) foreach @files;
done_testing;
