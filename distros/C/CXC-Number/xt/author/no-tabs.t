use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/CXC/Number.pm',
    'lib/CXC/Number/Grid.pm',
    'lib/CXC/Number/Grid/Failure.pm',
    'lib/CXC/Number/Grid/Role/BigNum.pm',
    'lib/CXC/Number/Grid/Role/PDL.pm',
    'lib/CXC/Number/Grid/Types.pm',
    'lib/CXC/Number/Sequence.pm',
    'lib/CXC/Number/Sequence/Failure.pm',
    'lib/CXC/Number/Sequence/Fixed.pm',
    'lib/CXC/Number/Sequence/Linear.pm',
    'lib/CXC/Number/Sequence/Ratio.pm',
    'lib/CXC/Number/Sequence/Role/BigNum.pm',
    'lib/CXC/Number/Sequence/Role/PDL.pm',
    'lib/CXC/Number/Sequence/Types.pm',
    'lib/CXC/Number/Sequence/Utils.pm',
    'lib/CXC/Number/Types.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/Grid/edges.t',
    't/Grid/interface.t',
    't/Grid/join.t',
    't/Grid/overlay.t',
    't/Grid/regressions.t',
    't/Grid/select.t',
    't/Grid/split.t',
    't/Sequence/Fixed/sequence.t',
    't/Sequence/Linear/interface.t',
    't/Sequence/Linear/sequence.t',
    't/Sequence/Ratio/interface.t',
    't/Sequence/Ratio/sequence.t',
    't/Sequence/Types.t',
    't/Sequence/interface.t',
    't/lib/My/Sequence/Fails.pm',
    't/lib/My/Sequence/Lives.pm'
);

notabs_ok($_) foreach @files;
done_testing;
