use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Crypt/Random/Source.pm',
    'lib/Crypt/Random/Source/Base.pm',
    'lib/Crypt/Random/Source/Base/File.pm',
    'lib/Crypt/Random/Source/Base/Handle.pm',
    'lib/Crypt/Random/Source/Base/Proc.pm',
    'lib/Crypt/Random/Source/Base/RandomDevice.pm',
    'lib/Crypt/Random/Source/Factory.pm',
    'lib/Crypt/Random/Source/Strong.pm',
    'lib/Crypt/Random/Source/Strong/devrandom.pm',
    'lib/Crypt/Random/Source/Weak.pm',
    'lib/Crypt/Random/Source/Weak/devurandom.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/blocking.t',
    't/dev_random.t',
    't/factory.t',
    't/proc.t',
    't/reread.t',
    't/sugar.t',
    'xt/author/00-compile.t',
    'xt/author/changes_has_content.t',
    'xt/author/clean-namespaces.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-no404s.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t'
);

notabs_ok($_) foreach @files;
done_testing;
