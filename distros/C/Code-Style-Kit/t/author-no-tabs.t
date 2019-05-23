
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Code/Style/Kit.pm',
    'lib/Code/Style/Kit/Parts.pod',
    'lib/Code/Style/Kit/Parts/Autobox.pm',
    'lib/Code/Style/Kit/Parts/Common.pm',
    'lib/Code/Style/Kit/Parts/Mojo.pm',
    'lib/Code/Style/Kit/Parts/Moo.pm',
    'lib/Code/Style/Kit/Parts/Moose.pm',
    'lib/Code/Style/Kit/Parts/Perl516.pm',
    'lib/Code/Style/Kit/Parts/Perl526.pm',
    'lib/Code/Style/Kit/Parts/Test.pm',
    'lib/Code/Style/Kit/Parts/Test2.pm',
    'lib/Code/Style/Kit/Parts/Types.pm',
    't/lib/TestHelper.pm',
    't/lib/TestKit.pm',
    't/lib/TestKit/Parts/Args.pm',
    't/lib/TestKit/Parts/List.pm',
    't/lib/TestKit/Parts/Methods.pm',
    't/lib/TestKit/Parts/Strictures.pm',
    't/lib/TestThing.pm',
    't/tests/autobox.t',
    't/tests/common.t',
    't/tests/kits.t',
    't/tests/mojo.t',
    't/tests/moo.t'
);

notabs_ok($_) foreach @files;
done_testing;
