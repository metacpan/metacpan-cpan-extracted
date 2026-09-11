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
# 1. SETUP SCHEMAS FOR TEST
# ============================================================
subtest '1. Setup Schemas' => sub {
    # Brand table
    my $brand_schema = {
        name         => "Brand Table",
        record_index => 1,
        match_block  => [1],
        blocks       => [
            { id => "id",       name => "ID",     type => "auto_id" },
            { id => "name",     name => "Marka",  type => "text" },
            { id => "discount", name => "İndirim",type => "num" },
        ],
    };
    ok( $adb->table_infset( "catalog_brand", $brand_schema ), "Created catalog_brand schema" );

    # Author table
    my $author_schema = {
        name         => "Author Table",
        record_index => 1,
        match_block  => [1],
        blocks       => [
            { id => "id",   name => "ID",    type => "auto_id" },
            { id => "name", name => "Yazar", type => "text" },
        ],
    };
    ok( $adb->table_infset( "catalog_author", $author_schema ), "Created catalog_author schema" );

    # Product table with RDBM links
    my $prod_schema = {
        name         => "Product Table",
        record_index => 1,
        match_block  => [ 1, 3, 5 ],
        search_block => [1],
        blocks       => [
            { id => "id",      name => "ID",       type => "auto_id" },
            { id => "title",   name => "Başlık",   type => "text" },
            { id => "price",   name => "Fiyat",    type => "num" },
            { id => "brand",   name => "Marka",    type => "num",  rdbm => "catalog_brand;1" },
            { id => "authors", name => "Yazarlar", type => "text", rdbm => "catalog_author;1" },
            { id => "cat",     name => "Kategori", type => "num" },
        ],
    };
    ok( $adb->table_infset( "catalog_product", $prod_schema ), "Created catalog_product schema" );
};

# ============================================================
# 2. WRITE OPERATIONS VIA HASHREF (deflate integration)
# ============================================================
subtest '2. Deflate & Write Operations' => sub {
    # Single insert_id with hashref (auto-id)
    my $b1_id = $adb->insert_id( "catalog_brand", { name => "Samsung", discount => 15 } );
    is( $b1_id, 1, "insert_id brand 1 with hashref" );

    # Single insert_id with explicit id
    my $b2_id = $adb->insert_id( "catalog_brand", 2, { name => "Apple", discount => 10 } );
    is( $b2_id, 2, "insert_id brand 2 with explicit ID" );

    # modify_id with hashref
    my $mod_ok = $adb->modify_id( "catalog_brand", 1, { name => "Samsung", discount => 20 } );
    ok( $mod_ok, "modify_id with hashref updated record" );

    # Verify brand 1 raw read
    my @b1_raw = $adb->read_id( "catalog_brand", 1 );
    is( $b1_raw[0], 1, "Brand 1 ID is 1" );
    is( $b1_raw[1], "Samsung", "Brand 1 name is Samsung" );
    is( $b1_raw[2], 20, "Brand 1 discount updated to 20" );

    # Bulk insert_list with array of hashrefs
    my $authors_res = $adb->insert_list( "catalog_author", [
        { name => "Ahmet Altan" },
        { name => "Maruf Çetin" },
        { name => "Sevim Altun" },
    ]);
    ok( $authors_res && keys %$authors_res == 3, "insert_list with array of hashrefs created 3 authors" );

    # Product inserts with multi-value foreign keys
    my $p1_id = $adb->insert_id( "catalog_product", {
        title   => "Perl ile Sistem Programlama",
        price   => 150,
        brand   => 1,
        authors => "1,2", # Ahmet Altan & Maruf Çetin
        cat     => 5,
    });
    is( $p1_id, 1, "insert_id product 1 created" );

    my $p2_id = $adb->insert_id( "catalog_product", {
        title   => "Modern Web Mimarisi",
        price   => 200,
        brand   => 2,
        authors => "2,3", # Maruf Çetin & Sevim Altun
        cat     => 5,
    });
    is( $p2_id, 2, "insert_id product 2 created" );
};

# ============================================================
# 3. SINGLE READ OPERATIONS (read_id with inflate)
# ============================================================
subtest '3. read_id Inflate' => sub {
    # 1. Classic raw read (backward compatibility)
    my @raw = $adb->read_id( "catalog_brand", 1 );
    is( scalar(@raw), 3, "Classic read_id returns raw array of 3 elements" );
    is( $raw[1], "Samsung", "Raw element 1 matches" );

    # 2. Counter / numeric flag (must NOT trigger inflate)
    my @counter_raw = $adb->read_id( "catalog_brand", 1, 1 );
    is( ref(\@counter_raw), 'ARRAY', "Numeric 3rd argument does not return hashref" );
    is( $counter_raw[1], "Samsung", "Numeric 3rd argument returns raw fields" );

    # 3. String "inflate"
    my $b_hash = $adb->read_id( "catalog_brand", 1, "inflate" );
    is( ref($b_hash), 'HASH', "read_id with 'inflate' returns hashref" );
    is( $b_hash->{id}, 1, "Inflated brand ID is 1" );
    is( $b_hash->{name}, "Samsung", "Inflated brand name is Samsung" );
    is( $b_hash->{discount}, 20, "Inflated brand discount is 20" );

    # 4. HashRef options { inflate => 1 }
    my $b_hash_opt = $adb->read_id( "catalog_brand", 2, { inflate => 1 } );
    is( ref($b_hash_opt), 'HASH', "read_id with { inflate => 1 } returns hashref" );
    is( $b_hash_opt->{name}, "Apple", "Brand 2 is Apple" );
};

# ============================================================
# 4. RDBM RESOLUTION & MULTI-VALUE BLOCKS
# ============================================================
subtest '4. RDBM Resolution & Multi-Value' => sub {
    # Default display mode for RDBM
    my $p1 = $adb->read_id( "catalog_product", 1, "inflate" );
    is( ref($p1), 'HASH', "Product 1 inflated" );
    is( $p1->{title}, "Perl ile Sistem Programlama", "Title inflated" );
    is( $p1->{price}, 150, "Price inflated" );

    # Brand (single RDBM display)
    is( ref($p1->{brand}), 'HASH', "brand is resolved to hashref" );
    is( $p1->{brand}->{1}, "Samsung", "brand 1 resolved to display name 'Samsung'" );

    # Authors (multi-value RDBM display: "1,2")
    is( ref($p1->{authors}), 'HASH', "authors is resolved to hashref" );
    is( $p1->{authors}->{1}, "Ahmet Altan", "Author 1 display is Ahmet Altan" );
    is( $p1->{authors}->{2}, "Maruf Çetin", "Author 2 display is Maruf Çetin" );

    # Full mode for Brand, Display for Authors
    my $p1_full = $adb->read_id( "catalog_product", 1, {
        inflate => {
            block => {
                brand   => 'full',
                authors => 'display',
            }
        }
    });
    is( ref($p1_full->{brand}->{1}), 'HASH', "Brand 1 resolved to full hashref" );
    is( $p1_full->{brand}->{1}->{name}, "Samsung", "Full brand has name" );
    is( $p1_full->{brand}->{1}->{discount}, 20, "Full brand has discount" );
    is( $p1_full->{authors}->{1}, "Ahmet Altan", "Authors still in display mode" );

    # Block rule 0 / none (raw foreign ID preserved)
    my $p1_raw_fk = $adb->read_id( "catalog_product", 1, {
        inflate => {
            block => {
                brand => 0,
            }
        }
    });
    is( $p1_raw_fk->{brand}, 1, "Brand with rule 0 remains raw foreign ID 1" );
};

# ============================================================
# 5. MULTI-RECORD READ (read_all with inflate)
# ============================================================
subtest '5. read_all with Inflate' => sub {
    # 1. inflate => 'list' (Array of Hashes)
    my ( $total_list, $res_list ) = $adb->read_all( "catalog_product", {
        inflate => 'list',
        limit   => 10,
        dir     => 'asc',
    });
    is( $total_list, 2, "Total count is 2" );
    is( ref($res_list), 'ARRAY', "result is ArrayRef when inflate => 'list'" );
    is( scalar(@$res_list), 2, "2 records returned" );
    is( $res_list->[0]->{title}, "Perl ile Sistem Programlama", "First product title" );
    is( $res_list->[1]->{title}, "Modern Web Mimarisi", "Second product title" );
    is( $res_list->[1]->{authors}->{3}, "Sevim Altun", "Author 3 resolved in second product" );

    # 2. inflate => 'hash' (Hash of Hashes keyed by ID)
    my ( $total_hash, $res_hash ) = $adb->read_all( "catalog_product", {
        inflate => 'hash',
        limit   => 10,
    });
    is( $total_hash, 2, "Total count is 2" );
    is( ref($res_hash), 'HASH', "result is HashRef when inflate => 'hash'" );
    ok( exists $res_hash->{1}, "Key 1 exists in hash" );
    ok( exists $res_hash->{2}, "Key 2 exists in hash" );
    is( $res_hash->{1}->{price}, 150, "Product 1 price accessed via ID key" );
    is( $res_hash->{2}->{price}, 200, "Product 2 price accessed via ID key" );

    # 3. Classic read_all without inflate (backward compatibility)
    my ( $total_classic, @classic_records ) = $adb->read_all( "catalog_product", limit => 10, dir => 'asc' );
    is( $total_classic, 2, "Total classic count is 2" );
    is( scalar(@classic_records), 2, "Classic read_all returns list" );
    is( ref($classic_records[0]), 'ARRAY', "Classic element is raw arrayref" );
};

# ============================================================
# 6. SCHEMALESS / MISSING SCHEMA FALLBACK
# ============================================================
subtest '6. Schemaless Table Return Consistency' => sub {
    # Insert raw record into a table without schema
    $adb->insert_id( "schemaless_table", 1, "ValA", "ValB" );

    # read_id with inflate on schemaless table
    my $res_single = $adb->read_id( "schemaless_table", 1, "inflate" );
    is( ref($res_single), 'ARRAY', "Schemaless read_id with inflate returns ArrayRef (not broken scalar)" );
    is( $res_single->[1], "ValA", "Field accessible by array index [1]" );

    # read_all with inflate on schemaless table
    my ( $cnt, $res_all ) = $adb->read_all( "schemaless_table", { inflate => 1, limit => 10 } );
    is( $cnt, 1, "Schemaless count is 1" );
    is( ref($res_all), 'ARRAY', "Schemaless read_all returns ArrayRef reference" );
    is( $res_all->[0]->[1], "ValA", "Field accessible by [0]->[1]" );
};

# ============================================================
# 7. field_fetch & search_table WITH INFLATE
# ============================================================
subtest '7. field_fetch and search_table with inflate' => sub {
    # field_fetch on category block 5
    my ( $ff_cnt, $ff_list ) = $adb->field_fetch( "catalog_product", 5, 5, {
        inflate => 'list',
        limit   => 10,
        dir     => 'asc',
    });
    is( $ff_cnt, 2, "field_fetch found 2 products in cat 5" );
    is( ref($ff_list), 'ARRAY', "field_fetch with inflate returns ArrayRef" );
    is( $ff_list->[0]->{title}, "Perl ile Sistem Programlama", "First match title" );

    # search_table on search term "Perl"
    my ( $st_cnt, $st_list ) = $adb->search_table( "catalog_product", "Perl", {
        inflate => 'list',
        limit   => 10,
    });
    is( $st_cnt, 1, "search_table found 1 product" );
    is( ref($st_list), 'ARRAY', "search_table with inflate returns ArrayRef" );
    is( $st_list->[0]->{title}, "Perl ile Sistem Programlama", "Search matched Perl title" );
    is( $st_list->[0]->{brand}->{1}, "Samsung", "RDBM brand resolved in search result" );
};

# ============================================================
# 8. DIRECT HELPER (inflate / deflate)
# ============================================================
subtest '8. Direct inflate & deflate' => sub {
    my $raw_rec = [ 1, "Perl Book", 120, 1, "1,2", 5 ];

    my $h1 = $adb->inflate( "catalog_product", $raw_rec );
    is( $h1->{id}, 1, "Direct inflate ID is 1" );
    is( $h1->{title}, "Perl Book", "Direct inflate title" );
    is( $h1->{brand}->{1}, "Samsung", "Direct inflate RDBM brand" );

    my $input_hash = {
        id      => 1,
        title   => "Perl Book",
        price   => 120,
        brand   => { 1 => "Samsung" }, # RDBM hash to be deflated back to 1
        authors => { 1 => "Ahmet", 2 => "Maruf" }, # To be deflated back to "1,2"
        cat     => 5,
    };

    my $d1 = $adb->deflate( "catalog_product", $input_hash );
    is( $d1->[0], 1, "Deflated ID is 1" );
    is( $d1->[1], "Perl Book", "Deflated title" );
    is( $d1->[3], "1", "Deflated brand hash to 1" );
    is( $d1->[4], "1,2", "Deflated authors hash to 1,2" );
};

# ============================================================
# 9. REPEATING RECORDS (repeat_start & type => repeat)
# ============================================================
subtest '9. Repeating records (repeat_start / type => repeat)' => sub {
    my $cart_schema = {
        name         => "Order Cart Table",
        record_index => 1,
        repeat_ids   => 3,
        repeat_start => 4,
        match_block  => [ 1, 3 ],
        blocks       => [
            { id => "id",       name => "ID",          type => "num" },
            { id => "customer", name => "Müşteri",     type => "text" },
            { id => "total",    name => "Toplam",      type => "num" },
            { id => "item_ids", name => "Ürün IDleri", type => "text" },
            { id => "product",  name => "Ürünler",     type => "repeat" },
        ],
    };
    ok( $adb->table_infset( "order_cart", $cart_schema ), "Created order_cart schema" );

    # 1. Insert order with repeat items using hashref
    my $order_in = {
        id       => 501,
        customer => "Maruf Çetin",
        total    => 3500.50,
        product  => [
            [ 101, "Logitech MX Master 3", 1, 1500.00 ],
            [ 102, "Keychron Q1 Pro", 1, 2000.50 ],
        ],
    };
    ok( $adb->insert_id( "order_cart", $order_in ), "Inserted order 501 with repeating products" );

    # 2. Verify raw storage array
    my @raw = $adb->read_id( "order_cart", 501 );
    is( $raw[0], 501, "Raw id is 501" );
    is( $raw[1], "Maruf Çetin", "Raw customer" );
    is( $raw[2], 3500.50, "Raw total" );
    is( $raw[3], "101,102", "Raw item_ids (repeat_ids) compiled automatically from repeat products" );
    is( ref($raw[4]), 'ARRAY', "Raw block 4 (repeat_start) is product 1 array" );
    is( $raw[4]->[0], 101, "Product 1 code is 101" );
    is( ref($raw[5]), 'ARRAY', "Raw block 5 is product 2 array" );
    is( $raw[5]->[0], 102, "Product 2 code is 102" );

    # 3. Read with inflate: $result->{product} = \@record[$repeat_start..$#record]
    my $inflated = $adb->read_id( "order_cart", 501, "inflate" );
    is( ref($inflated), 'HASH', "Inflated order is hashref" );
    is( $inflated->{id}, 501, "Inflated id" );
    is( $inflated->{customer}, "Maruf Çetin", "Inflated customer" );
    is( $inflated->{item_ids}, "101,102", "Inflated item_ids" );
    is( ref($inflated->{product}), 'ARRAY', "Inflated product is arrayref" );
    is( scalar(@{ $inflated->{product} }), 2, "Inflated product has 2 repeat items" );
    is( $inflated->{product}->[0]->[1], "Logitech MX Master 3", "First repeat item title" );
    is( $inflated->{product}->[1]->[1], "Keychron Q1 Pro", "Second repeat item title" );

    # 4. Modify with updated repeat items
    my $order_mod = {
        id       => 501,
        customer => "Maruf Çetin",
        total    => 4000.00,
        product  => [
            [ 101, "Logitech MX Master 3", 1, 1500.00 ],
            [ 102, "Keychron Q1 Pro", 1, 2000.50 ],
            [ 103, "Mousepad", 1, 499.50 ],
        ],
    };
    ok( $adb->modify_id( "order_cart", $order_mod ), "Modified order 501 with 3 repeat products" );

    my $upd_order = $adb->read_id( "order_cart", 501, { inflate => 1 } );
    is( scalar(@{ $upd_order->{product} }), 3, "Updated order has 3 repeat products" );
    is( $upd_order->{item_ids}, "101,102,103", "repeat_ids updated automatically after modify" );
    is( $upd_order->{product}->[2]->[0], 103, "Third repeat item is 103" );

    # 5. Insert order with empty repeat list
    my $order_empty = {
        id       => 502,
        customer => "Ahmet Altan",
        total    => 0,
        product  => [],
    };
    ok( $adb->insert_id( "order_cart", $order_empty ), "Inserted order 502 with no repeat products" );

    my $inf_empty = $adb->read_id( "order_cart", 502, "inflate" );
    is( ref($inf_empty->{product}), 'ARRAY', "Empty repeat block returns arrayref" );
    is( scalar(@{ $inf_empty->{product} }), 0, "Empty repeat products has 0 items" );

    # 6. Multi-record reading with repeat blocks (read_all)
    my ( $cnt_all, $all_hash ) = $adb->read_all( "order_cart", { inflate => 'hash', limit => 10 } );
    is( $cnt_all, 2, "read_all with limit found 2 orders" );
    is( ref($all_hash), 'HASH', "read_all with inflate => 'hash' returns hashref" );
    is( scalar(@{ $all_hash->{501}->{product} }), 3, "Order 501 in read_all hash has 3 repeat products" );
    is( scalar(@{ $all_hash->{502}->{product} }), 0, "Order 502 in read_all hash has 0 repeat products" );

    # read_all without limit returns scalar ref directly
    my $all_hash_nolim = $adb->read_all( "order_cart", { inflate => 'hash' } );
    is( ref($all_hash_nolim), 'HASH', "read_all without limit returns scalar hashref" );
    is( scalar(@{ $all_hash_nolim->{501}->{product} }), 3, "Order 501 has 3 repeat items in no-limit read" );

    # 7. Direct inflate & deflate check
    my $direct_slice = [ 503, "Sevim Altun", 100, "", [ 201, "Book" ], [ 202, "Pen" ] ];
    my $direct_h = $adb->inflate( "order_cart", $direct_slice );
    is_deeply(
        $direct_h->{product},
        [ [ 201, "Book" ], [ 202, "Pen" ] ],
        "Direct inflate correctly slices repeat_start..#record"
    );

    my $direct_def = $adb->deflate( "order_cart", $direct_h );
    is( $direct_def->[0], 503, "Deflated ID is 503" );
    is( $direct_def->[3], "201,202", "Deflated auto-computed repeat_ids is 201,202" );
    is_deeply( $direct_def->[4], [ 201, "Book" ], "Deflated block 4 is first repeat item" );
    is_deeply( $direct_def->[5], [ 202, "Pen" ], "Deflated block 5 is second repeat item" );
};

done_testing();
