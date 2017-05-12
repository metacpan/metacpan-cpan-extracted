use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Carp/Always/Color.pm',
    'lib/Carp/Always/Color/HTML.pm',
    'lib/Carp/Always/Color/Term.pm',
    't/00-compile.t',
    't/detect.t',
    't/eval.t',
    't/html.t',
    't/lib/TestHelpers.pm',
    't/object.t',
    't/term.t'
);

notabs_ok($_) foreach @files;
done_testing;
