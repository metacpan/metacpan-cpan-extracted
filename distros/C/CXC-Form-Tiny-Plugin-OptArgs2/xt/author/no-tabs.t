use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/CXC/Form/Tiny/Plugin/OptArgs2.pm',
    'lib/CXC/Form/Tiny/Plugin/OptArgs2/Class.pm',
    'lib/CXC/Form/Tiny/Plugin/OptArgs2/Meta.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/OptArgs.t',
    't/data/cscquery.csc',
    't/lib/My/Test/AutoCleanHash.pm',
    't/nested.t',
    't/required.t'
);

notabs_ok($_) foreach @files;
done_testing;
