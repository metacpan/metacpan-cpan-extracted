#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.006

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Bencher/Scenario/Data/Sah/Coerce.pm','lib/Bencher/Scenario/Data/Sah/Startup.pm','lib/Bencher/Scenario/Data/Sah/Validate.pm','lib/Bencher/Scenario/Data/Sah/extract_subschemas.pm','lib/Bencher/Scenario/Data/Sah/gen_coercer.pm','lib/Bencher/Scenario/Data/Sah/gen_validator.pm','lib/Bencher/Scenario/Data/Sah/normalize_schema.pm','lib/Bencher/Scenarios/Data/Sah.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
