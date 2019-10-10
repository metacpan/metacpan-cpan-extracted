#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::Importer::AlephX;
use Data::Dumper;
use open qw(:std :utf8);

Catmandu::Importer::AlephX->new(
  url => 'http://borges1.ugent.be/X',
  base => 'usm01',
  include_items => 1
)->each(sub{
  my $record = shift;
  print Dumper($record);
});
