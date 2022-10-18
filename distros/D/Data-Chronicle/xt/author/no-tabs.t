use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Data/Chronicle.pm',
    'lib/Data/Chronicle/Mock.pm',
    'lib/Data/Chronicle/Reader.pm',
    'lib/Data/Chronicle/Reader.pod',
    'lib/Data/Chronicle/Subscriber.pm',
    'lib/Data/Chronicle/Subscriber.pod',
    'lib/Data/Chronicle/Writer.pm',
    'lib/Data/Chronicle/Writer.pod',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/chronicle.t',
    't/publish.t',
    't/rc/perlcriticrc',
    't/rc/perltidyrc',
    't/redis.t',
    'xt/author/critic.t',
    'xt/author/distmeta.t',
    'xt/author/eol.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/author/test-version.t',
    'xt/release/common_spelling.t',
    'xt/release/cpan-changes.t'
);

notabs_ok($_) foreach @files;
done_testing;
