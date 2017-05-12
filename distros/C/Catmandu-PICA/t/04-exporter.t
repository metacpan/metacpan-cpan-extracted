use strict;
use warnings;
use Test::More;

use Catmandu::Exporter::PICA;
use File::Temp qw(tempfile);
use IO::File;
use Encode qw(encode);

my @pica_records = (
    [
      ['003@', '', '0', '1041318383'],
      ['021A', '', 'a', encode('UTF-8',"Hello \$\N{U+00A5}!")],
    ],
    {
      record => [
        ['028C', '01', d => 'Emma', a => 'Goldman']
      ]
    }
);

my ( $fh, $filename ) = tempfile();
my $exporter = Catmandu::Exporter::PICA->new(
    fh => $fh,
    type => 'plain',
);

for my $record (@pica_records) {
    $exporter->add($record);
}

$exporter->commit();

close($fh);

my $out = do { local (@ARGV,$/)=$filename; <> };

is $out, <<'PLAIN';
003@ $01041318383
021A $aHello $$¥!

028C/01 $dEmma$aGoldman

PLAIN

( $fh, $filename ) = tempfile();
$exporter = Catmandu::Exporter::PICA->new(
    fh => $fh,
    type => 'plus',
);

for my $record (@pica_records) {
    $exporter->add($record);
}

$exporter->commit();

close($fh);

$out = do { local (@ARGV,$/)=$filename; <> };

is $out, <<'PLUS';
003@ 01041318383021A aHello $¥!
028C/01 dEmmaaGoldman
PLUS

( $fh, $filename ) = tempfile();
$exporter = Catmandu::Exporter::PICA->new(
    fh => $fh,
    type => 'xml',
);

for my $record (@pica_records) {
    $exporter->add($record);
}

$exporter->commit();

close($fh);

$out = do { local (@ARGV,$/)=$filename; <> };

is $out, <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<collection xlmns="info:srw/schema/5/picaXML-v1.0">
<record>
  <datafield tag="003@">
    <subfield code="0">1041318383</subfield>
  </datafield>
  <datafield tag="021A">
    <subfield code="a">Hello $¥!</subfield>
  </datafield>
</record>
<record>
  <datafield tag="028C" occurrence="01">
    <subfield code="d">Emma</subfield>
    <subfield code="a">Goldman</subfield>
  </datafield>
</record>
XML

done_testing;