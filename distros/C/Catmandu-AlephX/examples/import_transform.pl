#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::Importer::AlephX;
use Catmandu::AlephX::Metadata::MARC::Aleph;
use Data::Dumper;
use open qw(:std :utf8);

Catmandu::Importer::AlephX->new(
  url => 'http://borges1.ugent.be/X',
  query => 'WRD=(art)',
  base => 'usm01',
  include_items => 0
)->each(sub{
  my $record = shift;
  say Catmandu::AlephX::Metadata::MARC::Aleph->to_xml($record);
});
