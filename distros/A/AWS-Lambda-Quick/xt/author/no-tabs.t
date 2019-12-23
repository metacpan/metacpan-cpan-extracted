use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/AWS/Lambda/Quick.pm',
    'lib/AWS/Lambda/Quick/CreateZip.pm',
    'lib/AWS/Lambda/Quick/Processor.pm',
    'lib/AWS/Lambda/Quick/Upload.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/02zip.t',
    't/03process.t',
    't/lib/TestHelper/CreateTestFiles.pm'
);

notabs_ok($_) foreach @files;
done_testing;
