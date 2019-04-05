use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/notifier',
    'lib/App/Notifier/Client.pm',
    'lib/App/Notifier/Client/Notifier_App.pm',
    't/00-compile.t'
);

notabs_ok($_) foreach @files;
done_testing;
