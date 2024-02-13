#!/usr/bin/perl

use strict;
use warnings;

use Test::Fatal;
use Test::More qw/no_plan/;
use FindBin;
use Compress::BGZF;
use Compress::BGZF::Reader;
use Compress::BGZF::Writer;
use File::Basename qw/basename/;
use File::Copy qw/copy/;
use File::Temp qw/tempfile/;
use IO::Handle;
use Digest::MD5;

chdir $FindBin::Bin;

require_ok ("Compress::BGZF");

# check that compressed and uncompressed FHs return identical results
my @files = (
    #'corpus/lorem_long',
    'corpus/lorem_mixed',
    'corpus/lorem',
    'corpus/long_chunks',
);

my $scratch = File::Temp->newdir(CLEANUP => 1);

# test various Writer methods, and add created fields to list of Reader tests
# to validate output
for my $i (0..$#files) {

    my $file = $files[$i];

    my $fn_u = join '/', $scratch, basename($file);
    my $fn_c = $fn_u . '.gz';
    my $fn_i = $fn_c . '.gzi';
    copy $file => $fn_u;

    # test writing to STDOUT on first file
    my $fh_tmp;
    if ($i == 0) {
        open $fh_tmp, '>', $fn_c;
        $fn_c = undef;
    }
    local *STDOUT = $fh_tmp
        if (defined $fh_tmp);

    my $writer = Compress::BGZF::Writer->new($fn_c);
    ok ($writer->isa('Compress::BGZF::Writer'), "returned Compress::BGZF::Writer object");

    # test various EOL/compression combinations
    $writer->set_write_eof();
    $writer->set_write_eof($i % 2);
    $writer->set_level(($i+1)*3 % 10);
    like(
        exception { $writer->set_level('foobar') },
        qr/invalid compression level/i,
        "invalid compression level caught $i.1"
    );
    like(
        exception { $writer->set_level(undef) },
        qr/invalid compression level/i,
        "invalid compression level caught $i.2"
    );

    open my $in, '<:raw', $file;
    while (my $line = <$in>) {
        $writer->add_data($line);
    }
    close $in;
    $writer->finalize();
    $writer->write_index($fn_i);
    like(
        exception { $writer->write_index() },
        qr/missing index output filename/i,
        "missing index filename caught $i.1"
    );

    push @files, $fn_u;

}

for my $i (0..$#files) {

    my $file = $files[$i];

    # check index creation

    my ($tmp_fh, $tmp_fn) = tempfile('bgzfXXXXXXXX', SUFFIX => '.gz',
        TMPDIR => 1, UNLINK => 1);
    close $tmp_fh;
    my $reader = Compress::BGZF::Reader->new("$file.gz");
    ok ($reader->isa('Compress::BGZF::Reader'), "returned Compress::BGZF::Reader object");
    $reader->rebuild_index
        if ($i % 2);
    $reader->write_index($tmp_fn);
    open my $new, '<:raw', $tmp_fn;
    my $md5_1 = Digest::MD5->new->addfile($new)->digest;
    open my $existing, '<:raw', "$file.gz.gzi";
    my $md5_2 = Digest::MD5->new->addfile($existing)->digest;

    ok ($md5_1 eq $md5_2, "index check $i.1");

    # check reading

    open my $fh_u, '<:raw', $file;

    $reader->move_to(5,0);
    seek $fh_u, 5, 0;
    my $line1 = $reader->getline();
    my $line2 = <$fh_u>;

    ok ($line1 eq $line2, "seek/read check $i.1");

    $reader->move_to(-s $file, 0);
    seek $fh_u, -s $file, 0;
    $line1 = $reader->getline();
    $line2 = <$fh_u>;

    ok (! defined $line1 && ! defined $line2, "seek/read EOF check $i.1");

    $reader->move_to(-5,0);
    seek $fh_u, -5, 0;
    $line1 = $reader->getline();
    $line2 = <$fh_u>;

    ok (! defined $line1 && ! defined $line2, "seek/read invalid position check $i.1");

    $reader->move_to(-5,2);
    seek $fh_u, -5, 2;
    $line1 = $reader->read_data(100);
    read $fh_u, $line2, 100;

    ok ($line1 eq $line2, "seek/read check $i.2");

    my $q1 = int( (-s $file)/4 );
    $reader->move_to($q1,0);
    seek $fh_u, $q1, 0;
    $line1 = $reader->getline();
    $line2 = <$fh_u>;

    ok ($line1 eq $line2, "seek/read check $i.3");

    my $q3 = int( (-s $file)/4*3 );
    $reader->move_to($q3,0);
    seek $fh_u, $q3, 0;
    $line1 = $reader->getline();
    $line2 = <$fh_u>;

    ok ($line1 eq $line2, "seek/read check $i.4");


    my $mid = int( (-s $file)/2 );
    $reader->move_to($mid,0);
    seek $fh_u, $mid, 0;
    my $vo = $reader->get_vo();
    $line1 = $reader->getline();
    $line2 = <$fh_u>;

    ok ($line1 eq $line2, "seek/read check $i.5");

    $reader->move_to(0,0);
    $reader->move_to_vo($vo);
    my $line1_vo = $reader->getline();

    ok ($line1 eq $line1_vo, "virtual offset check $i.1");

    ok ($reader->usize == -s $file, "size check $i.1");

    like(
        exception { $reader->move_to_vo(99999999) },
        qr/invalid block offset/i,
        "bad virtual offset caught $i.1"
    );

}

# test miscellaneous other intentional exceptions
like(
    exception { Compress::BGZF::Reader->new },
    qr/input filename required/i,
    'missing filename caught'
);
like(
    exception { Compress::BGZF::Reader->new('foobar_') },
    qr/failed to open/i,
    'bad filename caught'
);
like(
    exception { Compress::BGZF::Reader->new($files[0]) },
    qr/invalid header/i,
    'bad filetype caught'
);
like(
    exception { Compress::BGZF::Reader->new('corpus/truncated.gz') },
    qr/unexpected byte count/i,
    'truncated file caught'
);

