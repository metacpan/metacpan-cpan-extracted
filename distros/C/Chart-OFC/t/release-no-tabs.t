
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.06

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Chart/OFC.pm',
    'lib/Chart/OFC/Axis.pm',
    'lib/Chart/OFC/AxisLabel.pm',
    'lib/Chart/OFC/Dataset.pm',
    'lib/Chart/OFC/Dataset/3DBar.pm',
    'lib/Chart/OFC/Dataset/Area.pm',
    'lib/Chart/OFC/Dataset/Bar.pm',
    'lib/Chart/OFC/Dataset/Candle.pm',
    'lib/Chart/OFC/Dataset/FadeBar.pm',
    'lib/Chart/OFC/Dataset/GlassBar.pm',
    'lib/Chart/OFC/Dataset/HighLowClose.pm',
    'lib/Chart/OFC/Dataset/Line.pm',
    'lib/Chart/OFC/Dataset/LineWithDots.pm',
    'lib/Chart/OFC/Dataset/OutlinedBar.pm',
    'lib/Chart/OFC/Dataset/Scatter.pm',
    'lib/Chart/OFC/Dataset/SketchBar.pm',
    'lib/Chart/OFC/Grid.pm',
    'lib/Chart/OFC/Pie.pm',
    'lib/Chart/OFC/Role/OFCDataLines.pm',
    'lib/Chart/OFC/Types.pm',
    'lib/Chart/OFC/XAxis.pm',
    'lib/Chart/OFC/YAxis.pm'
);

notabs_ok($_) foreach @files;
done_testing;
