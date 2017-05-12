#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use FindBin;
use Digest::MD5;
use Compress::DSRC;


# There is a bug in the stable source relating to single-record files.
# A patched source is included - we explicity test such files here as well
my @fn_compressed   = qw/foo.dsrc foo.single.dsrc/;
my @fn_uncompressed = qw/foo.fastq foo.single.fastq/;

chdir $FindBin::Bin;

require_ok("Compress::DSRC");

my $settings = Compress::DSRC::Settings->new();
$settings->set_dna_level(1);
$settings->set_qual_level(1);
$settings->set_lossy(0);
$settings->set_buffer_size(64);

my $settings_lossy = Compress::DSRC::Settings->new();
$settings_lossy->set_dna_level(2);
$settings_lossy->set_qual_level(2);
$settings_lossy->set_lossy(1);
$settings_lossy->set_buffer_size(128);

for my $i (0..$#fn_compressed) {

    my $m = Compress::DSRC::Module->new();
    my $r = Compress::DSRC::Reader->new();
    my $w = Compress::DSRC::Writer->new();

    my $fn_c = $fn_compressed[$i];
    my $fn_u = $fn_uncompressed[$i];

    #------------------------------------------------------------------------#
    # test one-shot (de)compression
    #------------------------------------------------------------------------#

    ok( $m->compress($fn_u => 'bar.dsrc', $settings, 1),
        "one-shot compression" );
    ok( $m->compress($fn_u => 'bar.lossy.dsrc', $settings_lossy, 1),
        "one-shot compression (lossy)" );
    ok( $m->decompress($fn_c => 'bar.fastq', 1),
        "one-shot decompression 1" );
    ok( $m->decompress('bar.dsrc' => 'baz.fastq', 1),
        "one-shot decompression 2" );
    ok( $m->decompress('bar.lossy.dsrc' => 'baz.lossy.fastq', 1),
        "one-shot decompression 3" );

    my $md5_foo = Digest::MD5->new();
    my $md5_bar = Digest::MD5->new();
    my $md5_baz = Digest::MD5->new();
    my $md5_baz_lossy = Digest::MD5->new();
    open my $fh_foo, '<:raw', $fn_u;
    open my $fh_bar, '<:raw', 'bar.fastq';
    open my $fh_baz, '<:raw', 'baz.fastq';
    open my $fh_baz_lossy, '<:raw', 'baz.lossy.fastq';
    $md5_foo->addfile($fh_foo);
    $md5_bar->addfile($fh_bar);
    $md5_baz->addfile($fh_baz);
    $md5_baz_lossy->addfile($fh_baz_lossy);
    my $orig = $md5_foo->hexdigest;
    ok( $orig eq $md5_bar->hexdigest,       "files are identical"            );
    ok( $orig eq $md5_baz->hexdigest,       "round-trip files are identical" );
    ok( $orig ne $md5_baz_lossy->hexdigest, "lossy files are not identical"  );


    #------------------------------------------------------------------------#
    # test by-record decompression
    #------------------------------------------------------------------------#

    ok( $r->start($fn_c, 1), "started stream decompression" );
    ok( $w->start('bee.dsrc', $settings, 1), "started stream compression" );

    seek $fh_foo, 0, 0;

    my $read_count = 0;
    my $passed = 0;
    while (my $read = $r->next_record) {
        ++$read_count;
        chomp(my $orig_id = <$fh_foo>);
        $passed += $orig_id eq $read->get_tag;
        chomp(my $orig_seq = <$fh_foo>);
        $passed += $orig_seq eq $read->get_sequence;
        chomp(my $orig_plus = <$fh_foo>);
        $passed += $orig_plus eq $read->get_plus;
        chomp(my $orig_qual = <$fh_foo>);
        $passed += $orig_qual eq $read->get_quality;

        my $rec = Compress::DSRC::Record->new();
        $rec->set_tag( $orig_id );
        $rec->set_sequence( $orig_seq );
        $rec->set_quality( $orig_qual );
        $rec->set_plus('+');
        $w->write_record( $rec );
    }
    ok( $read_count > 0 && $read_count*4 == $passed,
        "streaming records identical" );
    $r->finish();
    $w->finish();

    ok( $m->decompress('bee.dsrc' => 'bee.fastq', 1),
        "one-shot decompression 4" );

    my $md5_bee = Digest::MD5->new();
    open my $fh_bee, '<:raw', 'bee.fastq';
    $md5_bee->addfile($fh_bee);
    ok( $orig eq $md5_bee->hexdigest, "streamed files are identical" );

    unlink qw/bar.dsrc bar.lossy.dsrc bar.fastq baz.fastq
        baz.lossy.fastq bee.dsrc bee.fastq/;

}

done_testing();
exit;

