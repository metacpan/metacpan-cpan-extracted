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

my $filenames = ['lib/App/ModuleUtils.pm','lib/App/PMUtils.pm','lib/App/pmgrep.pm','script/module-dir','script/pmabstract','script/pmbin','script/pmcat','script/pmchkver','script/pmcore','script/pmcost','script/pmdir','script/pmdoc','script/pmedit','script/pmgrep','script/pmhtml','script/pminfo','script/pmlatest','script/pmless','script/pmlines','script/pmlist','script/pmman','script/pmminversion','script/pmpath','script/pmstripper','script/pmuninst','script/pmunlink','script/pmversion','script/pmxs','script/podlist','script/podpath','script/pwd2mod','script/rel2mod'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
