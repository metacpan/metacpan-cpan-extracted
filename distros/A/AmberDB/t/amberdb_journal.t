#!/usr/bin/perl

# t/amberdb_journal.t - Unit tests for journal encoding, append, read, rotate, and scan

use 5.016000;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use lib "$Bin/../lib", 'lib';
use AmberDB;

my $tmpdir = tempdir( CLEANUP => 1 );
my $adb = AmberDB->new(
    path => { dbase_dir => $tmpdir },
);

subtest '1. Journal encode & decode' => sub {
    plan tests => 13;

    # Test 1: Record without pos
    my $line1 = $adb->journal_encode( 'recs', 'catalog_product', '/db/product.db', 1001, 'add', '', "Sample data|123", 1741512300 );
    like( $line1, qr/^1741512300\trecs\tcatalog_product\t\/db\/product\.db\t1001\tadd\t\t/, 'Line1 encoded properly with empty pos' );

    my $dec1 = $adb->journal_decode($line1);
    is( $dec1->{epoch}, 1741512300, 'Epoch decoded' );
    is( $dec1->{type}, 'recs', 'Type decoded' );
    is( $dec1->{tableid}, 'catalog_product', 'Tableid decoded' );
    is( $dec1->{file_path}, '/db/product.db', 'File path decoded' );
    is( $dec1->{key}, 1001, 'Key decoded' );
    is( $dec1->{action}, 'add', 'Action decoded' );
    ok( !defined $dec1->{pos}, 'Empty pos decoded as undef' );
    is( $dec1->{payload}, "Sample data|123", 'Payload restored from Base64' );

    # Test 2: Index with fixed byte offset (pos = 8000000)
    my $packed_id = pack( "Q>", 1000001 );
    my $line2 = $adb->journal_encode( 'index', 'catalog_product', '/db/product.inx', 'keys', 'append', 8000000, $packed_id, 1741512305 );
    my $dec2 = $adb->journal_decode($line2);
    is( $dec2->{pos}, 8000000, 'Fixed pos 8000000 decoded as number' );
    is( $dec2->{payload}, $packed_id, 'Binary payload matches raw bytes' );

    # Test 3: Null payload (e.g. del)
    my $line3 = $adb->journal_encode( 'recs', 'catalog_product', '/db/product.db', 1001, 'del', '', undef, 1741512310 );
    my $dec3 = $adb->journal_decode($line3);
    is( $dec3->{action}, 'del', 'Del action' );
    ok( !defined $dec3->{payload}, 'Null payload decoded as undef' );
};

subtest '2. Journal append, read, rotate, and scan' => sub {
    plan tests => 9;

    my $entry1 = [ 'recs', 'test_tbl', '/db/test.db', 1, 'add', '', "Item 1", 1741512300 ];
    my $entry2 = [ 'recs', 'test_tbl', '/db/test.db', 2, 'add', '', "Item 2", 1741512301 ];

    # Append to slot "sync_ramdisk" -> dbstore/journal/sync_ramdisk
    ok( $adb->journal_append( 'sync_ramdisk', $entry1, $entry2 ), 'Appended 2 entries to sync_ramdisk' );

    # Read back
    my @read = $adb->journal_read('sync_ramdisk');
    is( scalar(@read), 2, 'Read 2 entries back' );
    is( $read[0]->{key}, 1, 'First entry key' );
    is( $read[1]->{key}, 2, 'Second entry key' );

    # Rotate
    my $rotated = $adb->journal_rotate( 'sync_ramdisk', 1741512300 );
    ok( defined $rotated && -e $rotated, "Rotated file exists: $rotated" );
    like( $rotated, qr/sync_ramdisk_1741512300$/, 'Rotated file matches exact naming pattern' );

    # Scan rotated files
    my @scanned = $adb->journal_scan('sync_ramdisk_');
    is( scalar(@scanned), 1, 'Found 1 rotated sync journal' );
    is( $scanned[0], $rotated, 'Scanned path matches rotated path' );

    # Delete rotated file
    $adb->journal_delete($rotated);
    ok( !-e $rotated, 'Rotated journal deleted successfully' );
};

done_testing();
