use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
