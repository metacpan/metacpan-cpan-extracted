use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Class/Load/XS.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/000-load.t',
    't/001-is-class-loaded.t',
    't/002-try-load-class.t',
    't/003-load-class.t',
    't/004-load-double.t',
    't/005-load-optional.t',
    't/006-returned-error.t',
    't/007-first-existing.t',
    't/008-gvstash-bug.t',
    't/009-invalid-module-name.t',
    't/010-isa-false-positive.t',
    't/011-without-xs.t',
    't/012-without-implementation.t',
    't/013-errors.t',
    't/014-weird-constants.t',
    't/lib/Class/Load/Error/DieAfterBeginIsa.pm',
    't/lib/Class/Load/Error/DieAfterIsa.pm',
    't/lib/Class/Load/Error/SyntaxErrorAfterIsa.pm',
    't/lib/Class/Load/OK.pm',
    't/lib/Class/Load/Stash.pm',
    't/lib/Class/Load/Stash/Sub.pm',
    't/lib/Class/Load/SyntaxError.pm',
    't/lib/Class/Load/VersionCheck.pm',
    't/lib/Class/Load/VersionCheck2.pm',
    't/lib/Test/Class/Load.pm',
    'xt/author/00-compile.t',
    'xt/author/clean-namespaces.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-coverage.t',
    'xt/author/pod-no404s.t',
    'xt/author/pod-spell.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/minimum-version.t'
);

notabs_ok($_) foreach @files;
done_testing;
