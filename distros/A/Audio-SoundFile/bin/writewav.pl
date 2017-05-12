#!/usr/bin/perl -Iblib/arch -Iblib/lib

=head1 NAME

 writewav - Converts any sound file into .wav format

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
$header->{format} = SF_FORMAT_WAV | SF_FORMAT_PCM;
$writer = new Audio::SoundFile::Writer($ofile,  $header);

while ($length = $reader->bread_pdl(\$buffer, $BUFFSIZE)) {
    $writer->bwrite_pdl($buffer);
}

$reader->close;
$writer->close;

exit(0);
