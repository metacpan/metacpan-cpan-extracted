use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/mdown',
    'lib/App/ManiacDownloader.pm',
    'lib/App/ManiacDownloader/_BytesDownloaded.pm',
    'lib/App/ManiacDownloader/_File.pm',
    'lib/App/ManiacDownloader/_SegmentTask.pm',
    't/00-compile.t'
);

notabs_ok($_) foreach @files;
done_testing;
