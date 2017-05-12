use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/bagit.pl',
    'lib/Archive/BagIt/App.pm',
    'lib/Archive/BagIt/App/Verify.pm',
    't/00-compile.t'
);

notabs_ok($_) foreach @files;
done_testing;
