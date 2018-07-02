
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/bp_pairwise_kaks',
    'lib/Bio/Tools/Phylo/PAML.pm',
    'lib/Bio/Tools/Phylo/PAML/Codeml.pm',
    'lib/Bio/Tools/Phylo/PAML/ModelResult.pm',
    'lib/Bio/Tools/Phylo/PAML/Result.pm',
    'lib/Bio/Tools/Run/Phylo/PAML/Baseml.pm',
    'lib/Bio/Tools/Run/Phylo/PAML/Codeml.pm',
    'lib/Bio/Tools/Run/Phylo/PAML/Evolver.pm',
    'lib/Bio/Tools/Run/Phylo/PAML/Yn00.pm',
    't/00-compile.t',
    't/PAML-parser.t',
    't/PAML-run.t',
    't/author-eol.t',
    't/author-mojibake.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
