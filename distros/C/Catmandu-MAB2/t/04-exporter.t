use utf8;
use strict;
use warnings;
use Test::More;

use Catmandu::Exporter::MAB2;

use File::Temp qw(tempfile);
use IO::File;
use Encode qw(encode);

my @mab_records = (

    [ [ '001', ' ', '_', '47918-4' ], [ '310', ' ', '_', 'Daß Ümläüt' ], [ '406', 'b', 'j', '1983' ], ],
    { record => [ [ '406', 'a', j => '1990', k => '2000' ] ] }
);

my ( $fh, $filename ) = tempfile();
my $exporter = Catmandu::Exporter::MAB2->new(
    file            => $filename,
    type            => 'XML',
    xml_declaration => 1,
    collection      => 1
);

for my $record (@mab_records) {
    $exporter->add($record);
}

$exporter->commit();

close($fh);

open $fh, '<:encoding(UTF-8)', $filename or die $!;
my $out = do { local $/; <$fh> };

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

( $fh, $filename ) = tempfile();
$exporter = Catmandu::Exporter::MAB2->new( file => $filename, type => 'RAW' );

for my $record (@mab_records) {
    $exporter->add($record);
}

$exporter->commit();

close($fh);

open $fh, '<:encoding(UTF-8)', $filename or die $!;
$out = do { local $/; <$fh> };

is $out, <<'MABRAW';
99999nM2.01200024      h001 47918-4310 Daß Ümläüt406bj1983
99999nM2.01200024      h406aj1990k2000
MABRAW

( $fh, $filename ) = tempfile();
$exporter = Catmandu::Exporter::MAB2->new( file => $filename, type => 'DISK' );

for my $record (@mab_records) {
    $exporter->add($record);
}

$exporter->commit();

close($fh);

open $fh, '<:encoding(UTF-8)', $filename or die $!;
$out = do { local $/; <$fh> };

is $out, <<'MABDISK';
### 99999nM2.01200024      h
001 47918-4
310 Daß Ümläüt
406bj1983

### 99999nM2.01200024      h
406aj1990k2000

MABDISK

done_testing;
