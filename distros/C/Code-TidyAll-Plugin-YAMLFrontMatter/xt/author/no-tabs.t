use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Code/TidyAll/Plugin/YAMLFrontMatter.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/FrontMatter.t',
    't/lib/Test/Code/TidyAll/Plugin/YAMLFrontMatter.pm'
);

notabs_ok($_) foreach @files;
done_testing;
