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

my $filenames = ['lib/App/FilterOrgByHeadlines.pm','lib/App/ListOrgAnniversaries.pm','lib/App/ListOrgHeadlines.pm','lib/App/ListOrgHeadlinesFast.pm','lib/App/ListOrgTodos.pm','lib/App/OrgUtils.pm','script/browse-org','script/count-done-org-todos','script/count-org-headlines-fast','script/count-org-todos','script/count-org-todos-fast','script/count-undone-org-todos','script/dump-org-structure','script/dump-org-structure-tiny','script/filter-org-by-headlines','script/list-org-anniversaries','script/list-org-headlines','script/list-org-headlines-fast','script/list-org-priorities','script/list-org-tags','script/list-org-todo-states','script/list-org-todos','script/list-org-todos-fast','script/move-done-todos','script/org-to-html','script/org-to-html-wordpress','script/org2html','script/org2html-wp','script/reverse-org-headlines','script/sort-org-headlines','script/stat-org-document'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
