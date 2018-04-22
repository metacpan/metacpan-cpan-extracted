use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/B/Hooks/EndOfScope.pm',
    'lib/B/Hooks/EndOfScope/PP.pm',
    'lib/B/Hooks/EndOfScope/PP/FieldHash.pm',
    'lib/B/Hooks/EndOfScope/PP/HintHash.pm',
    'lib/B/Hooks/EndOfScope/XS.pm',
    't/00-basic.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-eval.t',
    't/02-localise.t',
    't/05-exception_xs.t',
    't/06-exception_pp.t',
    't/07-nested.t',
    't/10-test_without_vm_pure_pp.t',
    't/11-direct_xs.t',
    't/12-direct_pp.t',
    't/lib/OtherClass.pm',
    't/lib/YetAnotherClass.pm',
    'xt/author/00-compile.t',
    'xt/author/changes_has_content.t',
    'xt/author/check-inc.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
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
