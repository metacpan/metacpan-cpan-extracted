#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw/no_plan/;
use FindBin;
use Compress::BGZF::Reader;
use Compress::BGZF::Writer;
use File::Temp qw/tempfile/;
use IO::Handle;
use Digest::MD5;

chdir $FindBin::Bin;

require_ok ("Compress::BGZF");

# check that compressed and uncompressed FHs return identical results
my @files = (
    'corpus/lorem_long',
    'corpus/lorem',
    'corpus/long_chunks',
);

for my $i (0..$#files) {

    my $file = $files[$i];

    # check index creation

    my ($tmp_fh, $tmp_fn) = tempfile('bgzfXXXXXXXX', SUFFIX => '.gz',
        TMPDIR => 1, UNLINK => 1);

    my $reader = Compress::BGZF::Reader->new("$file.gz");
    $reader->write_index($tmp_fn);
    seek $tmp_fh, 0, 0;
    my $md5_1 = Digest::MD5->new->addfile($tmp_fh)->digest;
    open my $idx, '<:raw', "$file.gz.gzi";
    my $md5_2 = Digest::MD5->new->addfile($idx)->digest;

    ok ($md5_1 eq $md5_2, "index check $i.1");

    # check reading

    open my $fh_u, '<:raw', $file;

    $reader->move_to(5,0);
    seek $fh_u, 5, 0;
    my $line1 = $reader->getline();
    my $line2 = <$fh_u>;

    ok ($line1 eq $line2, "seek/read check $i.2");

    $reader->move_to(-s $file,0);
    seek $fh_u, -s $file, 0;
    $line1 = $reader->getline();
    $line2 = <$fh_u>;

    ok ($line1 eq $line2, "seek/read check $i.3");

    $reader->move_to(-5,0);
    seek $fh_u, -5, 0;
    $line1 = $reader->getline();
    $line2 = <$fh_u>;

    ok ($line1 eq $line2, "seek/read check $i.4");

    $reader->move_to(-5,2);
    seek $fh_u, -5, 2;
    $line1 = $reader->read_data(100);
    read $fh_u, $line2, 100;

    ok ($line1 eq $line2, "seek/read check $i.5");

    ok ($reader->usize == -s $file, "size check $i.1");

    #TODO: Add additional Writer object-oriented tests

}


