use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/DateTime/Format/Duration.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/1_load.t',
    't/2_fmt_normalise.t',
    't/3_fmt_normalise_iso.t',
    't/4_fmt_normalise_no_base.t',
    't/5_fmt_no_normalise.t',
    't/6_parse.t',
    't/7_misc.t',
    't/8_negatives.t',
    'xt/author/00-compile.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-spell.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/minimum-version.t',
    'xt/release/pod-syntax.t',
    'xt/release/portability.t'
);

notabs_ok($_) foreach @files;
done_testing;
