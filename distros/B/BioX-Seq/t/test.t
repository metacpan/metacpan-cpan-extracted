#!/usr/bin/perl

use strict;
use warnings;

use File::Compare;
use IPC::Cmd qw/can_run/;
use Test::More;
use Test::Exception;
use FindBin;
use BioX::Seq;
use BioX::Seq::Stream;
use BioX::Seq::Fetch;
use BioX::Seq::Utils qw/rev_com is_nucleic all_orfs build_ORF_regex/;

chdir $FindBin::Bin;

my $test_fa         = 'test_data/test.fa';
my $test2_fa        = 'test_data/test2.fa';
my $test_fq         = 'test_data/test.fq.bz2';
my $test_gz         = 'test_data/test2.fa.gz';
my $test_zst        = 'test_data/test2.fa.zst';
my $test_fai        = 'test_data/test2.fa.gz.fai';
my $test_fai_expl   = 'test_data/foo.fai';
my $test_fai_cmp    = 'test_data/test2.fa.gz.fai.cmp';
my $test_2bit       = 'test_data/test3.2bit';
my $test_orfs       = 'test_data/test4.fa';
my $test_dsrc       = 'test_data/test2.fq.dsrc';
my $test_fqz        = 'test_data/test2.fq.fqz';
my $test_xz         = 'test_data/test2.fa.xz';
my $test_onebyte    = 'test_data/one_byte.fa';
my $test_foobar     = 'test_data/foobar.txt';
my $test_notbgzip   = 'test_data/not_bgzip.fa.gz';
my $test_bad        = 'test_data/test_bad.fa';
my $test_endings    = 'test_data/test_weird_endings.fa';
my $test_duplicates = 'test_data/test_duplicate_ids.fa';
my $test_oneline_fa = 'test_data/test_one_line.fa';
my $test_oneline_fq = 'test_data/test_one_line.fq';
my $test_badheader  = 'test_data/test_bad_header.fa';
my $test_large      = 'test_data/large.fa.gz';

my @tmp_files = (
    $test_fai,
    $test_fai_expl,
    "$test_duplicates.fai",
    "$test2_fa.fai",
);


#----------------------------------------------------------------------------#
# BioX::Seq testing
#----------------------------------------------------------------------------#

my $obj = BioX::Seq->new;

ok ($obj->isa('BioX::Seq'), "returned BioX::Seq object");

$obj->seq = undef;
ok ("$obj" eq '', "empty object stringify");

$obj->seq( 'AAGE' );
ok ( ! defined $obj->rev_com , 'bad rev_com');
$obj->seq( 'AAGT' );
$obj .= 'TTCAAA';
$obj->rev_com();
ok ("$obj" eq 'TTTGAAACTT', "concat and rc");

ok( ! defined $obj->as_fasta, "print FASTA missing ID" );

throws_ok { $obj->translate(-1) } qr/not a valid frame/, 'frame too low';
throws_ok { $obj->translate(6) } qr/not a valid frame/, 'frame too high';
my $tr = $obj->translate(5);
ok ($obj->seq() eq 'TTTGAAACTT', "context transform");
ok ($tr->seq() eq 'VS', "translater");

ok (! defined $obj->as_fastq, "print FASTQ missing ID");
$obj->id('test_seq');
ok ($obj->as_fasta eq ">test_seq\nTTTGAAACTT\n", "as FASTA no desc");

my $sub = $obj->rev_com->range(3,10);
ok ("$sub" eq 'GTTTCAAA', "range");
$sub = $obj->rev_com->range(3,11);
ok (! defined $sub, "out of range");

throws_ok { $obj->as_fastq } qr/undefined quality/, 'undefined quality check';
my $fq = $obj->rev_com->as_fastq(21);
ok ($fq eq "\@test_seq\nAAGTTTCAAA\n+\n6666666666\n", "as FASTQ");

$obj->qual('TOOSHORT');
throws_ok { $obj->as_fastq } qr/length mismatch/, 'length mismatch check';
$obj->qual( 'A'. 'C' x (length($obj)-1) );
$obj->desc("testing it");
ok ($obj->rev_com->as_fastq eq "\@test_seq testing it\nAAGTTTCAAA\n+\nCCCCCCCCCA\n", "as FASTQ 2");
$sub = $obj->range(0,1);
ok (! defined $sub, "out of range 2");
$sub = $obj->range(2,3);
ok ($sub->qual eq 'CC', "range quality");

my $fa = $obj->as_fasta(4);
ok ($fa eq ">test_seq testing it\nTTTG\nAAAC\nTT\n", "as FASTA short lines");

$obj->seq( 'AATGYTAAT' );
$obj->translate;
ok ($obj->seq() eq 'NXN', "in-place translate");


# check new sequence with bad quality
throws_ok { $obj = BioX::Seq->new(
    'ATGC',
    'foo',
    'bar',
    'CCC'
) } qr/length mismatch/, 'new() length mismatch check';

#----------------------------------------------------------------------------#
# FASTA testing
#----------------------------------------------------------------------------#

open my $in, '<', $test_fa;
my $parser = BioX::Seq::Stream->new($in);

ok ($parser->isa('BioX::Seq::Stream::FASTA'), "returned BioX::Seq::Stream::FASTA object");

my $seq = $parser->next_seq;
ok ($seq->isa('BioX::Seq'), "returned BioX::Seq object");

ok ($seq->id eq 'Test1|someseq', "read seq ID");
ok ($seq->seq eq 'AATGCAAGTACGTAAGACTTATAGCAGTAGGATGGAATGATAGCCATAG', "read seq ");
ok ($seq->desc eq 'This is a test of the emergency broadcast system', "read desc");
ok (! defined $seq->qual, "undefined qual");

$seq = $parser->next_seq;
ok ($seq->seq eq 'TTAGATTGATTTTTAGATAGGA', "read 2nd seq ");
$seq = $parser->next_seq;
ok ($seq->seq eq 'GTTAGAGCCAGGAACGAGAACGA', "read 3rd seq ");
$seq = $parser->next_seq;
ok ($seq->seq eq 'WWFWWFWWFWWFWWFWWFWWFWWFWWF', "read 4th seq ");
$seq->translate();
ok ($seq->seq eq 'WWFWWFWWFWWFWWFWWFWWFWWFWWF', "invalid translate");
my $invalid = $seq->translate();
ok (! defined $invalid, "invalid translate undef");

close $in;

#read from STDIN
{
    open my $stdin, '<', $test_fa;
    local *STDIN = $stdin;
    my $parser = BioX::Seq::Stream->new();
    my $seq = $parser->next_seq;
    ok ($seq->id eq 'Test1|someseq', "read seq ID");
    ok ($seq->seq eq 'AATGCAAGTACGTAAGACTTATAGCAGTAGGATGGAATGATAGCCATAG', "read seq ");
    close $stdin;
}

# missing any line endings
throws_ok { BioX::Seq::Stream->new($test_oneline_fa) } qr/detect line endings/,
    "missing fasta line endings";
throws_ok { BioX::Seq::Stream->new($test_oneline_fq) } qr/detect line endings/,
    "missing fastq line endings";

# bad header line
$parser = BioX::Seq::Stream->new($test_badheader);
throws_ok { while ($parser->next_seq) {} } qr/record invalid/,
    "bad FASTA header";

# test a real-world file
$parser = BioX::Seq::Stream->new($test_large);
my $n = 0;
my $t = 0;
while (my $seq = $parser->next_seq) {
    ++$n;
    $t += length $seq;
}
ok ($n == 50, "correct sequence count");
ok ($t == 19379, "correct sequence lengths");

# test a real-world file in 'fast' mode
$parser = BioX::Seq::Stream->new($test_large, fast => 1);
$n = 0;
$t = 0;
while (my $seq = $parser->next_seq) {
    ++$n;
    $t += length $seq;
}
ok ($n == 50, "correct sequence count");
ok ($t == 19379, "correct sequence lengths");

#----------------------------------------------------------------------------#
# gzip testing
#----------------------------------------------------------------------------#

$parser = BioX::Seq::Stream->new($test_gz);

ok ($parser->isa('BioX::Seq::Stream::FASTA'), "returned BioX::Seq::Stream::FASTA object");

$seq = $parser->next_seq;
ok ($seq->isa('BioX::Seq'), "returned BioX::Seq object");

ok ($seq->id eq 'Test1|someseq', "read seq ID");
ok ($seq->seq eq 'AATGCAAGTACGTAAGACTTATAGCAGTAGGATGGAATGATAGCCATAG', "read seq ");
ok ($seq->desc eq 'This is a test of the emergency broadcast system', "read desc");
ok (! defined $seq->qual, "undefined qual");

# simulate when 'gzip' binary is missing
my $gzip_bin_tmp = $BioX::Seq::Stream::GZIP_BIN;
$BioX::Seq::Stream::GZIP_BIN = undef;

$parser = BioX::Seq::Stream->new($test_gz);

$seq = $parser->next_seq;
ok ($seq->id eq 'Test1|someseq', "read seq ID");
ok ($seq->seq eq 'AATGCAAGTACGTAAGACTTATAGCAGTAGGATGGAATGATAGCCATAG', "read seq ");
ok ($seq->desc eq 'This is a test of the emergency broadcast system', "read desc");
ok (! defined $seq->qual, "undefined qual");

$BioX::Seq::Stream::GZIP_BIN = $gzip_bin_tmp;

throws_ok { BioX::Seq::Stream->new('nonexistent_file') } qr/Error opening/, "bad filename";

# simulate when 'gzip' binary is bad
$BioX::Seq::Stream::GZIP_BIN = 'nonexistent';
throws_ok { BioX::Seq::Stream->new($test_gz) } qr/[Error opening|not recognized]/, "bad gzip binary";
$BioX::Seq::Stream::GZIP_BIN = $gzip_bin_tmp;

#----------------------------------------------------------------------------#
# zstd testing
#----------------------------------------------------------------------------#
if (can_run( 'zstd') ) {

    $parser = BioX::Seq::Stream->new($test_zst);

    ok ($parser->isa('BioX::Seq::Stream::FASTA'), "returned BioX::Seq::Stream::FASTA object");

    $seq = $parser->next_seq;
    ok ($seq->isa('BioX::Seq'), "returned BioX::Seq object");

    ok ($seq->id eq 'Test1|someseq', "read seq ID");
    ok ($seq->seq eq 'AATGCAAGTACGTAAGACTTATAGCAGTAGGATGGAATGATAGCCATAG', "read seq ");
    ok ($seq->desc eq 'This is a test of the emergency broadcast system', "read desc");
    ok (! defined $seq->qual, "undefined qual");

}

#----------------------------------------------------------------------------#
# FASTQ / bzip2 testing
#----------------------------------------------------------------------------#

$parser = BioX::Seq::Stream->new($test_fq);

ok ($parser->isa('BioX::Seq::Stream::FASTQ'), "returned BioX::Seq::Stream::FASTQ object");

$seq = $parser->next_seq;
ok ($seq->seq eq 'ATTGAGGGGATTGAGATAGGGTGGAGTANNNTGGAT', "read seq");
ok ($seq->id eq 'Test1', "read id");
ok ($seq->desc eq 'some description here', "read desc");
ok ($seq->qual eq '433229299291929292922291919292292211', "read qual");

$seq = $parser->next_seq;
ok ($seq->seq eq 'ATTGAGAATGACCGATAAACT', "read 2nd seq");
ok ($seq->qual eq '@11944491019494440111', "read 2nd qual");

# this one should throw error
eval {
    $seq = $parser->next_seq;
};
ok ($seq->seq eq 'ATTGAGAATGACCGATAAACT', "seq unchanged");

# simulate when 'bzip2' binary is missing
my $bzip2_bin_tmp = $BioX::Seq::Stream::BZIP_BIN;
$BioX::Seq::Stream::BZIP_BIN = undef;

$parser = BioX::Seq::Stream->new($test_fq);

$seq = $parser->next_seq;
ok ($seq->seq eq 'ATTGAGGGGATTGAGATAGGGTGGAGTANNNTGGAT', "read seq");
ok ($seq->id eq 'Test1', "read id");
ok ($seq->desc eq 'some description here', "read desc");
ok ($seq->qual eq '433229299291929292922291919292292211', "read qual");

$BioX::Seq::Stream::BZIP_BIN = $bzip2_bin_tmp;

# simulate when 'bzip2' binary is bad
$BioX::Seq::Stream::BZIP_BIN = 'nonexistent';
throws_ok { BioX::Seq::Stream->new($test_fq) } qr/[Error opening|not recognized]/, "bad bzip2 binary";
$BioX::Seq::Stream::BZIP_BIN = $bzip2_bin_tmp;

#----------------------------------------------------------------------------#
# TwoBit testing
#----------------------------------------------------------------------------#

open my $twobit, '<', $test_2bit;
$parser = BioX::Seq::Stream->new($twobit);

ok( $parser->isa('BioX::Seq::Stream::TwoBit'),
    "returned BioX::Seq::Stream::TwoBit object" );

for (1..3) {
    $seq = $parser->next_seq;
}
ok( $seq->seq eq 'ATTAGggagNNnTAGGC', "read 2bit seq" );
ok( $seq->id eq 'seq_03', "read 2bit id" );

#----------------------------------------------------------------------------#
# dsrc testing
#----------------------------------------------------------------------------#

# 2020-12-19: Testing of DSRC has been disabled since there is not currently a
# stable DSRC release (building the latest from GitHub master is *somewhat*
# stable)
if (0 &&  can_run('dsrc') ) {

    $parser = BioX::Seq::Stream->new($test_dsrc);

    ok ($parser->isa('BioX::Seq::Stream::FASTQ'), "returned BioX::Seq::Stream::FASTQ object");

    $seq = $parser->next_seq;
    ok ($seq->isa('BioX::Seq'), "returned BioX::Seq object");
    ok ($seq->seq eq 'ATTGAGGGGATTGAGATAGGGTGGAGTANNNTGGAT', "read seq");
    ok ($seq->id eq 'Test1', "read id");
    ok ($seq->desc eq 'some description here', "read desc");
    ok ($seq->qual eq '4332292992919292929222919192!!!92211', "read qual");

    $seq = $parser->next_seq;
    ok ($seq->seq eq 'ATTGAGAATGACCGATAAACT', "read 2nd seq");
    ok ($seq->qual eq '@11944491019494440111', "read 2nd qual");

}

#----------------------------------------------------------------------------#
# fzqcomp testing
#----------------------------------------------------------------------------#

if ( can_run('fqz_comp') ) {

    $parser = BioX::Seq::Stream->new($test_fqz);

    ok ($parser->isa('BioX::Seq::Stream::FASTQ'), "returned BioX::Seq::Stream::FASTQ object");

    $seq = $parser->next_seq;
    ok ($seq->isa('BioX::Seq'), "returned BioX::Seq object");
    ok ($seq->seq eq 'ATTGAGGGGATTGAGATAGGGTGGAGTANNNTGGAT', "read seq");
    ok ($seq->id eq 'Test1', "read id");
    ok ($seq->desc eq 'some description here', "read desc");
    ok ($seq->qual eq '4332292992919292929222919192!!!92211', "read qual");

    $seq = $parser->next_seq;
    ok ($seq->seq eq 'ATTGAGAATGACCGATAAACT', "read 2nd seq");
    ok ($seq->qual eq '@11944491019494440111', "read 2nd qual");

}

#----------------------------------------------------------------------------#
# xz testing
#----------------------------------------------------------------------------#

if (can_run( 'xz') ) {

    $parser = BioX::Seq::Stream->new($test_xz);

    ok ($parser->isa('BioX::Seq::Stream::FASTA'), "returned BioX::Seq::Stream::FASTA object");

    $seq = $parser->next_seq;
    ok ($seq->isa('BioX::Seq'), "returned BioX::Seq object");

    ok ($seq->id eq 'Test1|someseq', "read seq ID");
    ok ($seq->seq eq 'AATGCAAGTACGTAAGACTTATAGCAGTAGGATGGAATGATAGCCATAG', "read seq ");
    ok ($seq->desc eq 'This is a test of the emergency broadcast system', "read desc");
    ok (! defined $seq->qual, "undefined qual");

}

#----------------------------------------------------------------------------#
# Fetch testing
#----------------------------------------------------------------------------#

$parser = BioX::Seq::Fetch->new($test_gz, with_description => 0);
ok(! compare($test_fai, $test_fai_cmp), "Compare indices" );
$parser->write_index($test_fai_expl);
ok(! compare($test_fai_expl, $test_fai_cmp), "Compare indices 2" );

$seq = $parser->fetch_seq('Prot1', 1 => 1);
ok( $seq->seq eq 'W', "fetch seq match 2" );

$seq = $parser->fetch_seq('Test3/yetanother');
ok( $seq->seq eq 'GTTAGAGCCAGGAACGAGAACGA', "fetch seq match 3" );

$seq = $parser->fetch_seq('Test1|someseq', 28 => 33);
ok( $seq->seq eq 'TAGGAT', "fetch seq match 1" );

# should not have description
$seq = $parser->fetch_seq('Test1|another');
ok( ! defined $seq->desc );


my @ids = $parser->ids;
ok( scalar(@ids) == 4, "ID count" );
ok( $ids[1] eq 'Test1|another', "ID comparison" );
my $l = $parser->length($ids[2]);
ok( $parser->length($ids[2]) == 23, "length comparison" );

# now try to get descriptions
$parser = BioX::Seq::Fetch->new($test_gz, with_description => 1);
$seq = $parser->fetch_seq('Test1|another');
ok( $seq->desc eq 'This is a second test' );

# non-gzipped
$parser = BioX::Seq::Fetch->new($test2_fa, with_description => 0);
$seq = $parser->fetch_seq('Test1|someseq');
ok( $seq->seq eq 'AATGCAAGTACGTAAGACTTATAGCAGTAGGATGGAATGATAGCCATAG', "fetch non-gz" );

# out-of-bounds
throws_ok { $seq = $parser->fetch_seq('Test1|someseq',-1,3) } qr/out of bounds/, "Fetch too low";
throws_ok { $seq = $parser->fetch_seq('Test1|someseq',1,300) } qr/out of bounds/, "Fetch too high";

#misc error conditions
throws_ok { BioX::Seq::Fetch->new(undef) } qr/Must define/, "Fetch undefined filename";
throws_ok { BioX::Seq::Fetch->new('nonexistent_file') } qr/Error opening/, "Fetch nonexistent filename";
throws_ok { BioX::Seq::Fetch->new($test_notbgzip) } qr/with bgzip/, "Fetch with regular gzip";
throws_ok { BioX::Seq::Fetch->new($test_bad) } qr/Unexpected content/, "Fetch invalid chars";
throws_ok { BioX::Seq::Fetch->new($test_fa) } qr/Base length mismatch/, "Fetch uneven lines";
throws_ok { BioX::Seq::Fetch->new($test_endings) } qr/Line length mismatch/, "Fetch weird line endings";
throws_ok { BioX::Seq::Fetch->new($test_duplicates) } qr/duplicate entries/, "Fetch duplicate IDs";

#----------------------------------------------------------------------------#
# Fetch utils
#----------------------------------------------------------------------------#

# rev_com()
$seq = 'AATGAGACAGGTGNNRSGGG';
my $rc = rev_com($seq);
ok( $rc eq 'CCCSYNNCACCTGTCTCATT', "check rev_com()" );

# is_nucleic()

my $aa = 'MERTTSQYPAVARS';
ok( ! is_nucleic($aa), "check amino acid" );
ok(   is_nucleic($rc), "check nucleic acid" );

# all_orfs() / build_ORF_regex()

$parser = BioX::Seq::Stream->new($test_orfs);
$seq = $parser->next_seq();
my $orf = $parser->next_seq();
my @orfs = all_orfs(
    $seq,
    3,
    300,
);
ok( scalar(@orfs) == 4, "check ORF count" );
ok( $orfs[1]->[0] eq "$orf", "check ORF seq" );
ok( $orfs[1]->[1] == 1784, "check ORF start" );
ok( $orfs[1]->[2] == 1371, "check ORF stop" );

@orfs = all_orfs(
    $seq,
    0,
    300,
);

ok( scalar(@orfs) == 5, "check ORF count 2" );

throws_ok { all_orfs($seq) } qr/Missing mode/, "missing mode";
throws_ok { all_orfs($seq, 0) } qr/Missing min/, "missing minimum length";

throws_ok { BioX::Seq::Stream->new($test_onebyte) } qr/initial bytes/, "truncated input";

throws_ok { BioX::Seq::Stream->new($test_foobar) } qr/Failed to guess/, "non-sequence input";

# simulate missing zstd
my $zstd_bin_tmp = $BioX::Seq::Stream::ZSTD_BIN;
$BioX::Seq::Stream::ZSTD_BIN = undef;
throws_ok { BioX::Seq::Stream->new($test_zst) } qr/no zstd/, "missing zstd";
$BioX::Seq::Stream::ZSTD_BIN = 'nonexistent';
throws_ok { BioX::Seq::Stream->new($test_zst) } qr/[Error opening|not recognized]/, "bad zstd binary";
$BioX::Seq::Stream::ZSTD_BIN = $zstd_bin_tmp;

# simulate missing dsrc
my $dsrc_bin_tmp = $BioX::Seq::Stream::DSRC_BIN;
$BioX::Seq::Stream::DSRC_BIN = undef;
throws_ok { BioX::Seq::Stream->new($test_dsrc) } qr/no dsrc/, "missing dsrc";
$BioX::Seq::Stream::DSRC_BIN = 'nonexistent';
throws_ok { BioX::Seq::Stream->new($test_dsrc) } qr/[Error opening|not recognized]/, "bad dsrc binary";
$BioX::Seq::Stream::DSRC_BIN = $dsrc_bin_tmp;

# simulate missing fqzc
my $fqzc_bin_tmp = $BioX::Seq::Stream::FQZC_BIN;
$BioX::Seq::Stream::FQZC_BIN = undef;
throws_ok { BioX::Seq::Stream->new($test_fqz) } qr/no fqz/, "missing fqz";
$BioX::Seq::Stream::FQZC_BIN = 'nonexistent bin';
throws_ok { BioX::Seq::Stream->new($test_fqz) } qr/[Error opening|not recognized]/, "bad fqz binary";
$BioX::Seq::Stream::FQZC_BIN = $fqzc_bin_tmp;

#----------------------------------------------------------------------------#
# Finish up
#----------------------------------------------------------------------------#

unlink $_ for (@tmp_files);

done_testing();
exit;
