#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
  $pkg = 'Catmandu::Importer::PLoS';
  use_ok($pkg);
}
require_ok($pkg);

my %attrs = (
  query => 'github'
);

my $importer = Catmandu::Importer::PLoS->new(%attrs);

isa_ok($importer, $pkg);

can_ok($importer, 'each');

done_testing 4;