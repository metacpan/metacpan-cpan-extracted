#!/usr/bin/perl -Iblib/arch -Iblib/lib

=head1 NAME

 makeloud - Increase sound level of input and writes to output

=cut

use PDL;
use Audio::SoundFile;
use Audio::SoundFile::Header;

my $BUFFSIZE = 16384;

my $ifile = shift;
my $ofile = shift;

my $buffer;
my $length;
my $header;
my $reader;
my $writer;

$reader = new Audio::SoundFile::Reader($ifile, \$header);
$writer = new Audio::SoundFile::Writer($ofile,  $header);

while ($length = $reader->bread_pdl(\$buffer, $BUFFSIZE)) {
    $buffer->inplace->mult(1.5, 0);
    $writer->bwrite_pdl($buffer);
}

$reader->close;
$writer->close;

exit(0);
