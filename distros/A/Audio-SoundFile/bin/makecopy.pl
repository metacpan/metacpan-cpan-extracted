#!/usr/bin/perl -Iblib/arch -Iblib/lib

=head1 NAME

 makecopy - cp(1) for sound file, using Audio::SoundFile library

=cut

use Audio::SoundFile;

my $BUFFSIZE = 16384;

my $ifile = shift;
my $ofile = shift;

my $buffer;
my $length;
my $header;
my $reader = new Audio::SoundFile::Reader($ifile, \$header);
my $writer = new Audio::SoundFile::Writer($ofile,  $header);

while ($length = $reader->bread_pdl(\$buffer, $BUFFSIZE)) {
    $writer->bwrite_pdl($buffer);
}
$reader->close;
$writer->close;

exit(0);
