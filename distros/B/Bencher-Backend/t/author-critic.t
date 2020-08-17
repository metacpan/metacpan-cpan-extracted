#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.005

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Bencher/Backend.pm','lib/Bencher/Formatter.pm','lib/Bencher/Formatter/AddComparisonFields.pm','lib/Bencher/Formatter/CodeStartup.pm','lib/Bencher/Formatter/DeleteConstantFields.pm','lib/Bencher/Formatter/DeleteNotesFieldIfEmpty.pm','lib/Bencher/Formatter/DeleteSeqField.pm','lib/Bencher/Formatter/ModuleStartup.pm','lib/Bencher/Formatter/RenderAsTextTable.pm','lib/Bencher/Formatter/RoundNumbers.pm','lib/Bencher/Formatter/ScaleRate.pm','lib/Bencher/Formatter/ScaleSize.pm','lib/Bencher/Formatter/ScaleTime.pm','lib/Bencher/Formatter/ShowEnv.pm','lib/Bencher/Formatter/Sort.pm','lib/Bencher/Role/FieldMunger.pm','lib/Bencher/Role/ResultMunger.pm','lib/Bencher/Role/ResultRenderer.pm','lib/Bencher/Scenario/Example.pm','lib/Bencher/Scenario/Example/CmdLineTemplate.pm','lib/Bencher/Scenario/Example/CommandNotFound.pm','lib/Bencher/Scenario/Example/MultipleArgValues/Array.pm','lib/Bencher/Scenario/Example/MultipleArgValues/Hash.pm','lib/Benchmark/Dumb/SimpleTime.pm','lib/Sah/Schema/bencher/scenario.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
