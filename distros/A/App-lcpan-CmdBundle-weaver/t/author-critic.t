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

my $filenames = ['lib/App/lcpan/Cmd/weaver_authors_by_bundle_count.pm','lib/App/lcpan/Cmd/weaver_authors_by_plugin_count.pm','lib/App/lcpan/Cmd/weaver_authors_by_role_count.pm','lib/App/lcpan/Cmd/weaver_authors_by_section_count.pm','lib/App/lcpan/Cmd/weaver_bundle.pm','lib/App/lcpan/Cmd/weaver_bundles.pm','lib/App/lcpan/Cmd/weaver_bundles_by_rdep_count.pm','lib/App/lcpan/Cmd/weaver_plugin.pm','lib/App/lcpan/Cmd/weaver_plugins.pm','lib/App/lcpan/Cmd/weaver_plugins_by_rdep_count.pm','lib/App/lcpan/Cmd/weaver_role.pm','lib/App/lcpan/Cmd/weaver_roles.pm','lib/App/lcpan/Cmd/weaver_roles_by_rdep_count.pm','lib/App/lcpan/Cmd/weaver_section.pm','lib/App/lcpan/Cmd/weaver_sections.pm','lib/App/lcpan/Cmd/weaver_sections_by_rdep_count.pm','lib/App/lcpan/CmdBundle/weaver.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
