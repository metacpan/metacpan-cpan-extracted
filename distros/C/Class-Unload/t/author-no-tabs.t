
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'Changes',
    'META.json',
    'META.yml',
    'Makefile.PL',
    'README',
    'dist.ini',
    'lib/Class/Unload.pm',
    't/00-load.t',
    't/01-unload.t',
    't/02-inheritance.t',
    't/03-moose.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/lib/MooseClass.pm',
    't/lib/MyClass.pm',
    't/lib/MyClass/Child.pm',
    't/lib/MyClass/Parent.pm',
    't/lib/MyClass/Sub.pm',
    't/lib/MyClass/Sub/Sub.pm'
);

notabs_ok($_) foreach @files;
done_testing;
