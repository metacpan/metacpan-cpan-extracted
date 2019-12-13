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

my $filenames = ['lib/Data/Unixish.pm','lib/Data/Unixish/Apply.pm','lib/Data/Unixish/Util.pm','lib/Data/Unixish/_pad.pm','lib/Data/Unixish/avg.pm','lib/Data/Unixish/bool.pm','lib/Data/Unixish/cat.pm','lib/Data/Unixish/centerpad.pm','lib/Data/Unixish/chain.pm','lib/Data/Unixish/cond.pm','lib/Data/Unixish/count.pm','lib/Data/Unixish/date.pm','lib/Data/Unixish/grep.pm','lib/Data/Unixish/head.pm','lib/Data/Unixish/indent.pm','lib/Data/Unixish/join.pm','lib/Data/Unixish/lc.pm','lib/Data/Unixish/lcfirst.pm','lib/Data/Unixish/lins.pm','lib/Data/Unixish/linum.pm','lib/Data/Unixish/lpad.pm','lib/Data/Unixish/ltrim.pm','lib/Data/Unixish/map.pm','lib/Data/Unixish/num.pm','lib/Data/Unixish/pick.pm','lib/Data/Unixish/rand.pm','lib/Data/Unixish/randstr.pm','lib/Data/Unixish/rev.pm','lib/Data/Unixish/rins.pm','lib/Data/Unixish/rpad.pm','lib/Data/Unixish/rtrim.pm','lib/Data/Unixish/shuf.pm','lib/Data/Unixish/sort.pm','lib/Data/Unixish/splice.pm','lib/Data/Unixish/split.pm','lib/Data/Unixish/sprintf.pm','lib/Data/Unixish/sprintfn.pm','lib/Data/Unixish/subsort.pm','lib/Data/Unixish/sum.pm','lib/Data/Unixish/tail.pm','lib/Data/Unixish/trim.pm','lib/Data/Unixish/trunc.pm','lib/Data/Unixish/uc.pm','lib/Data/Unixish/ucfirst.pm','lib/Data/Unixish/wc.pm','lib/Data/Unixish/wrap.pm','lib/Data/Unixish/yes.pm','lib/Test/Data/Unixish.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
