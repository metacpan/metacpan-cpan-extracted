use utf8;
use strict;
use Test::More;
use MAB2::Writer::Disk;
use MAB2::Writer::RAW;
use MAB2::Writer::XML;

use File::Temp qw(tempfile);
use IO::File;
use Encode qw(encode);

my ($fh, $filename) = tempfile();
my $writer = MAB2::Writer::XML->new( fh => $fh, xml_declaration => 1, collection => 1 );

my @mab_records = (
    [
      ['001', ' ', '_', '47918-4'],
      ['310', ' ', '_', 'Daß Ümläüt'],
      ['406', 'b', 'j', '1983'],
    ],
    {
      record => [
        ['LDR', ' ', '_', '11111nM2.01200024      h'],
        ['406', 'a', j => '1990', k => '2000'],
      ]
    }
);

$writer->start();

foreach my $record (@mab_records) {
    $writer->write($record);
}

# ToDo: Catmandu::Exporter::MAB2::commit
$writer->end();

close($fh);

my $out = do { local ( @ARGV, $/ ) = $filename; <> };

is $out, <<'MABXML';
<?xml version="1.0" encoding="UTF-8"?>
<datei xmlns="http://www.ddb.de/professionell/mabxml/mabxml-1.xsd" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.ddb.de/professionell/mabxml/mabxml-1.xsd http://www.d-nb.de/standardisierung/formate/mabxml-1.xsd">
<datensatz typ="h" status="n" mabVersion="M2.0">
<feld nr="001" ind=" ">47918-4</feld>
<feld nr="310" ind=" ">Daß Ümläüt</feld>
<feld nr="406" ind="b">
    <uf code="j">1983</uf>
</feld>
</datensatz>
<datensatz typ="h" status="n" mabVersion="M2.0">
<feld nr="406" ind="a">
    <uf code="j">1990</uf>
    <uf code="k">2000</uf>
</feld>
</datensatz>
</datei>
MABXML


($fh, $filename) = tempfile();
$writer = MAB2::Writer::RAW->new( fh => $fh );

foreach my $record (@mab_records) {
    $writer->write($record);
}

close($fh);

$out = do { local (@ARGV,$/)=$filename; <> };

is $out, <<'MABRAW';
99999nM2.01200024      h001 47918-4310 Daß Ümläüt406bj1983
11111nM2.01200024      h406aj1990k2000
MABRAW

($fh, $filename) = tempfile();

$writer = MAB2::Writer::RAW->new( file => $filename, encoding => 'UTF-8' );

foreach my $record (@mab_records) {
    $writer->write($record);
}
$writer->close_fh();

open $fh, '<:encoding(UTF-8)', $filename or die $!;
$out = do { local $/; <$fh> };

is $out, <<'MABRAW';
99999nM2.01200024      h001 47918-4310 Daß Ümläüt406bj1983
11111nM2.01200024      h406aj1990k2000
MABRAW

($fh, $filename) = tempfile();
$writer = MAB2::Writer::Disk->new( fh => $fh );

foreach my $record (@mab_records) {
    $writer->write($record);
}

close($fh);

$out = do { local (@ARGV,$/)=$filename; <> };

is $out, <<'MABDISK1';
### 99999nM2.01200024      h
001 47918-4
310 Daß Ümläüt
406bj1983

### 11111nM2.01200024      h
406aj1990k2000

MABDISK1

($fh, $filename) = tempfile();
$writer = MAB2::Writer::Disk->new( fh => $fh, subfield_indicator => '$' );

foreach my $record (@mab_records) {
    $writer->write($record);
}

close($fh);

$out = do { local (@ARGV,$/)=$filename; <> };

is $out, <<'MABDISK2';
### 99999nM2.01200024      h
001 47918-4
310 Daß Ümläüt
406b$j1983

### 11111nM2.01200024      h
406a$j1990$k2000

MABDISK2

done_testing;
