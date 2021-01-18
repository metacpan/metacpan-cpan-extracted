use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Apache2/Filter/Minifier/JavaScript.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-compile.t',
    't/MY/CharsetHandler.pm',
    't/MY/JSHandler.pm',
    't/MY/NoCTypeHandler.pm',
    't/MY/PlainHandler.pm',
    't/MY/UpperCase.pm',
    't/TEST.PL',
    't/conf/extra.conf.in',
    't/content-length.t',
    't/content-type.t',
    't/decline.t',
    't/dynamic.t',
    't/htdocs/minified-xs.txt',
    't/htdocs/minified.txt',
    't/htdocs/test.js',
    't/htdocs/test.txt',
    't/mime-types.t',
    't/minifiers.t',
    't/mod-cgi.t',
    't/non-js.t',
    't/perl-bin/js.pl',
    't/perl-bin/plain.pl',
    't/pod-coverage.t',
    't/pod.t',
    't/registry.t'
);

notabs_ok($_) foreach @files;
done_testing;
