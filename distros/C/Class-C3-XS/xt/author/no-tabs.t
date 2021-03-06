use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Class/C3/XS.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01_MRO.t',
    't/02_MRO.t',
    't/03_MRO.t',
    't/04_MRO.t',
    't/05_MRO.t',
    't/30_next_method.t',
    't/31_next_method_skip.t',
    't/32_next_method_edge_cases.t',
    't/33_next_method_used_with_NEXT.t',
    't/34_next_method_in_eval.t',
    't/35_next_method_in_anon.t',
    't/36_next_goto.t',
    'xt/author/00-compile.t',
    'xt/author/changes_has_content.t',
    'xt/author/clean-namespaces.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-no404s.t',
    'xt/author/pod-spell.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t'
);

notabs_ok($_) foreach @files;
done_testing;
