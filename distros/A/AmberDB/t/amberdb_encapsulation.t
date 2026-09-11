use strict;
use warnings;
use Test::More tests => 12;
use File::Temp qw(tempdir);
use AmberDB;

my $tmpdir = tempdir( CLEANUP => 1 );
$tmpdir =~ s{\\}{/}g;

my $adb = AmberDB->new(
    path => { dbase_dir => $tmpdir },
    cfg  => { user => "test_user", language => "tr" },
);

ok( defined $adb, "AmberDB instance created successfully" );

subtest "1. config() getter and setter tests" => sub {
    plan tests => 10;

    # 1.1 Single getter
    is( $adb->config('user'), "test_user", "config('user') returns initial value" );
    is( $adb->config('language'), "tr", "config('language') returns initial value" );

    # 1.2 Setter with key-value pairs
    $adb->config( custom_flag => "yes", no_write => 1 );
    is( $adb->config('custom_flag'), "yes", "config(custom_flag => 'yes') sets value" );
    is( $adb->config('no_write'), 1, "config(no_write => 1) sets value" );

    # 1.3 Setter with hashref
    $adb->config({ batch_limit => 50 });
    is( $adb->config('batch_limit'), 50, "config({ batch_limit => 50 }) sets value" );

    # 1.4 Language hook execution
    $adb->config( language => 'en' );
    is( $adb->config('language'), 'en', "config(language => 'en') updates language" );
    is( $adb->{_lang}, 'en', "config(language => 'en') triggered _load_locale hook" );

    # 1.5 db_ext hook execution (non-db triggers simple mode)
    $adb->config( db_ext => 'dat' );
    is( $adb->config('db_ext'), 'dat', "config(db_ext => 'dat') sets db_ext" );
    is( $adb->config('simple'), 1, "config(db_ext => 'dat') automatically triggers simple => 1" );

    # 1.6 Method chaining
    my $ret = $adb->config( no_write => 0 );
    is( $ret, $adb, "config(set) returns \$self for method chaining" );
};

subtest "2. config() shallow copy immutability" => sub {
    plan tests => 3;

    my $cfg_copy = $adb->config();
    ok( ref($cfg_copy) eq 'HASH', "config() without args returns HASH ref" );
    is( $cfg_copy->{user}, "test_user", "config copy has correct values" );

    # Mutate copy
    $cfg_copy->{user} = "hacked_user";
    $cfg_copy->{new_external_key} = 999;

    is( $adb->config('user'), "test_user", "Internal config user is NOT affected by mutating returned copy" );
};

subtest "3. table_attr() getter and setter tests" => sub {
    plan tests => 6;

    # 3.1 Set attributes via key-value
    my $ok = $adb->table_attr("demo_table", use_simple => 1, keep_deleted => 1);
    ok( $ok, "table_attr set via key-value succeeded" );

    # 3.2 Get single attribute
    is( $adb->table_attr("demo_table", "use_simple"), 1, "table_attr single getter returns correct value" );
    is( $adb->table_attr("demo_table", "keep_deleted"), 1, "table_attr single getter returns keep_deleted" );

    # 3.3 Set attributes via hashref
    $adb->table_attr("demo_table", { force => 1, custom_attr => "amber" });
    is( $adb->table_attr("demo_table", "force"), 1, "table_attr set via hashref succeeded" );
    is( $adb->table_attr("demo_table", "custom_attr"), "amber", "custom_attr is set" );

    # 3.4 Non-existent attribute
    is( $adb->table_attr("demo_table", "non_existent"), undef, "Non-existent attribute returns undef" );
};

subtest "4. table_attr() shallow copy immutability" => sub {
    plan tests => 3;

    my $attrs_copy = $adb->table_attr("demo_table");
    ok( ref($attrs_copy) eq 'HASH', "table_attr('demo_table') returns HASH ref" );
    is( $attrs_copy->{use_simple}, 1, "attrs copy has correct value" );

    # Mutate copy
    $attrs_copy->{use_simple} = 0;
    $attrs_copy->{injected_key} = "bad";

    is( $adb->table_attr("demo_table", "use_simple"), 1, "Internal table_attr is NOT affected by mutating returned copy" );
};

subtest "5. table_attr() path invalidation on path-affecting attributes" => sub {
    plan tests => 3;

    $adb->config( simple => 0, db_ext => 'db', use_section => 1 );
    my $path1 = $adb->table_path("demo_table");
    ok( length($path1) > 0, "Initial table path resolved: $path1" );

    # Ensure target section directory exists before switching section
    mkdir "$tmpdir/table_north" unless -d "$tmpdir/table_north";

    # Change section -> should invalidate cached path and recalculate
    $adb->table_attr("demo_table", section => "north");
    my $path2 = $adb->table_path("demo_table");
    ok( length($path2) > 0, "Updated table path resolved: $path2" );
    isnt( $path1, $path2, "Path was refreshed after section attribute changed" );
};

subtest "6. table_info() shallow copy protection" => sub {
    plan tests => 3;

    my $info = $adb->table_info("demo_table");
    ok( ref($info) eq 'HASH', "table_info returns HASH ref" );

    # Mutate returned info
    $info->{external_mutation} = "corrupted";
    $info->{use_simple} = 0;

    my $info_fresh = $adb->table_info("demo_table");
    ok( !exists $info_fresh->{external_mutation}, "Internal table_info does NOT have external mutations" );
    is( $adb->table_attr("demo_table", "use_simple"), 1, "Internal use_simple remains intact" );
};

subtest "7. Hash::Util protection: Disallowed typo and public keys" => sub {
    plan tests => 3;

    eval {
        $adb->{disallowed_random_key} = "illegal";
    };
    like( $@, qr/disallowed key/i, "Attempting to assign an unauthorized key throws disallowed key error" );

    eval {
        $adb->{cfg} = { user => "hacker" };
    };
    like( $@, qr/disallowed key/i, "Direct assignment to \$adb->{cfg} is strictly disallowed" );

    eval {
        $adb->{path} = { dbase_dir => "/tmp" };
    };
    like( $@, qr/disallowed key/i, "Direct assignment to \$adb->{path} is strictly disallowed" );
};

subtest "8. Hash::Util protection: Locked core container references" => sub {
    plan tests => 3;

    eval {
        $adb->{_table} = {};
    };
    like( $@, qr/read-only/i, "Attempting to overwrite \$adb->{_table} throws read-only error" );

    eval {
        $adb->{_cfg} = {};
    };
    like( $@, qr/read-only/i, "Attempting to overwrite \$adb->{_cfg} throws read-only error" );

    eval {
        $adb->{_path} = {};
    };
    like( $@, qr/read-only/i, "Attempting to overwrite \$adb->{_path} throws read-only error" );
};

subtest "9. Full CRUD operation under encapsulated object" => sub {
    plan tests => 5;

    $adb->config( no_write => 0 );
    my $table = "crud_table";
    
    # Insert
    my $rid = $adb->insert_id( $table, 1, "Record 1", "Active", "2026-08-27" );
    is( $rid, 1, "insert_id succeeded: rid = $rid" );

    # Read
    my ($id, @rec) = $adb->read_id( $table, 1 );
    is( $rec[0], "Record 1", "read_id retrieved correct data" );

    # Modify
    my $mod_ok = $adb->modify_id( $table, 1, "Record 1 Modified", "Active", "2026-08-27" );
    ok( $mod_ok, "modify_id succeeded" );

    my ($id_mod, @rec_mod) = $adb->read_id( $table, 1 );
    is( $rec_mod[0], "Record 1 Modified", "read_id verified modified data" );

    # Delete
    my $del_ok = $adb->delete_id( $table, 1 );
    ok( $del_ok, "delete_id succeeded" );
};

subtest "10. path() getter, setter and shallow copy immutability" => sub {
    plan tests => 6;

    # Getter
    is( $adb->path('dbase_dir'), $tmpdir, "path('dbase_dir') returns expected directory" );

    # Setter via key-value
    $adb->path( custom_path => "/opt/data" );
    is( $adb->path('custom_path'), "/opt/data", "path(custom_path => ...) sets path" );

    # Setter via hashref
    $adb->path({ backup_dir => "$tmpdir/backup" });
    is( $adb->path('backup_dir'), "$tmpdir/backup", "path({ backup_dir => ... }) sets path" );

    # Bulk copy
    my $paths_copy = $adb->path();
    ok( ref($paths_copy) eq 'HASH', "path() returns HASH ref" );
    is( $paths_copy->{dbase_dir}, $tmpdir, "path copy contains dbase_dir" );

    # Mutation protection
    $paths_copy->{dbase_dir} = "/compromised/path";
    is( $adb->path('dbase_dir'), $tmpdir, "Internal path is NOT affected by mutating copy" );
};

subtest "11. Default engine configuration" => sub {
    plan tests => 3;

    my $adb_def = AmberDB->new();
    is( $adb_def->config('language'), 'gb', "default config('language') is 'gb'" );
    is( $adb_def->{_lang}, 'gb', "default internal _lang is 'gb'" );
    is( $adb_def->language, 'gb', "default language() accessor is 'gb'" );
};
