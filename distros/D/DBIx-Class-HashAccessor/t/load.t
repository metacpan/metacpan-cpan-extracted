#!/usr/bin/env perl
use strict;
use warnings;

use lib 't/lib';
use Test::More;

for (qw(
  DBIx::Class::HashAccessor
)) {
  use_ok($_);
}

done_testing;

