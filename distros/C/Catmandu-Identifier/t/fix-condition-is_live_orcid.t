#!/usr/bin/env perl

use strict;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
  $pkg = 'Catmandu::Fix::Condition::is_live_orcid';
  use_ok $pkg;
}
require_ok $pkg;

done_testing;