#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
  $pkg = 'Catmandu::Importer::Z3950';
  use_ok($pkg);
}
require_ok($pkg);

my %attrs = (
  host => 'z3950.loc.gov',
  port => 7090,
  databaseName => "Voyager",
  preferredRecordSyntax => "USMARC",
  queryType => 'PQF',
  query => '@attr 1=4 dinosaur'
);

my $importer = Catmandu::Importer::Z3950->new(%attrs);

isa_ok($importer, $pkg);

can_ok($importer, 'each');

done_testing 4;
