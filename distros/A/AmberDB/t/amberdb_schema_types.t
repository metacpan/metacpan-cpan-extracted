use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use lib 'lib';
use AmberDB;

my $tmp_dir = tempdir( CLEANUP => 1 );

# ============================================================
# 1. Setup Test Schema with 8 Core Types
# ============================================================
subtest '1. Schema Setup with 8 Core Types' => sub {
    my $db_dir     = "$tmp_dir/db_types";
    my $schema_dir = "$db_dir/schema";
    my $table_dir  = "$db_dir/table";
    mkdir($db_dir);
    mkdir($schema_dir);
    mkdir($table_dir);

    my $adb = AmberDB->new(
        path => {
            dbase_dir  => $db_dir,
            schema_dir => $schema_dir,
            table_dir  => $table_dir,
        },
    );

    # Create schema with blocks for all 8 types
    my $schema = {
        name         => "Product Types Test",
        record_index => 1,
        blocks       => [
            { id => "id",         name => "ID",            type => "auto_id", input => "hidden" },
            { id => "title",      name => "Ürün Başlığı",  type => "text",    input => "text" },
            { id => "price",      name => "Fiyat",         type => "num",     input => "number" },
            { id => "discount",   name => "İndirim Oranı", type => "number",  input => "number" },
            { id => "balance",    name => "Bakiye",        type => "num",     input => "number" },
            { id => "code",       name => "Ürün Kodu",     type => "ascii",   input => "ascii" },
            { id => "created_at", name => "Oluşturulma",   type => "date",    input => "date", valid => "auto_date" },
            { id => "tags",       name => "Etiketler",     type => "array",   input => "checkbox" },
            { id => "meta",       name => "Meta Veri",     type => "hash",    input => "text" },
            { id => "raw_blob",   name => "Binary Veri",   type => "binary",  input => "file" },
        ],
    };

    my $ok = $adb->table_infset( "products", $schema );
    ok( $ok, "table_infset created schema for products" );

    my $info = $adb->table_info("products");
    is( scalar( @{ $info->{blocks} } ), 10, "Schema has 10 block definitions" );
};

# ============================================================
# 2. enc_validate & dec_validate Unit Verification
# ============================================================
subtest '2. enc_validate & dec_validate Direct Unit Tests' => sub {
    my $db_dir = "$tmp_dir/db_types";
    my $adb = AmberDB->new( path => { dbase_dir => $db_dir } );

    # Raw input fields (Blocks 1..9)
    my @raw_input = (
        "Türkçe Kitap & Başlık", # 1: text
        "  150.75  ",            # 2: num (float with whitespace)
        "-25.50",                # 3: number (negative float)
        "invalid_num",           # 4: num (invalid string -> 0)
        "Ürün_Kodu_#105",        # 5: ascii (Turkish chars -> ASCII)
        "",                      # 6: date (empty + auto_date -> today)
        "elektronik,telefon",    # 7: array (comma string -> array ref)
        { color => "Mavi" },     # 8: hash (hash ref)
        "BINARY_BLOB_XYZ",       # 9: binary
    );

    my @enc = $adb->enc_validate( "products", \@raw_input );
    is( $enc[0], "Türkçe Kitap & Başlık", "1. text preserved in enc_validate" );
    is( $enc[1], 150.75,                  "2. num trimmed and cast to float" );
    is( $enc[2], -25.50,                  "3. negative number cast correctly" );
    is( $enc[3], 0,                       "4. invalid number defaulted to 0" );
    like( $enc[4], qr/^Urun_Kodu_/,       "5. ascii normalized to ASCII" );
    like( $enc[5], qr/^\d{4}-\d{2}-\d{2}$/, "6. auto_date populated current ISO date" );
    is_deeply( $enc[6], [ "elektronik", "telefon" ], "7. array string converted to ARRAY ref" );
    is_deeply( $enc[7], { color => "Mavi" }, "8. hash ref preserved" );
    is( $enc[8], "BINARY_BLOB_XYZ",       "9. binary scalar preserved" );

    # Test dec_validate
    my @dec_input = (
        "Türkçe Kitap", # 1: text
        "200.5",        # 2: num
        "-50",          # 3: number (negative)
        "",             # 4: num (empty string -> 0)
        "CODE123",      # 5: ascii
        "2026-08-31",   # 6: date
        ["a", "b"],     # 7: array
        { a => 1 },     # 8: hash
        "blob",         # 9: binary
    );

    my @dec = $adb->dec_validate( "products", \@dec_input );
    is( $dec[1], 200.5, "dec_validate casts num to number" );
    is( $dec[2], -50,   "dec_validate casts negative number to -50" );
    is( $dec[3], 0,     "dec_validate converts empty num to 0" );
    is_deeply( $dec[6], ["a", "b"], "dec_validate ensures array ref" );
    is_deeply( $dec[7], { a => 1 }, "dec_validate ensures hash ref" );

    # Direct single-block helper tests: enc_field & dec_field
    my $num_blk   = { id => "price", type => "num" };
    my $ascii_blk = { id => "code",  type => "ascii" };
    my $array_blk = { id => "tags",  type => "array" };

    is( $adb->enc_field( $num_blk, undef ), 0, "enc_field: undef num becomes 0" );
    is( $adb->enc_field( $num_blk, "" ), 0, "enc_field: empty string num becomes 0" );
    is( $adb->enc_field( $num_blk, " 350.25 " ), 350.25, "enc_field: valid float trimmed and cast" );
    is( $adb->enc_field( $ascii_blk, "Işık_Türkçe" ), "Isik_Turkce", "enc_field: ascii normalized" );
    is( $adb->dec_field( $num_blk, "" ), 0, "dec_field: empty num becomes 0" );
    is( $adb->dec_field( $num_blk, "45.90" ), 45.9, "dec_field: num cast to float" );
    is_deeply( $adb->dec_field( $array_blk, "x,y,z" ), ["x", "y", "z"], "dec_field: comma string to array ref" );
};

# ============================================================
# 3. CRUD Round-Trip with enc_validate & dec_validate
# ============================================================
subtest '3. Full CRUD Round-Trip via insert_id & read_id' => sub {
    my $db_dir = "$tmp_dir/db_types";
    my $adb = AmberDB->new( path => { dbase_dir => $db_dir } );

    # Insert record with various types (including negative numbers and empty auto_date)
    my $rid = $adb->insert_id(
        "products", 101,
        "Laptop Çantası",        # 1: title (text)
        "1250.50",               # 2: price (num)
        "-15.00",                # 3: discount (negative num)
        "",                      # 4: balance (empty num -> 0)
        "LAPTOP-BAG-TR",         # 5: code (ascii)
        "",                      # 6: created_at (auto_date)
        ["aksesuar", "çanta"],   # 7: tags (array ref)
        { brand => "AmberBrand", warranty => 24 }, # 8: meta (hash ref)
        "RAW_IMAGE_BYTES",       # 9: raw_blob (binary)
    );

    is( $rid, 101, "Record 101 inserted successfully" );

    # Read record back
    my @rec = $adb->read_id( "products", 101 );
    is( scalar(@rec), 10, "read_id returns exactly 10 fields (1 ID + 9 data fields)" );
    is( $rec[0], 101, "Field 0 is ID 101" );
    is( $rec[1], "Laptop Çantası", "Field 1 is text title" );
    is( $rec[2], 1250.5, "Field 2 is numeric price" );
    is( $rec[3], -15, "Field 3 is negative numeric discount" );
    is( $rec[4], 0, "Field 4 is 0 for empty num balance" );
    is( $rec[5], "LAPTOP-BAG-TR", "Field 5 is ascii code" );
    like( $rec[6], qr/^\d{4}-\d{2}-\d{2}$/, "Field 6 is auto populated date" );
    is_deeply( $rec[7], ["aksesuar", "çanta"], "Field 7 is array ref" );
    is_deeply( $rec[8], { brand => "AmberBrand", warranty => 24 }, "Field 8 is hash ref" );
    is( $rec[9], "RAW_IMAGE_BYTES", "Field 9 is binary string" );

    # Modify record
    $adb->modify_id(
        "products", 101,
        "Laptop Çantası V2",
        "1400",
        "-10",
        "500",
        "LAPTOP-BAG-V2",
        "2026-08-31",
        ["aksesuar", "çanta", "yeni"],
        { brand => "AmberBrand", warranty => 36 },
        "RAW_V2_BYTES",
    );

    my @mod_rec = $adb->read_id( "products", 101 );
    is( $mod_rec[1], "Laptop Çantası V2", "Modified title verified" );
    is( $mod_rec[2], 1400, "Modified price verified" );
    is( $mod_rec[3], -10,  "Modified negative discount verified" );
    is( $mod_rec[4], 500,  "Modified balance verified" );
    is_deeply( $mod_rec[7], ["aksesuar", "çanta", "yeni"], "Modified array ref verified" );
    is_deeply( $mod_rec[8]->{warranty}, 36, "Modified hash ref verified" );
};

# ============================================================
# 4. Bulk Operations (insert_list, modify_list, read_list, read_all)
# ============================================================
subtest '4. Bulk Operations & read_all Validation' => sub {
    my $db_dir = "$tmp_dir/db_types";
    my $adb = AmberDB->new( path => { dbase_dir => $db_dir } );

    my @batch = (
        [ 201, "Ürün A", "50.25", "-5", "10", "PROD-A", "", ["kat1"], { k => 1 }, "bin1" ],
        [ 202, "Ürün B", "75.00", "",   "0",  "PROD-B", "", ["kat2"], { k => 2 }, "bin2" ],
        [ 203, "Ürün C", "-100",  "0",  "-20", "PROD-C", "", [],       {},         "bin3" ],
    );

    my $statu = $adb->insert_list( "products", @batch );
    is( scalar( keys %$statu ), 3, "insert_list inserted 3 records" );

    # Test read_list
    my @list = $adb->read_list( "products", [ 201, 202, 203 ] );
    is( scalar(@list), 3, "read_list returned 3 records" );
    is( $list[0]->[2], 50.25, "read_list record 201 price is numeric float" );
    is( $list[0]->[3], -5,    "read_list record 201 discount is negative" );
    is( $list[1]->[3], 0,     "read_list record 202 empty discount is 0" );
    is( $list[2]->[2], -100,  "read_list record 203 negative price is -100" );

    # Test read_all
    my @all = $adb->read_all("products");
    # We have 101, 201, 202, 203 = 4 records
    is( scalar(@all), 4, "read_all returned 4 records" );
    my ($p201) = grep { $_->[0] == 201 } @all;
    ok( $p201, "Record 201 present in read_all" );
    is( $p201->[2], 50.25, "read_all record 201 has numeric type" );
    is_deeply( $p201->[7], ["kat1"], "read_all record 201 has array ref" );
};

# ============================================================
# 5. Simple Mode Bypass Verification (Zero Overhead)
# ============================================================
subtest '5. Simple Mode Bypasses enc_validate & dec_validate' => sub {
    my $db_dir = "$tmp_dir/db_types_simple";
    mkdir($db_dir);
    my $adb = AmberDB->new(
        path => { dbase_dir => $db_dir },
        cfg  => { simple => 1 },
    );

    # In simple mode, arbitrary data passes untouched without schema block casting
    my $raw_val = "   custom string not forced to number   ";
    my @enc = $adb->enc_validate( "free_table", [$raw_val] );
    is( $enc[0], $raw_val, "enc_validate in simple mode leaves data untouched" );

    my @dec = $adb->dec_validate( "free_table", [$raw_val] );
    is( $dec[0], $raw_val, "dec_validate in simple mode leaves data untouched" );

    # Insert and read arbitrary key and data
    $adb->insert_id( "free_table", "user\@test.com", "Active", "Data123" );
    my @read = $adb->read_id( "free_table", "user\@test.com" );
    is( $read[0], "user\@test.com", "Simple mode read_id returned exact key" );
    is( $read[1], "Active", "Simple mode read_id returned field 1" );
};

done_testing();
