#!/usr/bin/perl

# t/flatdb_repeat.t - Unit tests for repeat_ids and repeat_start field joining in AmberDB

use 5.016000;
use strict;
use warnings;
use Test::More;

use AmberDB;

# ---------------------------------------------------------------------------
subtest 'order_active schema repeat_fields unit test' => sub {
    my $db = AmberDB->new( cfg => { use_simple => 1 } );

    # Real-world schema structure from order_active.table
    my $table_info = {
        repeat_ids   => 12,
        repeat_start => 15,
        blocks       => [
            { id => 'id',                name => 'ID' },                   # 0
            { id => 'member_id',         name => 'Üye ID' },               # 1
            { id => 'invoice_no',        name => 'Fatura No' },            # 2
            { id => 'amounts',           name => 'Tutarlar' },             # 3
            { id => 'timestamps',        name => 'Tarihler' },             # 4
            { id => 'status',            name => 'Statü' },                # 5
            { id => 'session_id',        name => 'Session ID' },           # 6
            { id => 'delivery_address',  name => 'Teslim Adresi' },        # 7
            { id => 'invoice_address',   name => 'Fatura Adresi' },        # 8
            { id => 'cargo',             name => 'Kargo Bilgileri' },      # 9
            { id => 'payment_info',      name => 'Ödeme Tipi' },           # 10
            { id => 'credit_card_info',  name => 'Kredi Kartı Bilgileri' },# 11
            { id => 'product_ids',       name => 'Ürün Döngüsü' },         # 12 (repeat_ids)
            { id => 'member_notes',      name => 'Üye Notları' },          # 13
            { id => 'gift_products',     name => 'Hediye Ürün Listesi' },  # 14
            { id => 'products',          name => 'Ürünler' },              # 15 (repeat_start)
        ],
    };

    my $rid = 'REC101';
    my @fields = (
        '1001',             # 0: member_id (block 1)
        'INV-2026-001',     # 1: invoice_no (block 2)
        '1500.00',          # 2: amounts (block 3)
        '2026-08-09',       # 3: timestamps (block 4)
        '1',                # 4: status (block 5)
        'SESS12345',        # 5: session_id (block 6)
        'Address A',        # 6: delivery_address (block 7)
        'Address B',        # 7: invoice_address (block 8)
        'Cargo X',          # 8: cargo (block 9)
        'CreditCard',       # 9: payment_info (block 10)
        '**** 1234',        # 10: credit_card_info (block 11)
        '',                 # 11: product_ids (block 12 -> repeat_ids = 12)
        'Note 1',           # 12: member_notes (block 13)
        'Gift 1',           # 13: gift_products (block 14)
        ['P101', 'Item 1'], # 14: product 1 (block 15 -> repeat_start = 15)
        ['P102', 'Item 2'], # 15: product 2 (block 16)
        ['P103', 'Item 3'], # 16: product 3 (block 17)
    );

    # Add items up to 30 total blocks in full record
    for my $i ( 4 .. 15 ) {
        push @fields, [ "P10$i", "Item $i" ];
    }

    # Calling repeat_fields with full record [$rid, @fields]
    my @processed = $db->repeat_fields( $table_info, $rid, @fields );

    # Index 0 is $rid
    is( $processed[0], 'REC101', 'First element in returned array is $rid' );

    # Index 12 is product_ids (block 12)
    is( $processed[12], 'P101,P102,P103,P104,P105,P106,P107,P108,P109,P1010,P1011,P1012,P1013,P1014,P1015',
        'repeat_ids field (index 12 / block 12) is populated with product keys P101..P1015' );

    # Verify adjacent fixed fields are completely untouched
    is( $processed[13], 'Note 1', 'member_notes (index 13 / block 13) is untouched' );
    is( $processed[14], 'Gift 1', 'gift_products (index 14 / block 14) is untouched' );

    # Verify first product item at index 15 (block 15) is intact
    is_deeply( $processed[15], ['P101', 'Item 1'], 'First product item (index 15 / block 15) is intact' );
};

# ---------------------------------------------------------------------------
subtest 'repeat_fields skips empty / undef blocks without double commas' => sub {
    my $db = AmberDB->new( cfg => { use_simple => 1 } );

    my $table_info = {
        repeat_ids   => 2,
        repeat_start => 4,
        blocks       => [
            { id => 'id',        name => 'ID' },
            { id => 'title',     name => 'Title' },
            { id => 'rep_ids',   name => 'Repeat IDs' },
            { id => 'cat',       name => 'Category' },
            { id => 'var1',      name => 'Var 1' },
            { id => 'var2',      name => 'Var 2' },
            { id => 'var3',      name => 'Var 3' },
            { id => 'var4',      name => 'Var 4' },
            { id => 'var5',      name => 'Var 5' },
        ],
    };

    my @full_record = (
        '101',
        'Product A',
        '',
        'Tech',
        ['14', 'Item 14'],
        '',                 # empty string
        ['26', 'Item 26'],
        undef,              # undef block
        ['85', 'Item 85'],
    );

    my @processed = $db->repeat_fields( $table_info, @full_record );

    is( $processed[2], '14,26,85', 'Empty/undef blocks are skipped; output is "14,26,85" without double commas' );
};

done_testing();
