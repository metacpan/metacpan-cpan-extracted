package BackPAN::Index::Create::TestUtils;

use strict;
use warnings;

use File::Touch;
use File::Compare ();
use parent 'Exporter';

our @EXPORT_OK = qw/ setup_testpan text_files_match /;


sub setup_testpan
{
    return touch_file('t/testpan/authors/id/P/PO/POGLE/Wood-Pogle-0.001.meta'          => 1399111341)
           && touch_file('t/testpan/authors/id/P/PO/POGLE/Wood-Pogle-0.001.readme'     => 1399111357)
           && touch_file('t/testpan/authors/id/P/PO/POGLE/Wood-Pogle-0.001.tar.gz'     => 1399111421)
           && touch_file('t/testpan/authors/id/Z/ZA/ZAPHOD/Heart-Of-Gold-0.01.meta'    => 1399110691)
           && touch_file('t/testpan/authors/id/Z/ZA/ZAPHOD/Heart-Of-Gold-0.01.readme'  => 1399110713)
           && touch_file('t/testpan/authors/id/Z/ZA/ZAPHOD/Heart-Of-Gold-0.01.tar.gz'  => 1399111170);
}

sub touch_file
{
    my ($filename, $time) = @_;
    my $toucher           = File::Touch->new(mtime => $time);

    return $toucher->touch($filename);
}

sub text_files_match
{
    my ($filename1, $filename2) = @_;

    return File::Compare::compare_text($filename1, $filename2,
                sub {
                    my ($line1, $line2) = @_;
                    $line1 =~ s/[\r\n]+$//;
                    $line2 =~ s/[\r\n]+$//;
                    return $line1 ne $line2;
                }) == 0;
}

