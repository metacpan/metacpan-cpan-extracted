use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/App/DH.pm',
    't/00-compile/lib_App_DH_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t',
    't/corpus/ddl/SQLite/deploy/1/001-auto-__VERSION.sql',
    't/corpus/ddl/SQLite/deploy/1/001-auto.sql',
    't/corpus/ddl/SQLite/deploy/2/001-auto-__VERSION.sql',
    't/corpus/ddl/SQLite/deploy/2/001-auto.sql',
    't/corpus/ddl/SQLite/deploy/3/001-auto-__VERSION.sql',
    't/corpus/ddl/SQLite/deploy/3/001-auto.sql',
    't/corpus/ddl/SQLite/upgrade/1-2/001-auto.sql',
    't/corpus/ddl/SQLite/upgrade/2-3/001-auto.sql',
    't/corpus/ddl/_source/deploy/1/001-auto-__VERSION.yml',
    't/corpus/ddl/_source/deploy/1/001-auto.yml',
    't/corpus/ddl/_source/deploy/2/001-auto-__VERSION.yml',
    't/corpus/ddl/_source/deploy/2/001-auto.yml',
    't/corpus/ddl/_source/deploy/3/001-auto-__VERSION.yml',
    't/corpus/ddl/_source/deploy/3/001-auto.yml',
    't/corpus/lib/MySchema.pm',
    't/corpus/lib/MySchema/Result/Kitten.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
