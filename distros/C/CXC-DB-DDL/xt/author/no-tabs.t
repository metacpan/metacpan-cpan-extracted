use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/CXC/DB/DDL.pm',
    'lib/CXC/DB/DDL/CloneClear.pm',
    'lib/CXC/DB/DDL/Constants.pm',
    'lib/CXC/DB/DDL/Failure.pm',
    'lib/CXC/DB/DDL/Field.pm',
    'lib/CXC/DB/DDL/FieldType.pm',
    'lib/CXC/DB/DDL/Manual/Intro.pod',
    'lib/CXC/DB/DDL/Table.pm',
    'lib/CXC/DB/DDL/Types.pm',
    'lib/CXC/DB/DDL/Util.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/DDL/Util.t',
    't/DDL/Util/dbd_types.t',
    't/DDL/create.t',
    't/lib/DBD/MyTestDBD.pm',
    't/lib/My/Field.pm'
);

notabs_ok($_) foreach @files;
done_testing;
