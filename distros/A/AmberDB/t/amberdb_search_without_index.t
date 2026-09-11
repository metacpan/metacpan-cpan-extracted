#!/usr/bin/perl

# t/amberdb_search_without_index.t - Tests for AmberDB Search without Index (Direct Table Scan)

use 5.016000;
use strict;
use warnings;
use utf8;
use open ':std', ':utf8';
use Test::More;
binmode Test::More->builder->output,         ':utf8';
binmode Test::More->builder->failure_output, ':utf8';
binmode Test::More->builder->todo_output,    ':utf8';
use File::Temp qw(tempdir);
use File::Spec;
use Encode qw(encode);

use_ok('AmberDB') or BAIL_OUT('Cannot load AmberDB');

my $tmpdir = tempdir( CLEANUP => 1 );

# Initialize AmberDB instance with Turkish locale
my $adb = AmberDB->new(
    path => { dbase_dir => $tmpdir },
    cfg  => { language  => 'tr' },
);

# ==============================================================================
# SUBTEST 1: Unindexed Schema & No Index Files Verification
# ==============================================================================
subtest '1. Unindexed Schema & Verification of No Index Files on Disk' => sub {
    plan tests => 6;

    my $tbl = 'catalog_unindexed';
    my $table_info = {
        record_index => 0,
        # No search_block defined (unindexed mode)
    };
    $adb->table_attr( $tbl, $table_info );

    # Insert initial product catalog records:
    # [ ID, SKU (blk 1), Title (blk 2), Desc (blk 3), Category (blk 4), Price (blk 5), Brand (blk 6) ]
    my @initial_records = (
        [ 1, 'SKU-001', 'Sony Kablosuz Kulaklık',     'Bluetooth stereo kulaklık yüksek ses', '10', '150', '12' ],
        [ 2, 'SKU-002', 'Philips Bluetooth Kulaklık', 'Kablosuz mikrofonlu kulaklık',          '10', '120', '12' ],
        [ 3, 'SKU-003', 'JBL Bluetooth Hoparlör',     'Taşınabilir yüksek ses hoparlör',       '20', '200', '12' ],
        [ 4, 'SKU-004', 'Sony Bluetooth Hoparlör',    'Kablosuz stereo hoparlör',              '20', '180', '14' ],
        [ 5, 'SKU-005', 'Apple Kablosuz Kulaklık',    'Bluetooth gürültü önleyici kulaklık',   '10', '300', '14' ],
        [ 6, 'SKU-006', 'Sennheiser Kulaklık Pro',    'Kablolu profesyonel stereo kulaklık',   '10', '400', '12' ],
    );

    for my $r (@initial_records) {
        $adb->insert_id( $tbl, $r->[0], @$r[ 1 .. $#$r ] );
    }

    my $table_path = $adb->table_path($tbl);
    my $db_file    = "$table_path.db";
    my $src_path   = "${table_path}.src";

    # Confirm raw .db file exists, but NO search index (.src) files exist
    ok( -e $db_file, "Data file ${tbl}.db created on disk" );
    ok( !-e $src_path, "No .src index file created" );

    # Basic unindexed search verification via table scan
    my @res_kulaklik = $adb->search_table( $tbl, 'kulaklık' );
    is( scalar @res_kulaklik, 4, "Unindexed search_table finds 4 records for 'kulaklık'" );

    my @res_hoparlor = $adb->search_table( $tbl, 'hoparlör' );
    is( scalar @res_hoparlor, 2, "Unindexed search_table finds 2 records for 'hoparlör'" );

    my @res_sony = $adb->search_table( $tbl, 'sony' );
    is( scalar @res_sony, 2, "Unindexed search_table finds 2 records for 'sony'" );

    my @res_bluetooth = $adb->search_table( $tbl, 'bluetooth' );
    is( scalar @res_bluetooth, 5, "Unindexed search_table finds 5 records for 'bluetooth' (across title & desc)" );
};

# ==============================================================================
# SUBTEST 2: insert_id, modify_id, delete_id Yaşam Döngüsü (Unindexed)
# ==============================================================================
subtest '2. insert_id, modify_id, delete_id Lifecycle & Unindexed Search' => sub {
    plan tests => 11;

    my $tbl = 'catalog_unindexed';

    # --- A) INSERT NEW RECORD ---
    my $inserted_id = $adb->insert_id(
        $tbl, 101,
        'SKU-101',
        'Mekanik Oyuncu Klavyesi',
        'RGB aydınlatmalı mekanik klavye sessiz tuş',
        '30', '500', '15'
    );
    is( $inserted_id, 101, "insert_id succeeded with ID 101" );

    # Search for newly inserted terms in unindexed table
    my @res_klavye = $adb->search_table( $tbl, 'klavye' );
    is( scalar @res_klavye, 1, "Unindexed search finds 1 record for newly inserted 'klavye'" );
    is( $res_klavye[0]->[0], 101, "Matched record ID is 101" );

    my @res_mekanik = $adb->search_table( $tbl, 'mekanik' );
    is( scalar @res_mekanik, 1, "Unindexed search finds 1 record for 'mekanik'" );

    # --- B) MODIFY RECORD ---
    my $modify_ok = $adb->modify_id(
        $tbl, 101,
        'SKU-101',
        'Kablosuz Optik Fare',
        'Yüksek hassasiyetli optik oyuncu faresi ergonomik',
        '30', '350', '15'
    );
    ok( $modify_ok, "modify_id succeeded for ID 101" );

    # Search for old words: MUST NO LONGER MATCH
    my @old_klavye = $adb->search_table( $tbl, 'klavye' );
    is( scalar @old_klavye, 0, "Old word 'klavye' returns 0 records after modify" );

    my @old_mekanik = $adb->search_table( $tbl, 'mekanik' );
    is( scalar @old_mekanik, 0, "Old word 'mekanik' returns 0 records after modify" );

    # Search for new words: MUST MATCH ID 101
    my @new_fare = $adb->search_table( $tbl, 'fare' );
    is( scalar @new_fare, 1, "New word 'fare' returns 1 record after modify" );
    is( $new_fare[0]->[0], 101, "Matched ID for 'fare' is 101" );

    # --- C) DELETE RECORD ---
    $adb->delete_id( $tbl, 101 );

    # Search for words of deleted record: MUST RETURN 0
    my @del_fare = $adb->search_table( $tbl, 'fare' );
    is( scalar @del_fare, 0, "Deleted record word 'fare' returns 0 records" );

    my @del_optik = $adb->search_table( $tbl, 'optik' );
    is( scalar @del_optik, 0, "Deleted record word 'optik' returns 0 records" );
};

# ==============================================================================
# SUBTEST 3: search_table ve filter blokunun uygulanması (Unindexed)
# ==============================================================================
subtest '3. search_table with Filter Block & Constraints (Unindexed)' => sub {
    plan tests => 8;

    my $tbl = 'catalog_unindexed';

    # 1. Searching "kulaklık" (IDs 1, 2, 5, 6) filtered by brand (field 6 = 12: IDs 1, 2, 6)
    my ( $total_f6, @res_f6 ) = $adb->search_table(
        $tbl, 'kulaklık',
        start  => 0,
        limit  => 20,
        filter => { field => 6, value => 12 }
    );
    is( $total_f6, 3, "Unindexed filtered search 'kulaklık' with field 6 = 12 count is 3" );
    is_deeply( [ sort { $a <=> $b } map { $_->[0] } @res_f6 ], [ 1, 2, 6 ],
        "Unindexed filtered search returns expected record IDs [1, 2, 6]" );

    # 2. Alternative syntax: hash { 6 => 12 }
    my ( $t_h, @res_h ) = $adb->search_table(
        $tbl, 'kulaklık',
        start  => 0,
        limit  => 10,
        filter => { 6 => 12 }
    );
    is( $t_h, 3, "Filter hash syntax { 6 => 12 } returns 3 records" );

    # 3. Alternative syntax: array [ 6, 12 ]
    my ( $t_a, @res_a ) = $adb->search_table(
        $tbl, 'kulaklık',
        start  => 0,
        limit  => 10,
        filter => [ 6, 12 ]
    );
    is( $t_a, 3, "Filter array syntax [ 6, 12 ] returns 3 records" );

    # 4. Multi-value filter: field 6 = [12, 14] -> returns all 4 kulaklık (IDs 1, 2, 5, 6)
    my ( $t_multi, @res_multi ) = $adb->search_table(
        $tbl, 'kulaklık',
        start  => 0,
        limit  => 10,
        filter => { field => 6, value => [ 12, 14 ] }
    );
    is( $t_multi, 4, "Multi-value filter [12, 14] matches all 4 records" );

    # 5. Filter with non-matching value (field 6 = 99)
    my ( $t_zero, @res_zero ) = $adb->search_table(
        $tbl, 'hoparlör',
        start  => 0,
        limit  => 10,
        filter => { field => 6, value => 99 }
    );
    is( $t_zero, 0, "Filter with non-matching value returns 0 count" );
    is( scalar @res_zero, 0, "Filter with non-matching value returns empty list" );

    # 6. Combined Search + Filter + Sort (by price desc: block 5)
    # IDs 1, 2, 6 prices: 6=>400, 1=>150, 2=>120
    my ( $t_sort, @res_sort ) = $adb->search_table(
        $tbl, 'kulaklık',
        start  => 0,
        limit  => 10,
        sort   => 5,
        filter => { field => 6, value => 12 }
    );
    is_deeply( [ map { $_->[0] } @res_sort ], [ 6, 1, 2 ],
        "Search + Filter + Sort by price desc returns [6, 1, 2]" );
};

# ==============================================================================
# SUBTEST 4: Normalizasyon kontrolü (Türkiye'nin / Kesme İşareti / Stop Word)
# ==============================================================================
subtest '4. Normalization & Apostrophe / Stop Word Handling (Unindexed)' => sub {
    plan tests => 15;

    my $tbl = 'articles_unindexed';
    $adb->table_attr( $tbl, {
        record_index => 0,
    } );

    # Insert records with apostrophes:
    # Record 201 contains "Türkiye'nin"
    $adb->insert_id( $tbl, 201, "Türkiye'nin Gezilecek Şehirleri", "Türkiye'nin başkenti Ankara ve tarihi mekanları" );
    # Record 202 contains "İstanbul'da"
    $adb->insert_id( $tbl, 202, "İstanbul'da Kültür ve Sanat", "İstanbul'da tarihi yarımada gezisi" );
    # Record 203 contains "Ahmet'in"
    $adb->insert_id( $tbl, 203, "Ahmet'in Başarı Hikayesi", "Ahmet'in okul ve iş hayatındaki başarıları" );

    # Kayıtta "Türkiye'nin" geçiyorsa:
    # 1. "Türkiye" araması doğru sonucu getirir
    my @s_tr = $adb->search_table( $tbl, 'Türkiye' );
    is( scalar @s_tr, 1, "Search for 'Türkiye' matches record with 'Türkiye\\'nin' in unindexed table" );
    is( $s_tr[0]->[0], 201, "Matched ID is 201" );

    # 2. "Türkiye'nin" araması doğru sonucu getirir
    my @s_tr_apos = $adb->search_table( $tbl, "Türkiye'nin" );
    is( scalar @s_tr_apos, 1, "Search for 'Türkiye\\'nin' matches record in unindexed table" );
    is( $s_tr_apos[0]->[0], 201, "Matched ID is 201" );

    # 3. "Türkiyenin" araması doğru sonucu getirir
    my @s_tr_comb = $adb->search_table( $tbl, 'Türkiyenin' );
    is( scalar @s_tr_comb, 1, "Search for 'Türkiyenin' matches record in unindexed table" );
    is( $s_tr_comb[0]->[0], 201, "Matched ID is 201" );

    # 4. "nin" sonuç getirmez (Apostroftan sonraki hece stop word olarak atlanır)
    my @s_nin = $adb->search_table( $tbl, 'nin' );
    is( scalar @s_nin, 0, "Search for apostrophe suffix 'nin' returns NO results (0 matches)" );

    # Additional apostrophe cases:
    # "İstanbul'da" -> matches "İstanbul", "İstanbul'da", "Istanbulda"; "da" returns 0
    my @s_ist = $adb->search_table( $tbl, 'İstanbul' );
    is( scalar @s_ist, 1, "Search for 'İstanbul' matches record 202" );

    my @s_ist_apos = $adb->search_table( $tbl, "İstanbul'da" );
    is( scalar @s_ist_apos, 1, "Search for 'İstanbul\\'da' matches record 202" );

    my @s_ist_comb = $adb->search_table( $tbl, 'Istanbulda' );
    is( scalar @s_ist_comb, 1, "Search for 'Istanbulda' matches record 202" );

    my @s_da = $adb->search_table( $tbl, 'da' );
    is( scalar @s_da, 0, "Search for apostrophe suffix 'da' returns NO results (0 matches)" );

    # "Ahmet'in" -> matches "Ahmet", "Ahmet'in", "Ahmetin"; "in" returns 0
    my @s_ahmet = $adb->search_table( $tbl, 'Ahmet' );
    is( scalar @s_ahmet, 1, "Search for 'Ahmet' matches record 203" );

    my @s_ahmet_apos = $adb->search_table( $tbl, "Ahmet'in" );
    is( scalar @s_ahmet_apos, 1, "Search for 'Ahmet\\'in' matches record 203" );

    my @s_ahmet_comb = $adb->search_table( $tbl, 'Ahmetin' );
    is( scalar @s_ahmet_comb, 1, "Search for 'Ahmetin' matches record 203" );

    my @s_in = $adb->search_table( $tbl, 'in' );
    is( scalar @s_in, 0, "Search for apostrophe suffix 'in' returns NO results (0 matches)" );
};

# ==============================================================================
# SUBTEST 5: Türkçe Karakterler, Şapkalı Harfler ve Son Harf Dönüşümleri
# ==============================================================================
subtest '5. Turkish Characters, Circumflex Vowels & Phonetic Devoicing (Unindexed)' => sub {
    plan tests => 22;

    my $tbl = 'turkish_unindexed';
    $adb->table_attr( $tbl, {
        record_index => 0,
    } );

    # Insert Turkish test records:
    # 301: ığdır (Iğdır / IĞDIR / igdir)
    $adb->insert_id( $tbl, 301, 'Iğdır Ovası Tarımı', 'IĞDIR ilinde yetişen lezzetli kayısılar' );
    # 302: Çarşı (çarşı / ÇARŞI / carsi)
    $adb->insert_id( $tbl, 302, 'Tarihi Çarşı Esnafı', 'KAPALI ÇARŞI dükkanları ve esnafları' );
    # 303: ÇÖPÇÜ (çöpçü / ÇÖPÇÜ / copcu)
    $adb->insert_id( $tbl, 303, 'ÇÖPÇÜ Kadrosu Hizmeti', 'Gece çalışan fedakar çöpçü emekçileri' );
    # 304: kârın (şapkalı â: kârın / karın / karin / KÂRIN)
    $adb->insert_id( $tbl, 304, 'Şirketin kârın dağıtımı', 'Yıllık net kârın ortaklara paylaştırılması' );
    # 305: ÂLÎM (şapkalı Â ve Î: ÂLÎM / âlim / alim / ALİM)
    $adb->insert_id( $tbl, 305, 'Büyük ÂLÎM Eserleri', 'İslam âlimlerinin ve ÂLÎM zatların kıymetli kitapları' );
    # 306: tevhid (son harf d -> t: tevhid / tevhit / TEVHİD / TEVHİT)
    $adb->insert_id( $tbl, 306, 'İslamda Tevhid İnancı', 'Tevhid akidesi ve tevhid esasları' );
    # 307: gazab (son harf b -> p: gazab / gazap / GAZAB / GAZAP)
    $adb->insert_id( $tbl, 307, 'İlahi Gazab ve Rahmet', 'Gazab yerine merhamet ve af dilemek' );
    # 308: ahbab (son harf b -> p: ahbab / ahbap)
    $adb->insert_id( $tbl, 308, 'Eski Ahbab Ziyareti', 'Sadık ahbab ve vefalı dostlar' );
    # 309: mehmed (son harf d -> t: mehmed / mehmet)
    $adb->insert_id( $tbl, 309, 'Mehmed Akif Ersoy Hayatı', 'Milli şairimiz Mehmed Akif ve şiirleri' );

    # A) Türkçe Karakter Eşleşmeleri: ığdır
    my @s_igdir1 = $adb->search_table( $tbl, 'ığdır' );
    is( scalar @s_igdir1, 1, "Unindexed search 'ığdır' matches record 301" );

    my @s_igdir2 = $adb->search_table( $tbl, 'IĞDIR' );
    is( scalar @s_igdir2, 1, "Unindexed search 'IĞDIR' matches record 301" );

    my @s_igdir3 = $adb->search_table( $tbl, 'igdir' );
    is( scalar @s_igdir3, 1, "Unindexed search 'igdir' (ASCII) matches record 301" );

    # B) Türkçe Karakter Eşleşmeleri: Çarşı
    my @s_carsi1 = $adb->search_table( $tbl, 'çarşı' );
    is( scalar @s_carsi1, 1, "Unindexed search 'çarşı' matches record 302" );

    my @s_carsi2 = $adb->search_table( $tbl, 'ÇARŞI' );
    is( scalar @s_carsi2, 1, "Unindexed search 'ÇARŞI' matches record 302" );

    my @s_carsi3 = $adb->search_table( $tbl, 'carsi' );
    is( scalar @s_carsi3, 1, "Unindexed search 'carsi' (ASCII) matches record 302" );

    # C) Türkçe Karakter Eşleşmeleri: ÇÖPÇÜ
    my @s_copcu1 = $adb->search_table( $tbl, 'çöpçü' );
    is( scalar @s_copcu1, 1, "Unindexed search 'çöpçü' matches record 303" );

    my @s_copcu2 = $adb->search_table( $tbl, 'ÇÖPÇÜ' );
    is( scalar @s_copcu2, 1, "Unindexed search 'ÇÖPÇÜ' matches record 303" );

    my @s_copcu3 = $adb->search_table( $tbl, 'copcu' );
    is( scalar @s_copcu3, 1, "Unindexed search 'copcu' (ASCII) matches record 303" );

    # D) Şapkalı Harfler (Circumflex): kârın
    my @s_karin1 = $adb->search_table( $tbl, 'kârın' );
    is( scalar @s_karin1, 1, "Unindexed search 'kârın' (circumflex â) matches record 304" );

    my @s_karin2 = $adb->search_table( $tbl, 'karın' );
    is( scalar @s_karin2, 1, "Unindexed search 'karın' matches record 304" );

    my @s_karin3 = $adb->search_table( $tbl, 'karin' );
    is( scalar @s_karin3, 1, "Unindexed search 'karin' (ASCII) matches record 304" );

    # E) Şapkalı Harfler (Circumflex): ÂLÎM
    my @s_alim1 = $adb->search_table( $tbl, 'ÂLÎM' );
    is( scalar @s_alim1, 1, "Unindexed search 'ÂLÎM' matches record 305" );

    my @s_alim2 = $adb->search_table( $tbl, 'âlim' );
    is( scalar @s_alim2, 1, "Unindexed search 'âlim' matches record 305" );

    my @s_alim3 = $adb->search_table( $tbl, 'alim' );
    is( scalar @s_alim3, 1, "Unindexed search 'alim' matches record 305" );

    # F) Son Harf Dönüşümü (Final Devoicing d -> t): tevhid / tevhit
    my @s_tevhid = $adb->search_table( $tbl, 'tevhid' );
    is( scalar @s_tevhid, 1, "Unindexed search 'tevhid' matches record 306" );

    my @s_tevhit = $adb->search_table( $tbl, 'tevhit' );
    is( scalar @s_tevhit, 1, "Unindexed search 'tevhit' matches record 306" );

    # G) Son Harf Dönüşümü (Final Devoicing b -> p): gazab / gazap
    my @s_gazab = $adb->search_table( $tbl, 'gazab' );
    is( scalar @s_gazab, 1, "Unindexed search 'gazab' matches record 307" );

    my @s_gazap = $adb->search_table( $tbl, 'gazap' );
    is( scalar @s_gazap, 1, "Unindexed search 'gazap' matches record 307" );

    # H) Son Harf Dönüşümü: ahbab / ahbap
    my @s_ahbab = $adb->search_table( $tbl, 'ahbab' );
    is( scalar @s_ahbab, 1, "Unindexed search 'ahbab' matches record 308" );

    my @s_ahbap = $adb->search_table( $tbl, 'ahbap' );
    is( scalar @s_ahbap, 1, "Unindexed search 'ahbap' matches record 308" );

    # I) Son Harf Dönüşümü: mehmed / mehmet
    my @s_mehmed = $adb->search_table( $tbl, 'mehmed' );
    is( scalar @s_mehmed, 1, "Unindexed search 'mehmed' matches record 309" );
};

# ==============================================================================
# SUBTEST 6: AND / OR Mantıksal Arama ve keys_only Seçeneği (Unindexed)
# ==============================================================================
subtest '6. Logical AND / OR Search & keys_only Option (Unindexed)' => sub {
    plan tests => 5;

    my $tbl = 'catalog_unindexed';

    # 1. AND search (default): "sony kulaklık" matches only ID 1
    my @s_and = $adb->search_table( $tbl, 'sony kulaklık', 'and' );
    is( scalar @s_and, 1, "AND search 'sony kulaklık' matches 1 record (ID 1)" );
    is( $s_and[0]->[0], 1, "Matched ID is 1" );

    # 2. OR search: "apple jbl" matches ID 3 (JBL) and ID 5 (Apple)
    my @s_or = $adb->search_table( $tbl, 'apple jbl', 'or' );
    is( scalar @s_or, 2, "OR search 'apple jbl' matches 2 records (IDs 3 and 5)" );
    is_deeply( [ sort { $a <=> $b } map { $_->[0] } @s_or ], [ 3, 5 ],
        "OR search returns IDs [3, 5]" );

    # 3. keys_only option: returns plain list of record ID scalars
    my @keys = $adb->search_table( $tbl, 'kulaklık', keys_only => 1 );
    is_deeply( [ sort { $a <=> $b } @keys ], [ 1, 2, 5, 6 ],
        "keys_only => 1 returns list of record ID scalars in unindexed search" );
};

# ==============================================================================
# SUBTEST 7: Bulk İşlemler (insert_list, modify_list, delete_list) - Unindexed
# ==============================================================================
subtest '7. Bulk CRUD (insert_list, modify_list, delete_list) Unindexed Search' => sub {
    plan tests => 17;

    my $tbl = 'bulk_unindexed';
    my $table_info = {
        record_index => 0,
    };
    $adb->table_attr( $tbl, $table_info );

    # --- A) BULK INSERT (insert_list) ---
    my @bulk_records = (
        [ 501, 'SKU-501', 'Kırmızı İpek Elbise',   'Yazlık pamuklu kırmızı elbise şık tasarım' ],
        [ 502, 'SKU-502', 'Mavi Kot Pantolon',     'Kumaş esnek mavi pantolon rahat kesim' ],
        [ 503, 'SKU-503', 'Siyah Deri Ceket',      'Hakiki deri şık siyah ceket klasik model' ],
    );

    my $ins_status = $adb->insert_list( $tbl, @bulk_records );
    is( scalar keys %$ins_status, 3, "Unindexed insert_list inserted 3 records" );

    # Verify search keywords find newly bulk-inserted records
    my @s_elbise = $adb->search_table( $tbl, 'elbise' );
    is( scalar @s_elbise, 1, "Unindexed search finds 1 record for 'elbise'" );
    is( $s_elbise[0]->[0], 501, "Matched ID is 501" );

    my @s_pantolon = $adb->search_table( $tbl, 'pantolon' );
    is( scalar @s_pantolon, 1, "Unindexed search finds 1 record for 'pantolon'" );
    is( $s_pantolon[0]->[0], 502, "Matched ID is 502" );

    my @s_ceket = $adb->search_table( $tbl, 'ceket' );
    is( scalar @s_ceket, 1, "Unindexed search finds 1 record for 'ceket'" );
    is( $s_ceket[0]->[0], 503, "Matched ID is 503" );

    # --- B) BULK MODIFY (modify_list) ---
    my @mod_records = (
        [ 501, 'SKU-501', 'Yeşil Keten Elbise',   'Yazlık keten yeşil elbise ferah' ],
        [ 502, 'SKU-502', 'Beyaz Kumaş Pantolon', 'Kumaş beyaz pantolon şık kesim' ],
    );

    my $mod_status = $adb->modify_list( $tbl, @mod_records );
    is( scalar keys %$mod_status, 2, "Unindexed modify_list modified 2 records" );

    # Verify old words return 0
    my @s_old_kirmizi = $adb->search_table( $tbl, 'kırmızı' );
    is( scalar @s_old_kirmizi, 0, "Old word 'kırmızı' returns 0 records after unindexed modify_list" );

    my @s_old_mavi = $adb->search_table( $tbl, 'mavi' );
    is( scalar @s_old_mavi, 0, "Old word 'mavi' returns 0 records after unindexed modify_list" );

    # Verify new words match
    my @s_new_yesil = $adb->search_table( $tbl, 'yeşil' );
    is( scalar @s_new_yesil, 1, "New word 'yeşil' returns 1 record after unindexed modify_list" );
    is( $s_new_yesil[0]->[0], 501, "Matched ID is 501" );

    my @s_new_beyaz = $adb->search_table( $tbl, 'beyaz' );
    is( scalar @s_new_beyaz, 1, "New word 'beyaz' returns 1 record after unindexed modify_list" );
    is( $s_new_beyaz[0]->[0], 502, "Matched ID is 502" );

    # --- C) BULK DELETE (delete_list) ---
    my $del_status = $adb->delete_list( $tbl, 501, 503 );
    is( scalar keys %$del_status, 2, "Unindexed delete_list deleted 2 records" );

    # Verify deleted words return 0
    my @s_del_yesil = $adb->search_table( $tbl, 'yeşil' );
    is( scalar @s_del_yesil, 0, "Deleted record word 'yeşil' returns 0 records after unindexed delete_list" );

    my @s_del_ceket = $adb->search_table( $tbl, 'ceket' );
    is( scalar @s_del_ceket, 0, "Deleted record word 'ceket' returns 0 records after unindexed delete_list" );
};

# ==============================================================================
# SUBTEST 8: Dynamic Schema Modification at Runtime (table_attr - Unindexed)
# ==============================================================================
subtest '8. Dynamic Schema Modification at Runtime (table_attr - Unindexed)' => sub {
    plan tests => 6;

    my $tbl = 'catalog_attr_dyn_unidx';
    my $table_info = {
        record_index => 0,
        search_block => [ 2, 3, 4, 9 ], # Initially search in Vendor (2), Author (3), Title (4), Barcode (9)
    };
    $adb->table_attr( $tbl, $table_info );

    # [ ID, SKU (1), Vendor (2), Author (3), Title (4), Price (5), Category (6), Desc (7), Stock (8), Barcode (9) ]
    my @records = (
        [ 1, 'SKU1', 'Arçelik', 'Mehmet', 'Buzdolabı NoFrost',        15000, 'Beyaz Eşya', 'A++', 10, '8690001' ],
        [ 2, 'SKU2', 'Beko',    'Arçelik', 'Çamaşır Makinesi',       12000, 'Beyaz Eşya', 'A++', 15, '8690002' ],
        [ 3, 'SKU3', 'Vestel',  'Ahmet',  'Arçelik Uyumlu Kumanda',    250, 'Aksesuar',   'Kum', 50, '8690003' ],
    );

    for my $r (@records) {
        $adb->insert_id( $tbl, $r->[0], @$r[ 1 .. $#$r ] );
    }

    # 1. Initially with search_block => [2, 3, 4, 9], "Arçelik" matches all 3 records (Vendor, Author, Title)
    my @s_all = $adb->search_table( $tbl, 'Arçelik' );
    is( scalar @s_all, 3, "Initial unindexed search 'Arçelik' across blocks [2,3,4,9] matches all 3 records" );
    is_deeply( [ sort { $a <=> $b } map { $_->[0] } @s_all ], [ 1, 2, 3 ],
        "Matched IDs are [1, 2, 3]" );

    # 2. Dynamically change search_block at runtime to only Title (4) and Barcode (9)
    my $attr_ok = $adb->table_attr( $tbl, { search_block => [ 4, 9 ] } );
    ok( $attr_ok, "table_attr successfully updated schema in-memory (unindexed)" );

    # Now searching "Arçelik" should ONLY match Record 3 (where it is in Title)
    my @s_narrowed = $adb->search_table( $tbl, 'Arçelik' );
    is( scalar @s_narrowed, 1, "Runtime narrowed unindexed search 'Arçelik' matches only 1 record" );
    is( $s_narrowed[0]->[0], 3, "Matched ID is 3 (Title match)" );

    # Searching barcode "8690001" matches Record 1
    my @s_barcode = $adb->search_table( $tbl, '8690001' );
    is( scalar @s_barcode, 1, "Barcode search '8690001' matches record 1 (unindexed)" );
};

done_testing();
