#!/usr/bin/perl -Iblib/arch -Iblib/lib

=head1 NAME

 makeslow - Slows down playing speed by changing samplerate parameter

=cut

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
$header->{samplerate} >>= 1;
$writer = new Audio::SoundFile::Writer($ofile,  $header);

while ($length = $reader->bread_pdl(\$buffer, $BUFFSIZE)) {
    $writer->bwrite_pdl($buffer);
}

$reader->close;
$writer->close;

exit(0);
