
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/cpandb',
    'lib/CPAN/SQLite.pm',
    'lib/CPAN/SQLite/DBI.pm',
    'lib/CPAN/SQLite/DBI/Index.pm',
    'lib/CPAN/SQLite/DBI/Search.pm',
    'lib/CPAN/SQLite/Index.pm',
    'lib/CPAN/SQLite/Info.pm',
    'lib/CPAN/SQLite/META.pm',
    'lib/CPAN/SQLite/Populate.pm',
    'lib/CPAN/SQLite/Search.pm',
    'lib/CPAN/SQLite/State.pm',
    'lib/CPAN/SQLite/Util.pm',
    't/00-all_prereqs.t',
    't/00-compile.t',
    't/00-compile/lib_CPAN_SQLite_DBI_Index_pm.t',
    't/00-compile/lib_CPAN_SQLite_DBI_Search_pm.t',
    't/00-compile/lib_CPAN_SQLite_DBI_pm.t',
    't/00-compile/lib_CPAN_SQLite_Index_pm.t',
    't/00-compile/lib_CPAN_SQLite_Info_pm.t',
    't/00-compile/lib_CPAN_SQLite_META_pm.t',
    't/00-compile/lib_CPAN_SQLite_Populate_pm.t',
    't/00-compile/lib_CPAN_SQLite_Search_pm.t',
    't/00-compile/lib_CPAN_SQLite_State_pm.t',
    't/00-compile/lib_CPAN_SQLite_Util_pm.t',
    't/00-compile/lib_CPAN_SQLite_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/000-report-versions.t',
    't/01basic.t',
    't/02drop.t',
    't/03info.t',
    't/04search.t',
    't/04search_everything.t',
    't/05meta_new.t',
    't/05meta_update.t',
    't/06retrieve.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-spell.t',
    't/lib/TestSQL.pm',
    't/lib/TestShell.pm',
    't/release-changes_has_content.t',
    't/release-distmeta.t',
    't/release-fixme.t',
    't/release-has-version.t',
    't/release-kwalitee.t',
    't/release-meta-json.t',
    't/release-minimum-version.t',
    't/release-pause-permissions.t',
    't/release-pod-linkcheck.t',
    't/release-pod-syntax.t',
    't/testrules.yml'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
