#!/usr/bin/perl

# t/amberdb_match_unq.t
# Comprehensive tests for field_to_list, match_block numeric indexing (.fld),
# string dictionary & unique constraint (.unq) with auto-incrementing lastid,
# and RDBM foreign string-to-ID auto resolution.

use 5.016000;
use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

binmode Test::More->builder->output,         ':utf8';
binmode Test::More->builder->failure_output, ':utf8';
binmode Test::More->builder->todo_output,    ':utf8';
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

use_ok('AmberDB')        or BAIL_OUT('Cannot load AmberDB');
use_ok('AmberDB::Base::Index') or BAIL_OUT('Cannot load AmberDB::Base::Index');
use_ok('AmberDB::Tools') or BAIL_OUT('Cannot load AmberDB::Tools');

# ------------------------------------------------------------------
# SUBTEST 1: get_fieldlist / set_fieldlist unit tests (trim_space & normalization)
# ------------------------------------------------------------------
subtest 'get_fieldlist normalization and trim_space' => sub {
    plan tests => 10;

    my $adb = AmberDB->new();

    # 1. Undef / empty
    is_deeply( [ $adb->get_fieldlist(undef) ], [], 'undef returns empty list' );
    is_deeply( [ $adb->get_fieldlist('') ],    [], 'empty string returns empty list' );
    is_deeply( [ $adb->get_fieldlist('   ') ], [], 'whitespace-only returns empty list' );

    # 2. Single value with whitespace
    is_deeply( [ $adb->get_fieldlist('  Edebiyat  ') ], ['Edebiyat'], 'single string trimmed' );

    # 3. Comma / semicolon delimited with multiple spaces & tabs
    my $str1 = " Edebiyat ,  Dünya   Klasikleri ; \t Rus Romanları \n ";
    is_deeply(
        [ $adb->get_fieldlist($str1) ],
        [ 'Edebiyat', 'Dünya Klasikleri', 'Rus Romanları' ],
        'comma/semicolon delimited string trimmed and normalized'
    );

    # 4. Numeric comma list
    is_deeply(
        [ $adb->get_fieldlist(' 49 , 112 ; 167 ') ],
        [ '49', '112', '167' ],
        'numeric comma/semicolon list parsed'
    );

    # 5. Array reference with trailing/leading spaces
    my $arr1 = [ ' Edebiyat ', '  Dünya  Klasikleri  ', '', '   ' ];
    is_deeply(
        [ $adb->get_fieldlist($arr1) ],
        [ 'Edebiyat', 'Dünya Klasikleri' ],
        'array ref elements trimmed and empty items removed'
    );

    # 6. Nested array reference
    my $arr2 = [ '49', [ ' 112 ', ' 167 ' ] ];
    is_deeply(
        [ $adb->get_fieldlist($arr2) ],
        [ '49', '112', '167' ],
        'nested array ref flattened and trimmed'
    );

    # 7. trim_space default mode (preserves newlines/tabs)
    my $ts_default = $adb->trim_space("  hello \n world \t !  ");
    is( $ts_default, "hello\nworld\t!", 'trim_space default preserves newlines and tabs' );

    # 8. trim_space flatten mode (flattens all whitespace)
    my $ts_flatten = $adb->trim_space("  hello \n world \t !  ", 1);
    is( $ts_flatten, "hello world !", 'trim_space flatten mode converts all whitespace to single space' );
};

# ------------------------------------------------------------------
# SUBTEST 2: rdbm field (Case 1: numeric indexing)
# ------------------------------------------------------------------
subtest 'rdbm match_block numeric indexing (Case 1)' => sub {
    plan tests => 6;

    my $temp_dir   = tempdir( CLEANUP => 1 );
    my $conf_dir   = File::Spec->catdir( $temp_dir, 'config' );
    my $schema_dir = File::Spec->catdir( $temp_dir, 'schema' );
    mkdir $conf_dir;
    mkdir $schema_dir;

    my $schema_file = File::Spec->catfile( $schema_dir, 'products.table' );
    open my $fh, '>:encoding(UTF-8)', $schema_file or die "Cannot create schema: $!";
    print $fh <<'SCHEMA';
use utf8;
{
    record_index => 1,
    match_block  => [ 1 ],
    blocks       => [
        { id => "id",   name => "ID",       type => "auto_id", rdbm => "" },
        { id => "cat",  name => "Kategori", type => "text",    rdbm => "catalog_category;2" },
        { id => "name", name => "İsim",     type => "text",    rdbm => "" },
    ],
}
SCHEMA
    close $fh;

    my $adb = AmberDB->new(
        path => {
            dbase_dir  => $temp_dir,
            conf_dir   => $conf_dir,
            schema_dir => $schema_dir,
        }
    );

    # Insert products with category primary keys
    my $id1 = $adb->insert_id( 'products', 1, '49, 112', 'Kitap 1' );
    my $id2 = $adb->insert_id( 'products', 2, '112, 167', 'Kitap 2' );
    my $id3 = $adb->insert_id( 'products', 3, '49', 'Kitap 3' );

    my $fld_path = $adb->table_path('products') . '.fld';
    ok( -e $fld_path, 'products.fld index file exists' );

    # Verify .fld contains numeric keys 1:49, 1:112, 1:167
    my ( undef, @recs_49 )  = $adb->index_get( $fld_path, '1:49' );
    my ( undef, @recs_112 ) = $adb->index_get( $fld_path, '1:112' );
    my ( undef, @recs_167 ) = $adb->index_get( $fld_path, '1:167' );

    is_deeply( [ sort @recs_49 ],  [ 1, 3 ], 'key 49 contains products 1, 3' );
    is_deeply( [ sort @recs_112 ], [ 1, 2 ], 'key 112 contains products 1, 2' );
    is_deeply( [ sort @recs_167 ], [ 2 ],    'key 167 contains product 2' );

    # field_fetch queries
    my @fetch_49 = $adb->field_fetch( 'products', 1, 49 );
    is( scalar(@fetch_49), 2, 'field_fetch(1, 49) returns 2 records' );

    my @fetch_both = $adb->field_fetch( 'products', 1, '49, 167' );
    is( scalar(@fetch_both), 3, 'field_fetch(1, "49, 167") returns 3 records' );
};

# ------------------------------------------------------------------
# SUBTEST 3: non-rdbm string field (Case 2: .unq dictionary with lastid)
# ------------------------------------------------------------------
subtest 'non-rdbm string match_block with .unq and lastid (Case 2)' => sub {
    plan tests => 13;

    my $temp_dir   = tempdir( CLEANUP => 1 );
    my $conf_dir   = File::Spec->catdir( $temp_dir, 'config' );
    my $schema_dir = File::Spec->catdir( $temp_dir, 'schema' );
    mkdir $conf_dir;
    mkdir $schema_dir;

    my $schema_file = File::Spec->catfile( $schema_dir, 'tags.table' );
    open my $fh, '>:encoding(UTF-8)', $schema_file or die "Cannot create schema: $!";
    print $fh <<'SCHEMA';
use utf8;
{
    record_index => 1,
    match_block  => [ 1 ],
    blocks       => [
        { id => "id",    name => "ID",       type => "auto_id", rdbm => "" },
        { id => "tags",  name => "Etiketler",type => "text",    rdbm => "" },
        { id => "title", name => "Başlık",   type => "text",    rdbm => "" },
    ],
}
SCHEMA
    close $fh;

    my $adb = AmberDB->new(
        path => {
            dbase_dir  => $temp_dir,
            conf_dir   => $conf_dir,
            schema_dir => $schema_dir,
        }
    );

    # Insert records with text strings
    my $id1 = $adb->insert_id( 'tags', 1, 'Edebiyat, Dünya Klasikleri, Rus Romanları', 'Makale 1' );
    my $id2 = $adb->insert_id( 'tags', 2, 'Dünya Klasikleri, Bilim Kurgu', 'Makale 2' );

    my $unq_path = $adb->table_path('tags') . '.unq';
    my $fld_path = $adb->table_path('tags') . '.fld';

    ok( -e $unq_path, 'tags.unq dictionary file exists' );
    ok( -e $fld_path, 'tags.fld index file exists' );

    # Check lastid and string mappings in .unq using 1:s: prefix
    my ($lastid)  = $adb->index_get( $unq_path, '1:lastid', 'raw' );
    my ($id_edeb) = $adb->index_get( $unq_path, '1:s:Edebiyat', 'raw' );
    my ($id_dunya)= $adb->index_get( $unq_path, '1:s:Dünya Klasikleri', 'raw' );
    my ($id_rus)  = $adb->index_get( $unq_path, '1:s:Rus Romanları', 'raw' );
    my ($id_bilim)= $adb->index_get( $unq_path, '1:s:Bilim Kurgu', 'raw' );

    is( $lastid, 4, 'lastid in .unq equals 4' );
    is( $id_edeb, 1, 'Edebiyat assigned ID 1' );
    is( $id_dunya, 2, 'Dünya Klasikleri assigned ID 2' );
    is( $id_rus, 3, 'Rus Romanları assigned ID 3' );
    is( $id_bilim, 4, 'Bilim Kurgu assigned ID 4' );

    # Check .fld index keys (only numeric IDs 1, 2, 3, 4 with 1: prefix)
    my ( undef, @fld_1 ) = $adb->index_get( $fld_path, '1:1' );
    my ( undef, @fld_2 ) = $adb->index_get( $fld_path, '1:2' );
    is_deeply( \@fld_1, [1], 'key 1 (Edebiyat) has record 1' );
    is_deeply( [ sort @fld_2 ], [1, 2], 'key 2 (Dünya Klasikleri) has records 1, 2' );

    # field_fetch queries by string name
    my @fetch_edeb = $adb->field_fetch( 'tags', 1, 'Edebiyat' );
    is( scalar(@fetch_edeb), 1, 'field_fetch("tags", 1, "Edebiyat") finds record 1' );
    is( $fetch_edeb[0]->[0], 1, 'record 1 returned' );

    my @fetch_dunya = $adb->field_fetch( 'tags', 1, 'Dünya Klasikleri' );
    is( scalar(@fetch_dunya), 2, 'field_fetch("tags", 1, "Dünya Klasikleri") finds records 1, 2' );

    my @fetch_multi = $adb->field_fetch( 'tags', 1, 'Edebiyat, Bilim Kurgu' );
    is( scalar(@fetch_multi), 2, 'field_fetch("tags", 1, "Edebiyat, Bilim Kurgu") finds records 1, 2' );
};

# ------------------------------------------------------------------
# SUBTEST 4: modify_id, delete_id and set_fields (rebuild)
# ------------------------------------------------------------------
subtest 'modify_id, delete_id and index rebuild' => sub {
    plan tests => 8;

    my $temp_dir   = tempdir( CLEANUP => 1 );
    my $conf_dir   = File::Spec->catdir( $temp_dir, 'config' );
    my $schema_dir = File::Spec->catdir( $temp_dir, 'schema' );
    mkdir $conf_dir;
    mkdir $schema_dir;

    my $schema_file = File::Spec->catfile( $schema_dir, 'news.table' );
    open my $fh, '>:encoding(UTF-8)', $schema_file or die "Cannot create schema: $!";
    print $fh <<'SCHEMA';
use utf8;
{
    record_index => 1,
    match_block  => [ 1 ],
    blocks       => [
        { id => "id",    name => "ID",     type => "auto_id", rdbm => "" },
        { id => "topics",name => "Konular",type => "text",    rdbm => "" },
        { id => "title", name => "Başlık", type => "text",    rdbm => "" },
    ],
}
SCHEMA
    close $fh;

    my $adb = AmberDB->new(
        path => {
            dbase_dir  => $temp_dir,
            conf_dir   => $conf_dir,
            schema_dir => $schema_dir,
        }
    );

    $adb->insert_id( 'news', 1, 'Teknoloji, Yapay Zeka', 'Haber 1' );
    $adb->insert_id( 'news', 2, 'Yapay Zeka, Robotik',   'Haber 2' );

    my $unq_path = $adb->table_path('news') . '.unq';
    my ($lastid) = $adb->index_get( $unq_path, '1:lastid', 'raw' );
    is( $lastid, 3, 'initial lastid is 3' );

    # Modify news 1: replace 'Teknoloji' with new topic 'Uzay'
    $adb->modify_id( 'news', 1, 'Uzay, Yapay Zeka', 'Haber 1' );

    my ($new_lastid) = $adb->index_get( $unq_path, '1:lastid', 'raw' );
    my ($id_uzay)    = $adb->index_get( $unq_path, '1:s:Uzay', 'raw' );
    is( $new_lastid, 4, 'lastid incremented to 4 after adding Uzay' );
    is( $id_uzay, 4, 'Uzay assigned ID 4' );

    # Querying old topic 'Teknoloji' returns nothing for news 1
    my @fetch_tekno = $adb->field_fetch( 'news', 1, 'Teknoloji' );
    is( scalar(@fetch_tekno), 0, 'Teknoloji no longer matches news 1' );

    # Querying 'Uzay' returns news 1
    my @fetch_uzay = $adb->field_fetch( 'news', 1, 'Uzay' );
    is( scalar(@fetch_uzay), 1, 'Uzay matches news 1' );

    # Delete news 2
    $adb->delete_id( 'news', 2 );
    my @fetch_robo = $adb->field_fetch( 'news', 1, 'Robotik' );
    is( scalar(@fetch_robo), 0, 'Robotik no longer matches deleted news 2' );

    # Test Tools.pm set_fields (rebuild)
    my $tools = AmberDB::Tools->new($adb);
    my @all_records = $adb->read_all( 'news', 0, 0, no_index => 1 );
    $tools->set_fields( 'news', @all_records );

    my @fetch_uzay_rebuilt = $adb->field_fetch( 'news', 1, 'Uzay' );
    is( scalar(@fetch_uzay_rebuilt), 1, 'rebuilt index matches Uzay' );
    is( $fetch_uzay_rebuilt[0]->[0], 1, 'rebuilt record matches news 1' );
};

# ------------------------------------------------------------------
# SUBTEST 5: batch match_add lifecycle and embedded whitespace cleaning
# ------------------------------------------------------------------
subtest 'batch match_add handle lifecycle and whitespace cleaning' => sub {
    plan tests => 6;

    my $temp_dir   = tempdir( CLEANUP => 1 );
    my $conf_dir   = File::Spec->catdir( $temp_dir, 'config' );
    my $schema_dir = File::Spec->catdir( $temp_dir, 'schema' );
    mkdir $conf_dir;
    mkdir $schema_dir;

    my $schema_file = File::Spec->catfile( $schema_dir, 'batch_test.table' );
    open my $fh, '>:encoding(UTF-8)', $schema_file or die "Cannot create schema file: $!";
    print $fh <<'SCHEMA';
use utf8;
{
    record_index => 1,
    match_block  => [ 1 ],
    blocks       => [
        { id => "id",    name => "ID",     type => "auto_id", rdbm => "" },
        { id => "topics",name => "Konular",type => "text",    rdbm => "" },
        { id => "title", name => "Başlık", type => "text",    rdbm => "" },
    ],
}
SCHEMA
    close $fh;

    my $adb = AmberDB->new(
        path => {
            dbase_dir  => $temp_dir,
            conf_dir   => $conf_dir,
            schema_dir => $schema_dir,
        }
    );

    # Test newline/tab normalization in get_fieldlist
    my @f_list = $adb->get_fieldlist("  Bilim\nKurgu  ,  Yapay\tZeka  ");
    is_deeply( \@f_list, [ 'Bilim Kurgu', 'Yapay Zeka' ], 'embedded newlines and tabs normalized to single spaces' );

    # Batch records insertion
    my @batch = (
        [ 1, " Fizik , Kimya \n Biyoloji ", 'Ders 1' ],
        [ 2, 'Kimya, Matematik',            'Ders 2' ],
        [ 3, 'Geometri, Fizik',             'Ders 3' ],
    );

    my $table_path = File::Spec->catfile( $temp_dir, 'batch_test' );
    my $table_info = $adb->table_info('batch_test');

    # Run match_add for the whole batch
    $adb->match_add( $table_path, $table_info, \@batch );

    my $unq_path = File::Spec->catfile( $temp_dir, 'batch_test.unq' );
    my $fld_path = File::Spec->catfile( $temp_dir, 'batch_test.fld' );

    ok( -e $unq_path, 'batch_test.unq exists' );
    ok( -e $fld_path, 'batch_test.fld exists' );

    my ($lastid)   = $adb->index_get( $unq_path, '1:lastid', 'raw' );
    my ($id_fizik) = $adb->index_get( $unq_path, '1:s:Fizik', 'raw' );
    my ($id_kimya) = $adb->index_get( $unq_path, '1:s:Kimya', 'raw' );

    is( $lastid, 5, 'lastid is 5 after batch match_add' );

    # Verify .fld index for Fizik (ID 1) contains records 1 and 3 with 1: prefix
    my ( undef, @recs_fizik ) = $adb->index_get( $fld_path, "1:$id_fizik" );
    is_deeply( [ sort @recs_fizik ], [ 1, 3 ], 'Fizik index correctly maps to records 1 and 3 across batch' );

    # Verify get_fieldlist read mode does not open-close erroneously
    my @read_ids = $adb->get_fieldlist( 'Fizik, Geometri', 'read', $table_path, $table_info, 1 );
    is_deeply( \@read_ids, [ $id_fizik, 5 ], 'read mode resolves batch strings to numeric IDs' );
};

# ------------------------------------------------------------------
# SUBTEST 6: valid => "unique" O(1) duplicate constraint enforcement
# ------------------------------------------------------------------
subtest 'valid => "unique" constraint check in insert/modify/delete' => sub {
    plan tests => 8;

    my $temp_dir   = tempdir( CLEANUP => 1 );
    my $conf_dir   = File::Spec->catdir( $temp_dir, 'config' );
    my $schema_dir = File::Spec->catdir( $temp_dir, 'schema' );
    mkdir $conf_dir;
    mkdir $schema_dir;

    my $schema_file = File::Spec->catfile( $schema_dir, 'users.table' );
    open my $fh, '>:encoding(UTF-8)', $schema_file or die "Cannot create schema: $!";
    print $fh <<'SCHEMA';
use utf8;
{
    record_index => 1,
    blocks       => [
        { id => "id",       name => "ID",       type => "auto_id" },
        { id => "username", name => "Kullanıcı", type => "text",   valid => "not_null;unique" },
        { id => "email",    name => "E-posta",   type => "text",   valid => "unique" },
        { id => "fullname", name => "Ad Soyad",  type => "text" },
    ],
}
SCHEMA
    close $fh;

    my $adb = AmberDB->new(
        path => {
            dbase_dir  => $temp_dir,
            conf_dir   => $conf_dir,
            schema_dir => $schema_dir,
        }
    );

    # 1. First insert should succeed
    my $id1 = $adb->insert_id( 'users', 101, 'john_doe', 'john@example.com', 'John Doe' );
    is( $id1, 101, 'First user inserted successfully' );

    # Verify .unq file has 1:s:john_doe => 101 and 1:n:101 => john_doe
    my $unq_user = $adb->table_path('users') . '.unq';
    my ($u101) = $adb->index_get( $unq_user, '1:s:john_doe', 'raw' );
    is( $u101, 101, 'users.unq recorded 1:s:john_doe => 101' );

    # 2. Duplicate username insert should fail
    my $id2 = $adb->insert_id( 'users', 102, 'john_doe', 'other@example.com', 'Another User' );
    ok( !defined $id2, 'Duplicate username insert failed' );

    # 3. Duplicate email insert should fail
    my $id3 = $adb->insert_id( 'users', 103, 'jane_doe', 'john@example.com', 'Jane Doe' );
    ok( !defined $id3, 'Duplicate email insert failed' );

    # 4. Non-conflicting insert should succeed
    my $id4 = $adb->insert_id( 'users', 104, 'jane_doe', 'jane@example.com', 'Jane Doe' );
    is( $id4, 104, 'Second unique user inserted successfully' );

    # 5. Modifying user 104 with duplicate username 'john_doe' should fail
    my $mod_fail = $adb->modify_id( 'users', 104, 'john_doe', 'jane@example.com', 'Jane Doe Modified' );
    ok( !defined $mod_fail, 'modify_id with duplicate username rejected' );

    # 6. Modifying user 101 keeping same username should succeed
    my $mod_ok = $adb->modify_id( 'users', 101, 'john_doe', 'john_new@example.com', 'John Doe Jr.' );
    ok( $mod_ok, 'modify_id on same record succeeds' );

    # 7. Delete user 101, now 'john_doe' should become available again
    $adb->delete_id( 'users', 101 );
    my $id5 = $adb->insert_id( 'users', 105, 'john_doe', 'john5@example.com', 'John Five' );
    is( $id5, 105, 'Re-inserting username after deletion succeeds' );
};

# ------------------------------------------------------------------
# SUBTEST 7: RDBM Foreign String auto-resolution via foreign .unq
# ------------------------------------------------------------------
subtest 'RDBM Foreign String auto-resolution via foreign .unq' => sub {
    plan tests => 8;

    my $temp_dir   = tempdir( CLEANUP => 1 );
    my $conf_dir   = File::Spec->catdir( $temp_dir, 'config' );
    my $schema_dir = File::Spec->catdir( $temp_dir, 'schema' );
    mkdir $conf_dir;
    mkdir $schema_dir;

    # Target table: catalog_brand
    my $brand_schema = File::Spec->catfile( $schema_dir, 'catalog_brand.table' );
    open my $bfh, '>:encoding(UTF-8)', $brand_schema or die "Cannot create schema: $!";
    print $bfh <<'SCHEMA';
use utf8;
{
    record_index => 1,
    match_block  => [ 1 ],
    blocks       => [
        { id => "id",   name => "ID",           type => "auto_id" },
        { id => "name", name => "Yayınevi Adı", type => "text",   valid => "unique" },
    ],
}
SCHEMA
    close $bfh;

    # Host table: catalog_book with rdbm => "catalog_brand;1"
    my $book_schema = File::Spec->catfile( $schema_dir, 'catalog_book.table' );
    open my $kfh, '>:encoding(UTF-8)', $book_schema or die "Cannot create schema: $!";
    print $kfh <<'SCHEMA';
use utf8;
{
    record_index => 1,
    match_block  => [ 1 ],
    blocks       => [
        { id => "id",        name => "ID",       type => "auto_id" },
        { id => "publisher", name => "Yayınevi", type => "text",    rdbm => "catalog_brand;1" },
        { id => "title",     name => "Kitap",    type => "text" },
    ],
}
SCHEMA
    close $kfh;

    my $adb = AmberDB->new(
        path => {
            dbase_dir  => $temp_dir,
            conf_dir   => $conf_dir,
            schema_dir => $schema_dir,
        }
    );

    # Pre-register a brand in catalog_brand
    my $b10 = $adb->insert_id( 'catalog_brand', 10, 'Can Yayınları' );
    is( $b10, 10, 'Brand 10 Can Yayınları created' );

    # Insert book 1001 passing text 'Can Yayınları'
    my $k1 = $adb->insert_id( 'catalog_book', 1001, 'Can Yayınları', 'Karamazov Kardeşler' );
    is( $k1, 1001, 'Book 1001 inserted with string publisher' );

    # Verify .fld index of catalog_book has resolved 'Can Yayınları' to ID 10
    my $book_fld = $adb->table_path('catalog_book') . '.fld';
    my ( undef, @books_10 ) = $adb->index_get( $book_fld, '1:10' );
    is_deeply( \@books_10, [1001], 'Book 1001 correctly indexed under numeric Brand ID 10' );

    # Insert book 1002 passing brand ID 10 directly
    my $k2 = $adb->insert_id( 'catalog_book', 1002, 10, 'Suç ve Ceza' );
    is( $k2, 1002, 'Book 1002 inserted with numeric publisher ID' );

    my ( undef, @books_10_all ) = $adb->index_get( $book_fld, '1:10' );
    is_deeply( [ sort @books_10_all ], [ 1001, 1002 ], 'Both books match Brand ID 10' );

    # Insert book 1003 passing new brand 'İthaki Yayınları' (does NOT create foreign record, only unq)
    my $k3 = $adb->insert_id( 'catalog_book', 1003, 'İthaki Yayınları', 'Dune' );
    is( $k3, 1003, 'Book 1003 inserted' );

    # Verify target table catalog_brand has NOT created a foreign record (remains 1 record)
    my @all_brands = $adb->read_all('catalog_brand');
    is( scalar @all_brands, 1, 'catalog_brand has NOT created foreign record; exactly 1 record remains in .inx index' );

    # Verify catalog_book.unq has registered 'İthaki Yayınları' ("sadece unq üretsin")
    my $book_unq = $adb->table_path('catalog_book') . '.unq';
    my ($ithaki_unq_id) = $adb->index_get( $book_unq, '1:s:İthaki Yayınları', 'raw' );
    ok( defined $ithaki_unq_id && $ithaki_unq_id ne '', 'catalog_book.unq generated unq ID for string publisher' );
};

done_testing();
