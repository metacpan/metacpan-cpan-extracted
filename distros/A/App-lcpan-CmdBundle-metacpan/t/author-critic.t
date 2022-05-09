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

my $filenames = ['lib/App/lcpan/Cmd/metacpan_author.pm','lib/App/lcpan/Cmd/metacpan_dist.pm','lib/App/lcpan/Cmd/metacpan_mod.pm','lib/App/lcpan/Cmd/metacpan_pod.pm','lib/App/lcpan/Cmd/metacpan_script.pm','lib/App/lcpan/CmdBundle/metacpan.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
