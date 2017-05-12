use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.05

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Acme/LookOfDisapproval.pm'
);

notabs_ok($_) foreach @files;
done_testing;
