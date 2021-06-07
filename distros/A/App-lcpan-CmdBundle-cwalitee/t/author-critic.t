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

my $filenames = ['lib/App/lcpan/Cmd/cwalitee_of_module_abstract.pm','lib/App/lcpan/Cmd/cwalitee_of_release_changes.pm','lib/App/lcpan/Cmd/cwalitee_of_script_abstract.pm','lib/App/lcpan/Cmd/cwalitees_of_modules_abstracts.pm','lib/App/lcpan/Cmd/cwalitees_of_scripts_abstracts.pm','lib/App/lcpan/Cmd/dists_with_changes_cwalitee.pm','lib/App/lcpan/Cmd/mods_with_abstract_cwalitee.pm','lib/App/lcpan/CmdBundle/cwalitee.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
