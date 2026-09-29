#!/usr/bin/env perl
use 5.016;
use warnings;
use utf8;
use open ':std', ':utf8';
use Test::More;
binmode Test::More->builder->output,         ':utf8';
binmode Test::More->builder->failure_output, ':utf8';
binmode Test::More->builder->todo_output,    ':utf8';
use File::Temp qw(tempdir);
use File::Spec;

use lib 'lib';
use AmberDB;

my $temp_dir = tempdir( CLEANUP => 1 );
my $adb = AmberDB->new( path => { dbase_dir => $temp_dir } );
isa_ok( $adb, 'AmberDB' );

# 1. char_escape & char_unescape unit tests
subtest 'char_escape and char_unescape roundtrip' => sub {
    plan tests => 7;

    # Test A: Windows path
    my $win_path = 'C:\temp\notes\read.txt';
    my $esc_win  = $adb->char_escape($win_path);
    is( $esc_win, 'C:&#92;temp&#92;notes&#92;read.txt', 'Windows path escaped with &#92;' );
    my $unesc_win = $adb->char_unescape($esc_win);
    is( $unesc_win, $win_path, 'Windows path unescaped correctly without TAB/LF corruption' );

    # Test B: Literal TAB, LF, CR
    my $ctrl_str = "Line1\nLine2\rLine3\tColumn";
    my $esc_ctrl = $adb->char_escape($ctrl_str);
    is( $esc_ctrl, "Line1\\nLine2\\rLine3\\tColumn", 'Control chars escaped as \n, \r, \t' );
    my $unesc_ctrl = $adb->char_unescape($esc_ctrl);
    is( $unesc_ctrl, $ctrl_str, 'Control chars unescaped correctly' );

    # Test C: Delimiters and ampersand
    my $delims = 'A & B | C = D &#92; End';
    my $esc_delims = $adb->char_escape($delims);
    is( $esc_delims, 'A &#38; B &#124; C &#61; D &#38;#92; End', 'Delimiters and & escaped' );
    my $unesc_delims = $adb->char_unescape($esc_delims);
    is( $unesc_delims, $delims, 'Delimiters unescaped correctly without double-decode' );

    # Test D: Legacy \\ unescaping
    my $legacy_str = 'C:\\\\temp\\\\notes';
    my $unesc_legacy = $adb->char_unescape($legacy_str);
    is( $unesc_legacy, 'C:\temp\notes', 'Legacy double-backslash unescaped correctly' );
};

# 2. db_encode & db_decode scalar roundtrip
subtest 'db_encode and db_decode scalar fields' => sub {
    plan tests => 4;

    my @orig_fields = (
        101,
        'C:\temp\app.log',
        "Multi-line\ndescription\twith tab",
        'Param key=value & category|tag',
        'Normal text'
    );

    my $encoded = $adb->db_encode(@orig_fields);
    ok( defined $encoded && length($encoded), 'db_encode produced encoded string' );

    my @decoded = $adb->db_decode($encoded);
    is_deeply( \@decoded, \@orig_fields, 'db_decode restored all fields identically' );

    # Ensure field 1 is not corrupted
    is( $decoded[1], 'C:\temp\app.log', 'Windows path field preserved' );
    is( $decoded[2], "Multi-line\ndescription\twith tab", 'Multiline and tab field preserved' );
};

# 3. db_encode & db_decode nested ARRAY & HASH structures
subtest 'db_encode and db_decode nested data structures' => sub {
    plan tests => 3;

    my $data_array = [ 'C:\windows\system32', 'D:\files\notes.txt', "A=B|C&D" ];
    my $encoded_arr = $adb->db_encode($data_array);
    my $decoded_arr = $adb->db_decode($encoded_arr);
    is_deeply( $decoded_arr, $data_array, 'Nested ARRAY with paths and delims restored' );

    my $data_hash = {
        path => 'C:\temp\data',
        desc => "Notes:\n- item 1\tval\n- item 2",
        spec => 'price=100|stock=20&active=1'
    };
    my $encoded_hash = $adb->db_encode($data_hash);
    my $decoded_hash = $adb->db_decode($encoded_hash);
    is_deeply( $decoded_hash, $data_hash, 'Nested HASH with paths, newlines, and delims restored' );

    # Mixed record with scalars and references
    my @mixed_record = ( 1, 'Product A', [ 'C:\img\front.jpg', 'C:\img\back.jpg' ], { brand => 'Acme & Co.', model => 'X-100' } );
    my $encoded_mixed = $adb->db_encode(@mixed_record);
    my @decoded_mixed = $adb->db_decode($encoded_mixed);
    is_deeply( \@decoded_mixed, \@mixed_record, 'Mixed record with scalars and refs restored' );
};

# 4. Insert and Read via Berkeley DB table
subtest 'Table insert_id and read_id roundtrip' => sub {
    plan tests => 4;

    my $table = 'test_paths';
    my $id = 1;
    my @record = (
        'C:\Program Files\AmberDB',
        'C:\temp\cache.db',
        "Log entry:\nStatus: OK\tTime: 12:00",
        'Key=Val&Ref|Flag'
    );

    my $saved_id = $adb->insert_id( $table, $id, @record );
    is( $saved_id, $id, 'insert_id succeeded' );

    my @read_recs = $adb->read_id( $table, $id );
    is( $read_recs[0], $id, 'read_id returned correct ID' );
    is( $read_recs[1], 'C:\Program Files\AmberDB', 'Path 1 preserved from disk' );
    is( $read_recs[2], 'C:\temp\cache.db', 'Path 2 preserved from disk without TAB conversion' );
};

# 5. Comprehensive edge-case roundtrip scenarios
subtest 'Comprehensive 7 edge-case roundtrip scenarios' => sub {
    plan tests => 7;

    my @cases = (
        [ 'C:\temp\notes', 'Windows path' ],
        [ "line1\nline2\ttabbed\rcr", 'Real LF, TAB, CR' ],
        [ 'a&b|c=d', 'Delimiters & | =' ],
        [ '&#92;literal entity text', 'Literal entity text' ],
        [ 'back\slash\end', 'Arbitrary backslashes' ],
        [ "mixed \\n not-a-newline and \t real-tab", 'Literal \n text mixed with real TAB' ],
        [ 'Keşanlı & ürün adı = "fiyat|indirim"', 'Turkish characters with delims' ],
    );

    for my $c (@cases) {
        my ($input, $label) = @$c;
        my $encoded = $adb->db_encode($input);
        my $decoded = $adb->db_decode($encoded);
        is( $decoded, $input, "[OK] $label: $input" );
    }
};

# 6. Single HASH / ARRAY document-store records and deep nested structures
subtest 'Table single HASH and deep nested structures roundtrip' => sub {
    plan tests => 9;

    my $table = 'doc_store';

    # 1. Single HASH record without schema (e.g. data='{"name":"Ahmet"}')
    my $user_doc = { name => 'Ahmet', role => 'admin', active => 1 };
    my $uid = $adb->insert_id( $table, 0, $user_doc );
    ok( defined $uid && $uid > 0, "Single HASH record inserted with ID $uid" );

    my @read_user = $adb->read_id( $table, $uid );
    is( $read_user[0], $uid, "read_id returned ID $uid" );
    is( ref( $read_user[1] ), 'HASH', "Record payload is a HASH reference (not stringified 'HASH(0x...)')" );
    is_deeply( $read_user[1], $user_doc, "Record payload matches exact original HASH" );

    # 2. Mixed record with nested array, nested hash, and multi-level hierarchy
    my $complex_rec = [
        'Device Node',
        {
            sensors => [ { type => 'temp', val => 24.5 }, { type => 'humidity', val => 60 } ],
            network => { ip => '192.168.1.50', ports => [ 80, 443 ] },
        },
        [ 'alpha', 'beta', [ 100, 200 ] ]
    ];
    my $cid = $adb->insert_id( $table, 0, @$complex_rec );
    ok( defined $cid && $cid > 0, "Complex nested record inserted with ID $cid" );

    my @read_complex = $adb->read_id( $table, $cid );
    is( $read_complex[0], $cid, "Complex read returned ID $cid" );
    is_deeply( [ @read_complex[ 1 .. $#read_complex ] ], $complex_rec, "Deeply nested array/hash hierarchy restored intact" );

    # 3. Update single HASH record
    my $updated_doc = { name => 'Mehmet', role => 'editor', active => 0 };
    my $up_res = $adb->update_id( $table, $uid, $updated_doc );
    ok( $up_res, "update_id on single HASH record succeeded" );
    my @read_up = $adb->read_id( $table, $uid );
    is_deeply( $read_up[1], $updated_doc, "Updated single HASH record restored intact" );
};

done_testing();

