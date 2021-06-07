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

my $filenames = ['lib/App/PDRUtils.pm','lib/App/PDRUtils/Cmd.pm','lib/App/PDRUtils/DistIniCmd.pm','lib/App/PDRUtils/DistIniCmd/_modify_prereq_version.pm','lib/App/PDRUtils/DistIniCmd/add_prereq.pm','lib/App/PDRUtils/DistIniCmd/dec_prereq_version_by.pm','lib/App/PDRUtils/DistIniCmd/dec_prereq_version_to.pm','lib/App/PDRUtils/DistIniCmd/inc_prereq_version_by.pm','lib/App/PDRUtils/DistIniCmd/inc_prereq_version_to.pm','lib/App/PDRUtils/DistIniCmd/list_prereqs.pm','lib/App/PDRUtils/DistIniCmd/remove_prereq.pm','lib/App/PDRUtils/DistIniCmd/set_prereq_version_to.pm','lib/App/PDRUtils/DistIniCmd/sort_prereqs.pm','lib/App/PDRUtils/MultiCmd.pm','lib/App/PDRUtils/MultiCmd/add_prereq.pm','lib/App/PDRUtils/MultiCmd/dec_prereq_version_by.pm','lib/App/PDRUtils/MultiCmd/dec_prereq_version_to.pm','lib/App/PDRUtils/MultiCmd/inc_prereq_version_by.pm','lib/App/PDRUtils/MultiCmd/inc_prereq_version_to.pm','lib/App/PDRUtils/MultiCmd/ls.pm','lib/App/PDRUtils/MultiCmd/remove_prereq.pm','lib/App/PDRUtils/MultiCmd/set_prereq_version_to.pm','lib/App/PDRUtils/MultiCmd/sort_prereqs.pm','lib/App/PDRUtils/SingleCmd.pm','lib/App/PDRUtils/SingleCmd/add_prereq.pm','lib/App/PDRUtils/SingleCmd/dec_prereq_version_by.pm','lib/App/PDRUtils/SingleCmd/dec_prereq_version_to.pm','lib/App/PDRUtils/SingleCmd/inc_prereq_version_by.pm','lib/App/PDRUtils/SingleCmd/inc_prereq_version_to.pm','lib/App/PDRUtils/SingleCmd/list_prereqs.pm','lib/App/PDRUtils/SingleCmd/remove_prereq.pm','lib/App/PDRUtils/SingleCmd/set_prereq_version_to.pm','lib/App/PDRUtils/SingleCmd/sort_prereqs.pm','script/pdrutil','script/pdrutil-multi'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
