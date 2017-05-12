
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/CGI/Emulate/PSGI/Streaming.pm',
    'lib/CGI/Parse/PSGI/Streaming.pm',
    'lib/CGI/Parse/PSGI/Streaming/Handle.pm',
    't/parse.t',
    't/simple.t'
);

notabs_ok($_) foreach @files;
done_testing;
