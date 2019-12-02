#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.003

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Data/Sah/Coerce/perl/To_float/From_str/num_id.pm','lib/Data/Sah/Coerce/perl/To_int/From_str/num_id.pm','lib/Data/Sah/Coerce/perl/To_num/From_str/num_id.pm','lib/Data/Sah/CoerceBundle/To_num/From_str/num_id.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
