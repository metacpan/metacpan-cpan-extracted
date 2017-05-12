#!/usr/bin/perl -Iblib/arch -Iblib/lib

=head1 NAME

 benchmark - Compares processing speed of various methods

=cut

use Benchmark;

use PDL;
use Audio::SoundFile;

my $BUFFSIZE = 16384;

my $ifile = shift;
my $ofile = shift;
my $count = shift || 100;

print STDERR "Please wait. This may take several minutes (on P3-500)...\n";

timethese($count, {
    'Scalar Access Test' => \&actest_raw,
    'PDL Access Test'    => \&actest_pdl,
    'Hybrid Access Test' => \&actest_mix,
    'Scalar I/O Test'    => \&iotest_raw,
    'PDL I/O Test'       => \&iotest_pdl,
});

exit(0);

sub iotest_pdl {
    my $buffer;
    my $length;
    my $header;
    my $reader = new Audio::SoundFile::Reader($ifile, \$header);
    my $writer = new Audio::SoundFile::Writer($ofile,  $header);

    while ($length = $reader->bread_pdl(\$buffer, $BUFFSIZE)) {
#       print STDERR ".";
        $writer->bwrite_pdl($buffer);
    }
    $reader->close;
    $writer->close;
}

sub iotest_raw {
    my $buffer;
    my $length;
    my $header;
    my $reader = new Audio::SoundFile::Reader($ifile, \$header);
    my $writer = new Audio::SoundFile::Writer($ofile,  $header);

    while ($length = $reader->bread_raw(\$buffer, $BUFFSIZE)) {
#       print STDERR ".";
        $writer->bwrite_raw($buffer);
    }
    $reader->close;
    $writer->close;
}

sub actest_pdl {
    my $buffer;
    my $length;
    my $header;
    my $reader = new Audio::SoundFile::Reader($ifile, \$header);
    my $writer = new Audio::SoundFile::Writer($ofile,  $header);

    while ($length = $reader->bread_pdl(\$buffer, $BUFFSIZE)) {
#       print STDERR ".";
        $buffer->inplace->mult(2, 0);
        $writer->bwrite_pdl($buffer);
    }
    $reader->close;
    $writer->close;
}

sub actest_raw {
    my $buffer;
    my $length;
    my $header;
    my $reader = new Audio::SoundFile::Reader($ifile, \$header);
    my $writer = new Audio::SoundFile::Writer($ofile,  $header);

    while ($length = $reader->bread_raw(\$buffer, $BUFFSIZE)) {
#       print STDERR ".";
        $buffer = pack("s*", map { $_ *= 2 } unpack("s*", $buffer));
        $writer->bwrite_raw($buffer);
    }
    $reader->close;
    $writer->close;
}

sub actest_mix {
    my $buffer;
    my $length;
    my $header;
    my $reader = new Audio::SoundFile::Reader($ifile, \$header);
    my $writer = new Audio::SoundFile::Writer($ofile,  $header);

    while ($length = $reader->bread_raw(\$buffer, $BUFFSIZE)) {
#       print STDERR ".";
        $buffer = pdl(unpack("s*", $buffer));
        $buffer->inplace->mult(2, 0);
        $writer->bwrite_pdl($buffer);
    }
    $reader->close;
    $writer->close;
}
