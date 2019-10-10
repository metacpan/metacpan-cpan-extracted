#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::Importer::AlephX;
use Data::Dumper;
use Catmandu::Exporter::MARC;
use open qw(:std :utf8);


my $exporter = Catmandu::Exporter::MARC->new(type => "XML");

Catmandu::Importer::AlephX->new(
  url => 'http://borges1.ugent.be/X',
  base => 'usm01',
  include_items => 0
)->each(sub{
  my $record = shift;
  $exporter->add($record);
});
$exporter->commit();
