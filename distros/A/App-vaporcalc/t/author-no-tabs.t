
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/vaporcalc',
    'lib/App/vaporcalc.pm',
    'lib/App/vaporcalc/Cmd/Result.pm',
    'lib/App/vaporcalc/Cmd/Subject/Flavor.pm',
    'lib/App/vaporcalc/Cmd/Subject/Help.pm',
    'lib/App/vaporcalc/Cmd/Subject/NicBase.pm',
    'lib/App/vaporcalc/Cmd/Subject/NicTarget.pm',
    'lib/App/vaporcalc/Cmd/Subject/NicType.pm',
    'lib/App/vaporcalc/Cmd/Subject/Notes.pm',
    'lib/App/vaporcalc/Cmd/Subject/Pg.pm',
    'lib/App/vaporcalc/Cmd/Subject/Recipe.pm',
    'lib/App/vaporcalc/Cmd/Subject/TargetAmount.pm',
    'lib/App/vaporcalc/Cmd/Subject/Vg.pm',
    'lib/App/vaporcalc/CmdEngine.pm',
    'lib/App/vaporcalc/Exception.pm',
    'lib/App/vaporcalc/Flavor.pm',
    'lib/App/vaporcalc/FormatString.pm',
    'lib/App/vaporcalc/Recipe.pm',
    'lib/App/vaporcalc/RecipeResultSet.pm',
    'lib/App/vaporcalc/Result.pm',
    'lib/App/vaporcalc/Role/Calc.pm',
    'lib/App/vaporcalc/Role/Store.pm',
    'lib/App/vaporcalc/Role/UI/Cmd.pm',
    'lib/App/vaporcalc/Role/UI/ParseCmd.pm',
    'lib/App/vaporcalc/Role/UI/PrepareCmd.pm',
    'lib/App/vaporcalc/Types.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/author-synopsis.t',
    't/lib/cmd/result.t',
    't/lib/cmd/subject/flavor.t',
    't/lib/cmd/subject/help.t',
    't/lib/cmd/subject/nicbase.t',
    't/lib/cmd/subject/nictarget.t',
    't/lib/cmd/subject/nictype.t',
    't/lib/cmd/subject/notes.t',
    't/lib/cmd/subject/pg.t',
    't/lib/cmd/subject/recipe.t',
    't/lib/cmd/subject/targetamount.t',
    't/lib/cmd/subject/vg.t',
    't/lib/cmdengine.t',
    't/lib/exception.t',
    't/lib/flavor.t',
    't/lib/formatstring.t',
    't/lib/recipe.t',
    't/lib/reciperesultset.t',
    't/lib/result.t',
    't/lib/types.t',
    't/lib/vaporcalc.t',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-pod-linkcheck.t',
    't/role/calc.pm',
    't/role/store.t',
    't/role/ui/cmd.t',
    't/role/ui/parsecmd.t',
    't/role/ui/preparecmd.t'
);

notabs_ok($_) foreach @files;
done_testing;
