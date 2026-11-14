#!/usr/bin/perl

# t/amberdb/amberdb_security_paths.t - Tests for path sanitization, simple mode IDs, and transact_error

use 5.016000;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use lib 'lib';
use AmberDB;

my $tmpdir = tempdir( CLEANUP => 1 );
my $adb = AmberDB->new(
    path => { dbase_dir => $tmpdir },
    cfg  => { use_simple => 0 }
);

# ---------------------------------------------------------------------------
subtest '1. Path Traversal & Table Name Sanitization' => sub {
    plan tests => 10;

    is( $adb->sanitize_table("uyeler/bekleyen.uyeler"), "uyeler/bekleyen.uyeler", "Allows subdirectories and dots" );
    is( $adb->sanitize_table("./dosya"), "dosya", "Strips ./" );
    is( $adb->sanitize_table(".\\dosya"), "dosya", "Strips .\\" );
    is( $adb->sanitize_table("../secret"), "secret", "Strips ../" );
    is( $adb->sanitize_table("..\\secret"), "secret", "Strips ..\\" );
    is( $adb->sanitize_table("../../etc/passwd"), "etc/passwd", "Strips nested ../../" );
    is( $adb->sanitize_table("uyeler/../secret"), "uyeler/secret", "Strips inner .. segment" );
    is( $adb->sanitize_table("uyeler/./bekleyen"), "uyeler/bekleyen", "Strips inner . segment" );
    is( $adb->sanitize_table("/.dosya"), ".dosya", "Allows hidden file style /.dosya" );
    is( $adb->sanitize_table("uyeler/.gizli"), "uyeler/.gizli", "Allows hidden file style uyeler/.gizli" );
};

# ---------------------------------------------------------------------------
subtest '2. table_path resolution and subdirectory auto-creation' => sub {
    plan tests => 3;

    my $path1 = $adb->table_path("test_basic");
    like( $path1, qr{test_basic$}, "Basic table path resolved" );

    my $path2 = $adb->table_path("uyeler/bekleyen.uyeler");
    like( $path2, qr{uyeler/bekleyen\.uyeler$}, "Subdirectory table path resolved" );

    my $path3 = $adb->table_path("../../../escape_test");
    unlike( $path3, qr{\.\.}, "Path traversal not present in resolved path" );
};

# ---------------------------------------------------------------------------
subtest '3. Simple Mode Arbitrary String ID Length' => sub {
    plan tests => 4;

    # Standard mode: only numeric positive integer allowed
    $adb->config( use_simple => 0 );
    $adb->table_attr( test_table => { use_simple => 0 } );
    
    my $valid_num = $adb->id_check("test_table", "12345");
    is( $valid_num, "12345", "Numeric ID accepted in standard mode" );

    my $str_id = $adb->id_check("test_table", "user123_abc");
    is( $str_id, "123", "Non-digits stripped in standard mode" );

    # Table use_simple mode: arbitrary string ID allowed
    $adb->table_attr( test_table => { use_simple => 1 } );
    my $uuid = "123e4567-e89b-12d3-a456-426614174000";
    my $simple_uuid = $adb->id_check("test_table", $uuid);
    is( $simple_uuid, $uuid, "Long UUID accepted in table use_simple mode" );

    my $email_id = $adb->id_check("test_table", 'test.user_99@example.com');
    is( $email_id, 'test.user_99@example.com', "Exact email ID preserved intact in table use_simple mode" );
};

# ---------------------------------------------------------------------------
subtest '4. Transact transact_error and rollback' => sub {
    plan tests => 4;

    can_ok( $adb, 'transact_error' );

    $adb->{_error} = [];
    $adb->transact_start();

    $adb->transact_error( "test_table.db", "Simulated fatal error" );
    my $res = $adb->transact_end();

    is( $res->{status}, 'rollback', "Transaction rolled back due to transact_error" );
    ok( @{ $res->{errors} } > 0, "Errors captured in rollback response" );
    is( $res->{errors}->[0]->{context}, "test_table.db", "Correct error context captured" );
};

# ---------------------------------------------------------------------------
subtest '5. _eval_plural_rule hardening' => sub {
    plan tests => 4;

    ok( $adb->_eval_plural_rule("n == 1", 1), "n == 1 true for 1" );
    ok( !$adb->_eval_plural_rule("n == 1", 5), "n == 1 false for 5" );
    ok( !$adb->_eval_plural_rule("n / 0 == 1", 2), "Division by zero returns 0 safely without dying" );
    ok( !$adb->_eval_plural_rule("system('dir')", 1), "Code injection strictly blocked by whitelist" );
};

done_testing();
