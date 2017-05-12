#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::Importer::AlephX;
use Data::Dumper;
use open qw(:std :utf8);

my $i = 1;
Catmandu::Importer::AlephX->new(
  url => 'http://aleph.ugent.be/X',
  query => 'WRD=(all)',
  base => 'usm01',
  include_items => 0,
  limit => 5
)->each(sub{
  my $record = shift;
  #print Dumper($record);
  say ($i++);
});
