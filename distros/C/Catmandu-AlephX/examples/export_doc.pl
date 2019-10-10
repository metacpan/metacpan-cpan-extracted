#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::Store::AlephX;
use Catmandu::Exporter::MARC;
use open qw(:std :utf8);

my $bag = Catmandu::Store::AlephX->new(url => "http://borges1.ugent.be/X");
my $exporter = Catmandu::Exporter::MARC->new(type => "ALEPHSEQ");

$exporter->add($bag->get(shift));
$exporter->commit;
