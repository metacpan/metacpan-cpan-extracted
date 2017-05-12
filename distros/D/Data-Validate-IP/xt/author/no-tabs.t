use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Data/Validate/IP.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/Data-Validate-IP-slow.t',
    't/Data-Validate-IP.t',
    't/Untaint.t',
    't/lib/Test/Data/Validate/IP.pm'
);

notabs_ok($_) foreach @files;
done_testing;
