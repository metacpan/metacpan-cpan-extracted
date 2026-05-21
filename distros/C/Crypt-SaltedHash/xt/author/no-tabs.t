use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Crypt/SaltedHash.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/04Crypt-SaltedHash.t',
    't/bug-localize-regex-vars.t'
);

notabs_ok($_) foreach @files;
done_testing;
