#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
  $pkg = 'Catmandu::Importer::SRU';
  use_ok($pkg);
}
require_ok($pkg);

my %attrs = (
  base => 'http://www.unicat.be/sru',
  query => 'dna'
);

my $importer = Catmandu::Importer::SRU->new(%attrs);

isa_ok($importer, $pkg);

can_ok($importer, 'each');

done_testing 4;
