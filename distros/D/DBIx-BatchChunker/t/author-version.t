#!/usr/bin/perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

use Test2::Bundle::More;
use Test2::Require::AuthorTesting;
use Test::Version 2 qw( version_all_ok ), {
    is_strict   => 0,
    has_version => 1,
    consistent  => 1,
  };

version_all_ok('lib');

done_testing;
