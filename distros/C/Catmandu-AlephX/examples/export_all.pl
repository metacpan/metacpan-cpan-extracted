#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Catmandu::Store::AlephX;
use Catmandu::Exporter::MARC;
use open qw(:std :utf8);

my $bag = Catmandu::Store::AlephX->new(url => "http://aleph.ugent.be/X");

my $exporter = Catmandu::Exporter::MARC->new(type => "ALEPHSEQ");

$bag->each(sub{
  $exporter->add(shift);
});
