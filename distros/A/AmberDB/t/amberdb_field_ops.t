#!/usr/bin/env perl
use 5.016;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);

use AmberDB;

my $tmp_dir = tempdir( CLEANUP => 1 );
my $adb     = AmberDB->new( path => { dbase_dir => $tmp_dir } );

# ============================================================
# 1. SETUP SCHEMAS
# ============================================================
subtest '1. Setup Schemas' => sub {
    # 1. Standard table with no repeat blocks
    my $prod_schema = {
        name         => "Product Table",
        record_index => 1,
        match_block  => [ 2, 3 ], # price, status
        blocks       => [
            { id => "id",     name => "ID",       type => "num" },
            { id => "title",  name => "Başlık",   type => "text" },
            { id => "price",  name => "Fiyat",    type => "num" },
            { id => "status", name => "Durum",    type => "num" },
        ],
    };
    ok( $adb->table_infset( "shop_product", $prod_schema ), "Created shop_product schema" );

    # 2. Table with repeating blocks (repeat_start => 4, repeat_ids => 3)
    my $order_schema = {
        name         => "Order Table",
        record_index => 1,
        repeat_ids   => 3,
        repeat_start => 4,
        match_block  => [ 1, 3 ], # customer, item_ids
        blocks       => [
            { id => "id",       name => "ID",          type => "num" },
            { id => "customer", name => "Müşteri",     type => "text" },
            { id => "total",    name => "Toplam",      type => "num" },
            { id => "item_ids", name => "Ürün IDleri", type => "text" },
            { id => "items",    name => "Kalemler",    type => "repeat" },
        ],
    };
    ok( $adb->table_infset( "shop_order", $order_schema ), "Created shop_order schema" );
};

# ============================================================
# 2. update_field (Granular Field Updates & Clearing)
# ============================================================
subtest '2. update_field on Standard Table' => sub {
    # Insert initial record
    ok( $adb->insert_id( "shop_product", 101, "Mekanik Klavye", 1500, 1 ), "Inserted product 101" );

    my @rec1 = $adb->read_id( "shop_product", 101 );
    is( $rec1[2], 1500, "Initial price is 1500" );
    is( $rec1[3], 1, "Initial status is 1" );

    # 1. Update by block name ("price")
    ok( $adb->update_field( "shop_product", 101, "price", 1750 ), "update_field by block name 'price'" );
    my @rec2 = $adb->read_id( "shop_product", 101 );
    is( $rec2[2], 1750, "Price updated to 1750" );
    is( $rec2[1], "Mekanik Klavye", "Title remained unchanged" );

    # 2. Update by block index (3 -> status)
    ok( $adb->update_field( "shop_product", 101, 3, 2 ), "update_field by block index 3" );
    my @rec3 = $adb->read_id( "shop_product", 101 );
    is( $rec3[3], 2, "Status updated to 2" );

    # 3. Diff no-op: updating to the exact same value succeeds immediately
    ok( $adb->update_field( "shop_product", 101, "status", 2 ), "update_field no-op with identical value" );

    # 4. Clear/reset field value using undef
    ok( $adb->update_field( "shop_product", 101, "price", undef ), "update_field clear price with undef" );
    my @rec4 = $adb->read_id( "shop_product", 101 );
    is( $rec4[2], 0, "Price (numeric type) normalized to 0 on undef" );
    is( $rec4[1], "Mekanik Klavye", "Title still preserved" );

    # Clear text field
    ok( $adb->update_field( "shop_product", 101, "title", "" ), "update_field clear title with empty string" );
    my @rec4b = $adb->read_id( "shop_product", 101 );
    is( $rec4b[1], "", "Title is now empty string" );

    # Update numeric field with empty string "" -> must become 0
    ok( $adb->update_field( "shop_product", 101, "status", "" ), "update_field clear status with empty string" );
    my @rec4c = $adb->read_id( "shop_product", 101 );
    is( $rec4c[3], 0, "Status (numeric type) normalized to 0 on empty string" );

    # Updating numeric field that is already 0 with undef or "" succeeds cleanly
    ok( $adb->update_field( "shop_product", 101, "status", undef ), "update_field status (already 0) with undef is clean no-op" );
    my @rec4d = $adb->read_id( "shop_product", 101 );
    is( $rec4d[3], 0, "Status remains 0" );

    # 5. Guard: Block 0 (ID) cannot be modified via update_field
    my $bad_upd = $adb->update_field( "shop_product", 101, 0, 999 );
    ok( !$bad_upd, "update_field rejected on primary key ID (block 0)" );
    my @rec5 = $adb->read_id( "shop_product", 101 );
    is( $rec5[0], 101, "ID remains 101" );
};

# ============================================================
# 3. insert_field & update_field on Repeat Blocks
# ============================================================
subtest '3. insert_field on Repeat Blocks' => sub {
    # 1. Reject on non-repeat table
    my $bad_ins = $adb->insert_field( "shop_product", 101, "Extra Data" );
    ok( !$bad_ins, "insert_field rejected on table without repeat blocks" );

    # 2. Insert order with initial 2 items
    my $order_data = {
        id       => 501,
        customer => "Maruf Çetin",
        total    => 2500,
        items    => [
            [ 201, "Logitech Mouse", 1, 1000 ],
            [ 202, "Keychron Klavye", 1, 1500 ],
        ],
    };
    ok( $adb->insert_id( "shop_order", $order_data ), "Inserted order 501" );

    my $ord1 = $adb->read_id( "shop_order", 501, "inflate" );
    is( $ord1->{item_ids}, "201,202", "Initial repeat_ids is 201,202" );
    is( scalar(@{ $ord1->{items} }), 2, "Initial order has 2 items" );

    # 3. Duplicate ID protection: cannot insert item with existing child ID 202
    my $dup_item = [ 202, "Keychron Duplicate", 1, 1500 ];
    my $dup_res  = $adb->insert_field( "shop_order", 501, $dup_item );
    ok( !$dup_res, "insert_field rejected duplicate child item ID 202" );

    # 4. Append new repeat item via insert_field
    my $new_item = [ 203, "Mousepad XL", 1, 400 ];
    ok( $adb->insert_field( "shop_order", 501, $new_item ), "insert_field appended item 203" );

    # Verify storage and repeat_ids synchronization
    my @raw_ord = $adb->read_id( "shop_order", 501 );
    is( $raw_ord[3], "201,202,203", "repeat_ids automatically updated with 203" );
    is( ref($raw_ord[6]), 'ARRAY', "Block 6 is new repeat item" );
    is( $raw_ord[6]->[0], 203, "Item 203 is in raw storage" );

    # 5. Positional insert: pos => 0 (insert at beginning of repeat blocks)
    my $head_item = [ 200, "Bilek Desteği", 1, 250 ];
    ok( $adb->insert_field( "shop_order", 501, $head_item, pos => 0 ), "insert_field at pos => 0" );

    my $ord2 = $adb->read_id( "shop_order", 501, "inflate" );
    is( scalar(@{ $ord2->{items} }), 4, "Inflated order now has 4 items" );
    is( $ord2->{items}->[0]->[0], 200, "First item is now 200" );
    is( $ord2->{item_ids}, "200,201,202,203", "repeat_ids updated in correct order" );

    # 6. Test update_field on repeating items
    # A. Update by child ID
    my $upd_item = [ 202, "Keychron V2 Özel", 1, 1800 ];
    ok( $adb->update_field( "shop_order", 501, id => 202, $upd_item ), "update_field by id => 202" );
    my $ord_upd1 = $adb->read_id( "shop_order", 501, "inflate" );
    is( $ord_upd1->{items}->[2]->[1], "Keychron V2 Özel", "Item 202 updated title" );

    # B. Update by position: pos => 0 (repeat_start + 0)
    my $upd_pos0 = [ 200, "Bilek Desteği Deri", 1, 350 ];
    ok( $adb->update_field( "shop_order", 501, pos => 0, $upd_pos0 ), "update_field by pos => 0" );
    my $ord_upd2 = $adb->read_id( "shop_order", 501, "inflate" );
    is( $ord_upd2->{items}->[0]->[1], "Bilek Desteği Deri", "Item at pos 0 updated" );

    # C. Update by position: pos => 1 (repeat_start + 1)
    my $upd_pos1 = [ 201, "Logitech MX Master 3S", 1, 1200 ];
    ok( $adb->update_field( "shop_order", 501, pos => 1, $upd_pos1 ), "update_field by pos => 1 (repeat_start + 1)" );
    my $ord_upd3 = $adb->read_id( "shop_order", 501, "inflate" );
    is( $ord_upd3->{items}->[1]->[1], "Logitech MX Master 3S", "Item at pos 1 updated" );

    # D. Keyless fixed block update on repeat table ('customer' or 1)
    ok( $adb->update_field( "shop_order", 501, "customer", "Mustafa Kemal" ), "update_field without key ('customer')" );
    my $ord_upd4 = $adb->read_id( "shop_order", 501, "inflate" );
    is( $ord_upd4->{customer}, "Mustafa Kemal", "Fixed customer field updated without key" );

    ok( $adb->update_field( "shop_order", 501, 1, "Kemal Paşa" ), "update_field without key (block index 1)" );
    my $ord_upd5 = $adb->read_id( "shop_order", 501, "inflate" );
    is( $ord_upd5->{customer}, "Kemal Paşa", "Fixed customer block index 1 updated without key" );

    # E. Reject update by invalid ID or pos
    ok( !$adb->update_field( "shop_order", 501, id => 999, [ 999, "Yok", 1, 0 ] ), "update_field rejected on unknown child ID" );
    ok( !$adb->update_field( "shop_order", 501, pos => 99, [ 99, "Yok", 1, 0 ] ), "update_field rejected on out-of-range pos" );
};

# ============================================================
# 4. delete_field (Strict Mandatory id / pos Enforcement)
# ============================================================
subtest '4. delete_field on Repeat Blocks' => sub {
    # 1. Reject on non-repeat table
    my $bad_del1 = $adb->delete_field( "shop_product", 101, id => 2 );
    ok( !$bad_del1, "delete_field rejected on table without repeat blocks" );

    # 2. Reject calls without mandatory id or pos (bare numbers / ambiguous keys)
    my $bad_bare = $adb->delete_field( "shop_order", 501, 202 );
    ok( !$bad_bare, "delete_field rejected bare number without id => or pos =>" );

    my $bad_idx = $adb->delete_field( "shop_order", 501, 4 );
    ok( !$bad_idx, "delete_field rejected bare block index 4" );

    my $bad_key = $adb->delete_field( "shop_order", 501, index => 4 );
    ok( !$bad_key, "delete_field rejected non-standard key { index => 4 }" );

    # 3. Delete repeat item by explicit child ID: id => 202 (Keychron)
    ok( $adb->delete_field( "shop_order", 501, id => 202 ), "delete_field removed item with id => 202" );

    my $ord3 = $adb->read_id( "shop_order", 501, "inflate" );
    is( scalar(@{ $ord3->{items} }), 3, "Order now has 3 items after deleting 202" );
    is( $ord3->{item_ids}, "200,201,203", "repeat_ids automatically updated to 200,201,203" );

    # 4. Delete repeat item by explicit position: pos => 0 (first item, ID 200)
    ok( $adb->delete_field( "shop_order", 501, pos => 0 ), "delete_field removed repeat item at pos => 0" );

    my $ord4 = $adb->read_id( "shop_order", 501, "inflate" );
    is( scalar(@{ $ord4->{items} }), 2, "Order now has 2 items left" );
    is( $ord4->{item_ids}, "201,203", "repeat_ids updated to 201,203" );
    is( $ord4->{items}->[0]->[0], 201, "Remaining first item is 201" );

    # 5. Delete remaining items using hashref syntax { id => 201 } and { pos => 0 }
    ok( $adb->delete_field( "shop_order", 501, { id => 201 } ), "delete_field removed { id => 201 }" );
    ok( $adb->delete_field( "shop_order", 501, { pos => 0 } ),   "delete_field removed last item via { pos => 0 }" );

    my $ord5 = $adb->read_id( "shop_order", 501, "inflate" );
    is( scalar(@{ $ord5->{items} }), 0, "Order now has 0 items" );
    is( $ord5->{item_ids}, "", "repeat_ids is now empty" );
};

# ============================================================
# 5. delete_field Collision-Free Explicit Target Resolution
# ============================================================
subtest '5. delete_field Collision-Free Target Resolution' => sub {
    # Create order with items where one item has ID = 4 (same as repeat_start block index!)
    my $order_data = {
        id       => 601,
        customer => "Ali Veli",
        total    => 900,
        items    => [
            [ 10, "Item Ten",   1, 100 ], # pos 0
            [ 4,  "Item Four",  1, 400 ], # pos 1, child ID is 4!
            [ 20, "Item Twenty",1, 400 ], # pos 2
        ],
    };
    ok( $adb->insert_id( "shop_order", $order_data ), "Inserted order 601 with item ID 4 at pos 1" );

    # A. Delete by explicit id => 4 -> MUST delete "Item Four" at pos 1, NEVER pos 0!
    ok( $adb->delete_field( "shop_order", 601, id => 4 ), "delete_field with id => 4" );
    my $ord_a = $adb->read_id( "shop_order", 601, "inflate" );
    is( scalar(@{ $ord_a->{items} }), 2, "Order now has 2 items" );
    is( $ord_a->{items}->[0]->[0], 10, "First item is still Item Ten (ID 10)" );
    is( $ord_a->{items}->[1]->[0], 20, "Second item is Item Twenty (ID 20)" );

    # B. Delete by explicit pos => 0 (first repeat item -> ID 10)
    ok( $adb->delete_field( "shop_order", 601, pos => 0 ), "delete_field with pos => 0" );
    my $ord_b = $adb->read_id( "shop_order", 601, "inflate" );
    is( scalar(@{ $ord_b->{items} }), 1, "Order now has 1 item left" );
    is( $ord_b->{items}->[0]->[0], 20, "Remaining item is ID 20" );

    # C. Bare values or invalid keys rejected
    ok( !$adb->delete_field( "shop_order", 601, 20 ), "Bare ID 20 rejected" );
    ok( !$adb->delete_field( "shop_order", 601, 0 ),  "Bare pos 0 rejected" );
    ok( !$adb->delete_field( "shop_order", 601, "#5" ), "Magic prefix #5 rejected" );

    # D. Delete final item with { id => 20 }
    ok( $adb->delete_field( "shop_order", 601, { id => 20 } ), "delete_field with { id => 20 }" );
    my $ord_d = $adb->read_id( "shop_order", 601, "inflate" );
    is( scalar(@{ $ord_d->{items} }), 0, "Order is now empty" );
};

done_testing();
