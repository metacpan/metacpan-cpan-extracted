use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/cpan-changes-markdown',
    'lib/CPAN/Changes/Markdown.pm',
    'lib/CPAN/Changes/Markdown/Filter.pm',
    'lib/CPAN/Changes/Markdown/Filter/Node/DelimitedText.pm',
    'lib/CPAN/Changes/Markdown/Filter/Node/PlainText.pm',
    'lib/CPAN/Changes/Markdown/Filter/NodeUtil.pm',
    'lib/CPAN/Changes/Markdown/Filter/Passthrough.pm',
    'lib/CPAN/Changes/Markdown/Filter/Rule/NumericsToCode.pm',
    'lib/CPAN/Changes/Markdown/Filter/Rule/PackageNamesToCode.pm',
    'lib/CPAN/Changes/Markdown/Filter/Rule/UnderscoredToCode.pm',
    'lib/CPAN/Changes/Markdown/Filter/Rule/VersionsToCode.pm',
    'lib/CPAN/Changes/Markdown/Filter/RuleUtil.pm',
    'lib/CPAN/Changes/Markdown/Role/Filter.pm',
    'lib/CPAN/Changes/Markdown/Role/Filter/Node.pm',
    'lib/CPAN/Changes/Markdown/Role/Filter/Rule.pm',
    'lib/CPAN/Changes/Markdown/Role/Filter/Rule/PlainText.pm',
    't/00-compile/lib_CPAN_Changes_Markdown_Filter_NodeUtil_pm.t',
    't/00-compile/lib_CPAN_Changes_Markdown_Filter_Node_DelimitedText_pm.t',
    't/00-compile/lib_CPAN_Changes_Markdown_Filter_Node_PlainText_pm.t',
    't/00-compile/lib_CPAN_Changes_Markdown_Filter_Passthrough_pm.t',
    't/00-compile/lib_CPAN_Changes_Markdown_Filter_RuleUtil_pm.t',
    't/00-compile/lib_CPAN_Changes_Markdown_Filter_Rule_NumericsToCode_pm.t',
    't/00-compile/lib_CPAN_Changes_Markdown_Filter_Rule_PackageNamesToCode_pm.t',
    't/00-compile/lib_CPAN_Changes_Markdown_Filter_Rule_UnderscoredToCode_pm.t',
    't/00-compile/lib_CPAN_Changes_Markdown_Filter_Rule_VersionsToCode_pm.t',
    't/00-compile/lib_CPAN_Changes_Markdown_Filter_pm.t',
    't/00-compile/lib_CPAN_Changes_Markdown_Role_Filter_Node_pm.t',
    't/00-compile/lib_CPAN_Changes_Markdown_Role_Filter_Rule_PlainText_pm.t',
    't/00-compile/lib_CPAN_Changes_Markdown_Role_Filter_Rule_pm.t',
    't/00-compile/lib_CPAN_Changes_Markdown_Role_Filter_pm.t',
    't/00-compile/lib_CPAN_Changes_Markdown_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/filter_numeric.t',
    't/filter_package_name.t',
    't/filter_stacked.t',
    't/filter_underscore.t',
    't/filter_version.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
