use strict;
use warnings;
use Test::More;
use Test::XML;

use Catmandu::Exporter::PICA;
use File::Temp qw(tempfile);
use IO::File;
use Encode qw(encode);
use PICA::Data qw(pica_parser);
use PICA::Parser::PPXML;

sub slurp {
    do { local (@ARGV,$/) = shift; <> };
}

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

$exporter->add_many(\@pica_records);
$exporter->commit();

close($fh);

is slurp($filename), <<'PLAIN';
003@ $01041318383
021A $aHello $$¥!

028C/01 $dEmma$aGoldman

PLAIN

( $fh, $filename ) = tempfile();
$exporter = Catmandu::Exporter::PICA->new(
    fh => $fh,
    type => 'plus',
);

$exporter->add_many(\@pica_records);
$exporter->commit();

close($fh);

is slurp($filename), <<'PLUS';
003@ 01041318383021A aHello $¥!
028C/01 dEmmaaGoldman
PLUS

## Generic
($fh, $filename) = tempfile();
$exporter = Catmandu::Exporter::PICA->new(
    fh   => $fh,
    type => 'generic',
    subfield_indicator => '_',
    field_separator    => '!',
    record_separator   => "#\n"
);
$exporter->add_many(\@pica_records);
$exporter->commit();

close($fh);

is slurp($filename), <<'GENERIC';
003@ _01041318383!021A _aHello $¥!!#
028C/01 _dEmma_aGoldman!#
GENERIC


## XML
( $fh, $filename ) = tempfile();
$exporter = Catmandu::Exporter::PICA->new(
    fh => $fh,
    type => 'xml',
);

$exporter->add_many(\@pica_records);
$exporter->commit();

close($fh);

is slurp($filename), <<'XML';
<?xml version="1.0" encoding="UTF-8"?>

<collection xmlns="info:srw/schema/5/picaXML-v1.0">
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
</collection>
XML

# PPXML
my $parser = pica_parser( 'PPXML' => 't/files/slim_ppxml.xml' );
my $record;
($fh, $filename) = tempfile();
$exporter = Catmandu::Exporter::PICA->new(
    fh => $fh,
    type => 'ppxml',
);
while($record = $parser->next){
    $exporter->add($record);
}
$exporter->commit();
close $fh;

my $in = do { local (@ARGV,$/)='t/files/slim_ppxml.xml'; <> };

is_xml(slurp($filename), $in, 'PPXML writer');

done_testing;
