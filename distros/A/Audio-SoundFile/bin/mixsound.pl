#!/usr/bin/perl -Iblib/arch -Iblib/lib

=head1 NAME

 mixsound - A kludge that mixes two sound input into one

=cut

use PDL;
use Audio::SoundFile;
use Audio::SoundFile::Header;

my $BUFFSIZE = 4096;

my $file1 = shift;
my $file2 = shift;
my $file3 = shift;

$reader1 = new Audio::SoundFile::Reader($file1, \$header);
$reader2 = new Audio::SoundFile::Reader($file2, \$header);
$writer1 = new Audio::SoundFile::Writer($file3,  $header);

while (1) {
    $length1 = $reader1->bread_pdl(\$buffer1, $BUFFSIZE);
    $length2 = $reader2->bread_pdl(\$buffer2, $BUFFSIZE);

    last unless $length1 > 0 || $length2 > 0;

    ## make sure buffer is PDL object
    $buffer1 = pdl([]) unless $length1 > 0;
    $buffer2 = pdl([]) unless $length2 > 0;

    ## align buffer length
    if (($diff = $buffer1->dims - $buffer2->dims) != 0) {
        if ($diff > 0) {
            $buffer2 = $buffer2->append(zeroes(abs($diff)));
        }
        else {
            $buffer1 = $buffer1->append(zeroes(abs($diff)));
        }
    }

    # decrease signal level for each source
    $buffer1->inplace->mult(0.8, 0);
    $buffer2->inplace->mult(0.2, 0);

    # mix
    $buffer1->inplace->plus($buffer2, 0);

    # write
    $writer1->bwrite_pdl($buffer1);
}

$reader1->close;
$reader2->close;
$writer1->close;

exit(0);
