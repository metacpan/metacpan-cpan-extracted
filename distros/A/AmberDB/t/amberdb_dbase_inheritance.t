use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use lib 'lib';
use AmberDB;

my $tmp_dir = tempdir( CLEANUP => 1 );
$ENV{AMBERDB_TEST_RAMDISK} = 1;

# ============================================================
# 1. Basic Inheritance & Whitelist Isolation Test
# ============================================================
subtest '1. Dbase Schema Inheritance and Whitelist Isolation' => sub {
    my $db_dir     = "$tmp_dir/db_inherit";
    my $schema_dir = "$db_dir/schema";
    my $table_dir  = "$db_dir/table";
    mkdir($db_dir);
    mkdir($schema_dir);
    mkdir($table_dir);

    # Create catalog.dbase with inheritable flags AND non-whitelisted keys
    my $dbase_file = "$schema_dir/catalog.dbase";
    open my $dfh, '>', $dbase_file or die "Cannot create $dbase_file: $!";
    print $dfh qq{
{
    name         => 'catalog',
    keep_deleted => 1,
    use_counter  => 1,
    log_owner    => 1,
    use_ramdisk  => 2,
    table_dir    => 'custom_catalog',
    # The following must be ignored by whitelist:
    search_block => [ 1, 2 ],
    blocks       => [ { id => "forbidden" } ],
    random_attr  => "should_not_leak",
    1            => "numeric_key_ignored",
}
};
    close $dfh;

    # Create catalog_item.table without any operational flags
    my $table_file = "$schema_dir/catalog_item.table";
    open my $tfh, '>', $table_file or die "Cannot create $table_file: $!";
    print $tfh qq{
{
    table        => 'catalog_item',
    record_index => 1,
    blocks       => [
        { id => "id",    name => "ID",    type => "auto_id" },
        { id => "title", name => "Title", type => "text" },
    ],
}
};
    close $tfh;

    my $adb = AmberDB->new(
        path => {
            dbase_dir  => $db_dir,
            schema_dir => $schema_dir,
            table_dir  => $table_dir,
        },
    );

    my $info = $adb->table_info("catalog_item");
    ok( $info && ref($info) eq 'HASH', "Loaded catalog_item table_info" );

    # Inherited whitelisted keys
    is( $info->{keep_deleted}, 1, "Inherited keep_deleted => 1 from catalog.dbase" );
    is( $info->{use_counter},  1, "Inherited use_counter => 1 from catalog.dbase" );
    is( $info->{log_owner},    1, "Inherited log_owner => 1 from catalog.dbase" );
    is( $info->{use_ramdisk},  2, "Inherited use_ramdisk => 2 from catalog.dbase" );
    is( $info->{table_dir},    'custom_catalog', "Inherited table_dir => 'custom_catalog' from catalog.dbase" );

    # Whitelist isolation: table-specific structures must NOT be inherited
    is( $info->{random_attr},  undef, "random_attr was not leaked from dbase" );
    is( $info->{1},            undef, "numeric key was not leaked from dbase" );
    is( $info->{search_block}, undef, "search_block was not leaked from dbase" );
    is( scalar( @{ $info->{blocks} } ), 2, "blocks array is from catalog_item, not dbase" );
    is( $info->{blocks}[0]{id}, "id", "first block is id from table" );

    # table_path respects inherited table_dir
    my $tpath = $adb->table_path("catalog_item");
    like( $tpath, qr{custom_catalog[\\/]catalog_item}, "table_path uses inherited custom_catalog dir" );
};

# ============================================================
# 2. Granular Table Overrides Test
# ============================================================
subtest '2. Granular Table-Level Overrides' => sub {
    my $db_dir     = "$tmp_dir/db_inherit";
    my $schema_dir = "$db_dir/schema";

    # Create catalog_override.table which overrides use_ramdisk, keep_deleted, table_dir
    my $table_file = "$schema_dir/catalog_override.table";
    open my $tfh, '>', $table_file or die "Cannot create $table_file: $!";
    print $tfh qq{
{
    table        => 'catalog_override',
    record_index => 1,
    keep_deleted => 0,      # Overrides dbase keep_deleted => 1
    use_ramdisk  => 0,      # Overrides dbase use_ramdisk => 2
    table_dir    => '',     # Overrides dbase table_dir => 'custom_catalog' (root dbase_dir)
    blocks       => [
        { id => "id",    name => "ID",    type => "auto_id" },
        { id => "title", name => "Title", type => "text" },
    ],
}
};
    close $tfh;

    my $adb = AmberDB->new(
        path => {
            dbase_dir  => $db_dir,
            schema_dir => $schema_dir,
        },
    );

    my $info = $adb->table_info("catalog_override");

    # Overridden keys must keep table's values
    is( $info->{keep_deleted}, 0, "Table override: keep_deleted is 0" );
    is( $info->{use_ramdisk},  0, "Table override: use_ramdisk is 0" );
    is( $info->{table_dir},    '', "Table override: table_dir is empty string" );

    # Non-overridden keys must still be inherited
    is( $info->{use_counter},  1, "Non-overridden: use_counter inherited as 1" );
    is( $info->{log_owner},    1, "Non-overridden: log_owner inherited as 1" );
};

# ============================================================
# 3. Operational Verification: Inherited keep_deleted
# ============================================================
subtest '3. Operational Verification of Inherited Behavior' => sub {
    my $db_dir     = "$tmp_dir/db_ops";
    my $schema_dir = "$db_dir/schema";
    my $table_dir  = "$db_dir/table";
    mkdir($db_dir);
    mkdir($schema_dir);
    mkdir($table_dir);

    # Create shop.dbase with keep_deleted => 1
    open my $dfh, '>', "$schema_dir/shop.dbase" or die $!;
    print $dfh qq{
{
    name         => 'shop',
    keep_deleted => 1,
}
};
    close $dfh;

    # shop_product does not specify keep_deleted (inherits 1)
    open my $tfh1, '>', "$schema_dir/shop_product.table" or die $!;
    print $tfh1 qq{
{
    table        => 'shop_product',
    record_index => 1,
    blocks       => [
        { id => "id",    name => "ID",    type => "auto_id" },
        { id => "title", name => "Title", type => "text" },
    ],
}
};
    close $tfh1;

    # shop_temp explicitly sets keep_deleted => 0
    open my $tfh2, '>', "$schema_dir/shop_temp.table" or die $!;
    print $tfh2 qq{
{
    table        => 'shop_temp',
    record_index => 1,
    keep_deleted => 0,
    blocks       => [
        { id => "id",    name => "ID",    type => "auto_id" },
        { id => "title", name => "Title", type => "text" },
    ],
}
};
    close $tfh2;

    my $adb = AmberDB->new(
        path => {
            dbase_dir  => $db_dir,
            schema_dir => $schema_dir,
            table_dir  => $table_dir,
        },
    );

    # 1. Test shop_product (inherited keep_deleted => 1)
    my $p_id = $adb->insert_id( "shop_product", 0, "Laptop" );
    ok( $p_id, "Inserted shop_product ID: $p_id" );
    $adb->delete_id( "shop_product", $p_id );

    my $p_del_file = $adb->table_path("shop_product") . ".del";
    ok( -e $p_del_file, "Soft-deleted archive .del file created for shop_product via inherited keep_deleted" );

    # 2. Test shop_temp (overridden keep_deleted => 0)
    my $t_id = $adb->insert_id( "shop_temp", 0, "Temporary" );
    ok( $t_id, "Inserted shop_temp ID: $t_id" );
    $adb->delete_id( "shop_temp", $t_id );

    my $t_del_file = $adb->table_path("shop_temp") . ".del";
    ok( !-e $t_del_file, "No .del file created for shop_temp due to table override keep_deleted => 0" );
};

done_testing();
