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

my $filenames = ['lib/Data/Sah/Coerce/perl/To_date/From_str/flexible.pm','lib/Data/Sah/Coerce/perl/To_date/From_str/flexible_jakarta.pm','lib/Data/Sah/Coerce/perl/To_date/From_str/flexible_local.pm','lib/Data/Sah/Coerce/perl/To_date/From_str/flexible_utc.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
