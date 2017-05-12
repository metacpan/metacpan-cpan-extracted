#!/usr/bin/env perl

use strict;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
  $pkg = 'Catmandu::Fix::orcid_works';
  use_ok $pkg;
}
require_ok $pkg;

dies_ok { $pkg->new() } "required argument";
lives_ok { $pkg->new('orcid') } "path required";

done_testing;