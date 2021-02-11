use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/CGI/Application/Plugin/TT/LastModified.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-compile.t',
    't/auto-last-modified.t',
    't/last-modified.t',
    't/lib/TestApp/AutoLastModified.pm',
    't/lib/TestApp/LastModified.pm',
    't/lib/TestApp/Plain.pm',
    't/lib/TestApp/base.pm',
    't/plain.t',
    't/templates/bottom.html',
    't/templates/index.html',
    't/templates/top.html'
);

notabs_ok($_) foreach @files;
done_testing;
