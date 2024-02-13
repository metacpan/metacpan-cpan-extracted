#!/usr/bin/perl

use strict;
use warnings;

use Test::Fatal;
use Test::More qw/no_plan/;
use FindBin;
use Compress::BGZF;
use Compress::BGZF::Reader;
use Compress::BGZF::Writer;
use File::Temp qw/tempfile/;
use IO::Handle;

chdir $FindBin::Bin;

require_ok ("Compress::BGZF");

# check that compressed and uncompressed FHs return identical results
my @files = (
    'corpus/long_chunks',
    'corpus/lorem',
    'corpus/lorem_long',
);

for my $i (0..$#files) {

    my $file = $files[$i];

    # create a compressed version
    my ($tmp_fh, $tmp_fn) = tempfile('bgzfXXXXXXXX', SUFFIX => '.gz',
        TMPDIR => 1, UNLINK => 1);
    my $fh_w = Compress::BGZF::Writer->new_filehandle("$tmp_fn");
    open my $fh_u, '<:raw', $file;
    print {$fh_w} $_ while (<$fh_u>);
    close $fh_w;
    seek $fh_u, 0, 0;

    # initialize read pair
    my $fh_c = Compress::BGZF::Reader->new_filehandle($tmp_fn);
    ok (ref($fh_c) eq 'FileHandle', "returned filehandle FileHandle");
    my $buf_c;
    my $buf_u;
    my @inputs = ( [$fh_c, $buf_c], [$fh_u, $buf_u] );

    # perform as many possible types of seek/read as we can

    seek( $_->[0], 72000, 0 )   for @inputs;
    read( $_->[0], $_->[1], 9 ) for @inputs;
    ok ($inputs[0]->[1] eq $inputs[1]->[1], "seek/read check $i.1");

    ok (eof($inputs[0]->[0]) == eof($inputs[1]->[0]), "eof check $i.1");

    seek( $_->[0], 18, 1 )   for @inputs;
    read( $_->[0], $_->[1], 623, 5) for @inputs;;
    ok ($inputs[0]->[1] eq $inputs[1]->[1], "seek/read check $i.2");

    seek( $_->[0], -18, 2 )   for @inputs;
    read( $_->[0], $_->[1], 82, -2) for @inputs;;
    ok ($inputs[0]->[1] eq $inputs[1]->[1], "seek/read check $i.3");

    seek( $_->[0], 18, 2 )   for @inputs;
    read( $_->[0], $_->[1], 82, 0) for @inputs;;
    ok ($inputs[0]->[1] eq $inputs[1]->[1], "seek/read check $i.4");

    seek( $_->[0], 130000, 0 )   for @inputs;
    read( $_->[0], $_->[1], 8, 0) for @inputs;;
    ok ($inputs[0]->[1] eq $inputs[1]->[1], "seek/read check $i.5");

    seek( $_->[0], 83, 0 )   for @inputs;
    ok (eof($inputs[0]->[1]) == eof($inputs[1]->[1]), "eof check $i.2");

    read( $_->[0], $_->[1], 150000, 0) for @inputs;;
    ok ($inputs[0]->[1] eq $inputs[1]->[1], "seek/read check $i.6");

    ok (tell($inputs[0]->[0]) eq tell($inputs[1]->[0]), "tell check $i.1");

    seek( $_->[0], -2, 0 )   for @inputs;
    read( $_->[0], $_->[1], 15, 1) for @inputs;;
    ok ($inputs[0]->[1] eq $inputs[1]->[1], "seek/read check $i.7");

    seek( $_->[0], 811, 0 )   for @inputs;
    read( $_->[0], $_->[1], 15, 0) for @inputs;;
    ok ($inputs[0]->[1] eq $inputs[1]->[1], "seek/read check $i.8");

    seek( $_->[0], 812, 0 )   for @inputs;
    read( $_->[0], $_->[1], 15, 0) for @inputs;;
    ok ($inputs[0]->[1] eq $inputs[1]->[1], "seek/read check $i.9");

    seek( $_->[0], 813, 0 )   for @inputs;
    read( $_->[0], $_->[1], 15, 0) for @inputs;;
    ok ($inputs[0]->[1] eq $inputs[1]->[1], "seek/read check $i.10");

    seek( $_->[0], -400, 1 )   for @inputs;
    read( $_->[0], $_->[1], 15, 0) for @inputs;;
    ok ($inputs[0]->[1] eq $inputs[1]->[1], "seek/read check $i.11");

    seek( $_->[0], -200, 2 )   for @inputs;
    read( $_->[0], $_->[1], 15, 8) for @inputs;;
    ok ($inputs[0]->[1] eq $inputs[1]->[1], "seek/read check $i.12");

    seek( $_->[0], 0, 2 )   for @inputs;
    read( $_->[0], $_->[1], 15, 0) for @inputs;;
    ok ($inputs[0]->[1] eq $inputs[1]->[1], "seek/read check $i.13");

    for (0..1) {
        for (@inputs) {
            my $fh = $_->[0];
            my $line = <$fh>;
            $_->[1] .= $line if (defined $line);
        }
    }
    ok ($inputs[0]->[1] eq $inputs[1]->[1], "readline check $i.1");

    # clear buffers;
    $_->[1] = '' for @inputs;

    seek( $_->[0], -75000, 2 )   for @inputs;
    for (@inputs) {
        my $fh = $_->[0];
        while (my $line = <$fh>) {
            $_->[1] .= $line;
        }
    }
    my $l1 = length $inputs[0]->[1];
    my $l2 = length $inputs[1]->[1];
    print "$l1 v $l2\n";
    ok ($inputs[0]->[1] eq $inputs[1]->[1], "readline check $i.2");

    close $_->[0] for @inputs;

    ok ($inputs[0]->[0]->opened() eq $inputs[1]->[0]->opened(), "close check $i.1");

}

like(
    exception { Compress::BGZF::Reader->new_filehandle },
    qr/input filename required/i,
    'missing filename caught'
);
like(
    exception { Compress::BGZF::Reader->new_filehandle('foobar_') },
    qr/failed to open/i,
    'bad filename caught'
);


