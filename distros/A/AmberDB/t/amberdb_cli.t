#!/usr/bin/perl

# t/amberdb_cli.t - Comprehensive tests for bin/amberdb_cli.pl

use 5.016000;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Basename qw(dirname);
use Cwd qw(abs_path getcwd);
use JSON::PP qw(decode_json encode_json);

my $perl_bin = $^X;
my $script_dir = dirname(abs_path(__FILE__));
my $cli_path   = abs_path(File::Spec->catfile($script_dir, "..", "bin", "amberdb_cli.pl"));

ok(-f $cli_path, "amberdb_cli.pl exists at $cli_path");

my $test_tmpdir = tempdir(CLEANUP => 1);
my $test_dbdir  = File::Spec->catdir($test_tmpdir, "dbstore");
mkdir $test_dbdir unless -d $test_dbdir;
$test_dbdir = eval { abs_path($test_dbdir) } // $test_dbdir;

sub norm_path {
    my ($p) = @_;
    return '' unless defined $p;
    $p = eval { abs_path($p) } // $p;
    $p = File::Spec->canonpath($p);
    $p =~ s{\\}{/}g;
    $p =~ s{/+$}{};
    return lc($p);
}

# ---------------------------------------------------------------------------
subtest '1. Help screen & default table overview' => sub {
    plan tests => 3;

    my $out_help = `"$perl_bin" -Ilib "$cli_path" help`;
    like($out_help, qr/AmberDB CLI/, "Help screen shows CLI title");
    like($out_help, qr/Kullanım:/, "Help screen shows usage section");

    my $out_list = `"$perl_bin" -Ilib "$cli_path" path-dbase_dir="$test_dbdir" format=json`;
    my $data = eval { decode_json($out_list) };
    is(ref $data, 'HASH', "Default action outputs valid JSON with format=json");
};

# ---------------------------------------------------------------------------
subtest '2. Connect lifecycle & token generation' => sub {
    plan tests => 5;

    my $out_conn = `"$perl_bin" -Ilib "$cli_path" connect path-dbase_dir="$test_dbdir" cfg-language=tr format=json`;
    my $conn = eval { decode_json($out_conn) };
    is(ref $conn, 'HASH', "Connect returned valid JSON");
    is($conn->{status}, 'connected', "Status is connected");
    ok(defined $conn->{token} && $conn->{token} =~ /^\d{4}$/, "4-digit token generated: $conn->{token}");

    my $token = $conn->{token};

    # Verify session file exists
    my $sess_file = $conn->{session_file} || File::Spec->catfile($test_dbdir, "session", "cli_$token");
    ok(-f $sess_file, "Session file exists on disk: $sess_file");

    # Read session file content
    open my $fh, '<', $sess_file;
    local $/;
    my $sess_json = <$fh>;
    close $fh;
    my $sess_data = decode_json($sess_json);
    is($sess_data->{cfg}->{language}, 'tr', "Config language 'tr' saved in session");
};

# ---------------------------------------------------------------------------
subtest '3. Dash tolerance & global config update' => sub {
    plan tests => 4;

    # Connect to get token
    my $out_conn = `"$perl_bin" -Ilib "$cli_path" connect path-dbase_dir="$test_dbdir" format=json`;
    my $conn = eval { decode_json($out_conn) };
    my $token = $conn ? $conn->{token} : '';

    # Update with --cfg-no_write=1 (double dash)
    my $upd1 = `"$perl_bin" -Ilib "$cli_path" --token=$token --cfg-no_write=1 format=json 2>&1`;
    my $data1 = eval { decode_json($upd1) };
    is(eval { $data1->{cfg}->{no_write} }, 1, "Double dash --cfg-no_write=1 updated") or diag("upd1 output: $upd1");

    # Update with -cfg-no_write=0 (single dash)
    my $upd2 = `"$perl_bin" -Ilib "$cli_path" -token=$token -cfg-no_write=0 format=json 2>&1`;
    my $data2 = eval { decode_json($upd2) };
    is(eval { $data2->{cfg}->{no_write} }, 0, "Single dash -cfg-no_write=0 updated") or diag("upd2 output: $upd2");

    # Update with cfg-no_write=1 (no dash)
    my $upd3 = `"$perl_bin" -Ilib "$cli_path" token=$token cfg-no_write=1 format=json 2>&1`;
    my $data3 = eval { decode_json($upd3) };
    is(eval { $data3->{cfg}->{no_write} }, 1, "No dash cfg-no_write=1 updated") or diag("upd3 output: $upd3");

    # Clean disconnect
    my $disc = `"$perl_bin" -Ilib "$cli_path" token=$token disconnect format=json 2>&1`;
    my $ddata = eval { decode_json($disc) };
    is(eval { $ddata->{status} }, 'disconnected', "Disconnected successfully") or diag("disc output: $disc");
};

# ---------------------------------------------------------------------------
subtest '4. Table attributes with deep nested parsing and session persistence' => sub {
    plan tests => 6;

    my $out_conn = `"$perl_bin" -Ilib "$cli_path" connect path-dbase_dir="$test_dbdir" format=json`;
    my $token = decode_json($out_conn)->{token};

    # table_attr with deep keys: blocks-1-rdbm and search_block=[1]
    my $cmd = qq{"$perl_bin" -Ilib "$cli_path" token=$token action=table_attr table=cli_test_prod search_block=[1] keep_deleted=1 blocks-1-rdbm=cat,1 format=json};
    my $out_attr = `$cmd`;
    my $attr_data = decode_json($out_attr);
    is($attr_data->{status}, 'ok', "table_attr executed successfully");
    is($attr_data->{attributes}->{keep_deleted}, 1, "keep_deleted attribute set to 1");
    is_deeply($attr_data->{attributes}->{search_block}, [1], "search_block parsed as JSON array [1]");
    is(ref $attr_data->{attributes}->{blocks}->{1}->{rdbm}, 'HASH', "rdbm normalized to HASH");
    is($attr_data->{attributes}->{blocks}->{1}->{rdbm}->{table}, 'cat', "Deep nested blocks-1-rdbm table parsed");

    # Disconnect
    `"$perl_bin" -Ilib "$cli_path" token=$token disconnect`;
    my $sess_file = File::Spec->catfile($test_dbdir, "session", "cli_$token");
    ok(!-f $sess_file, "Session file deleted on disconnect");
};

# ---------------------------------------------------------------------------
subtest '5. CRUD operations & no_write protection' => sub {
    plan tests => 8;

    my $out_conn = `"$perl_bin" -Ilib "$cli_path" connect path-dbase_dir="$test_dbdir" cfg-no_write=1 format=json`;
    my $token = decode_json($out_conn)->{token};

    # Attempt insert when no_write is 1
    my $ins_blocked = `"$perl_bin" -Ilib "$cli_path" token=$token action=insert_id table=cli_items id=1 data='["Book",15]' 2>&1`;
    like($ins_blocked, qr/no_write aktif/, "insert_id blocked when no_write=1");

    # Enable writes in session
    `"$perl_bin" -Ilib "$cli_path" token=$token cfg-no_write=0`;

    # Insert record
    my $ins_ok = `"$perl_bin" -Ilib "$cli_path" token=$token action=insert_id table=cli_items id=1 data='["Book",15]' format=json`;
    my $ins_data = eval { decode_json($ins_ok) };
    is($ins_data->{status}, 'ok', "insert_id succeeded after enabling writes");
    is($ins_data->{id}, 1, "Inserted record ID is 1");

    # Read record
    my $read_ok = `"$perl_bin" -Ilib "$cli_path" token=$token action=read_id table=cli_items id=1 format=json`;
    my $read_data = eval { decode_json($read_ok) };
    is(ref $read_data, 'ARRAY', "read_id returned array of fields");
    is($read_data->[1], "Book", "read_id field 1 is Book");

    # Count table
    my $cnt_ok = `"$perl_bin" -Ilib "$cli_path" token=$token action=table_count table=cli_items format=json`;
    my $cnt_data = eval { decode_json($cnt_ok) };
    is($cnt_data->{count}, 1, "table_count is 1");

    # Read all
    my $all_ok = `"$perl_bin" -Ilib "$cli_path" token=$token action=read_all table=cli_items format=json`;
    my $all_data = eval { decode_json($all_ok) };
    is($all_data->{count}, 1, "read_all count is 1");

    # Delete record
    my $del_ok = `"$perl_bin" -Ilib "$cli_path" token=$token action=delete_id table=cli_items id=1 format=json`;
    my $del_data = eval { decode_json($del_ok) };
    is($del_data->{status}, 'ok', "delete_id succeeded");

    `"$perl_bin" -Ilib "$cli_path" token=$token disconnect`;
};

# ---------------------------------------------------------------------------
subtest '6. Tools operations: reindex, check, vacuum' => sub {
    plan tests => 3;

    my $out_conn = `"$perl_bin" -Ilib "$cli_path" connect path-dbase_dir="$test_dbdir" format=json`;
    my $token = decode_json($out_conn)->{token};

    # Insert a dummy record
    `"$perl_bin" -Ilib "$cli_path" token=$token action=insert_id table=cli_tools_test id=1 data='["Item A",100]'`;

    # Reindex
    my $reindex_out = `"$perl_bin" -Ilib "$cli_path" token=$token action=reindex table=cli_tools_test format=json`;
    my $reindex_data = eval { decode_json($reindex_out) };
    is($reindex_data->{status}, 'ok', "Tools reindex succeeded");

    # Check
    my $check_out = `"$perl_bin" -Ilib "$cli_path" token=$token action=check table=cli_tools_test format=json`;
    my $check_data = eval { decode_json($check_out) };
    is($check_data->{status}, 'ok', "Tools check succeeded");

    # Vacuum
    my $vac_out = `"$perl_bin" -Ilib "$cli_path" token=$token action=vacuum table=cli_tools_test format=json`;
    my $vac_data = eval { decode_json($vac_out) };
    is($vac_data->{status}, 'ok', "Tools vacuum succeeded");

    `"$perl_bin" -Ilib "$cli_path" token=$token disconnect`;
};

# ---------------------------------------------------------------------------
subtest '7. Natural positional signatures & trailing format' => sub {
    plan tests => 9;

    my $out_conn = `"$perl_bin" -Ilib "$cli_path" connect path-dbase_dir="$test_dbdir" format=json`;
    my $token = decode_json($out_conn)->{token};

    # Insert using natural syntax: <token> insert <table> <id> data='...'
    my $ins_cmd = `"$perl_bin" -Ilib "$cli_path" $token insert natural_items 1 data='["Book",25]' json`;
    my $ins = eval { decode_json($ins_cmd) };
    is($ins->{status}, 'ok', "Natural insert succeeded with trailing json format");

    # Read using natural syntax: <token> read <table> <id> json
    my $read_cmd = `"$perl_bin" -Ilib "$cli_path" $token read natural_items 1 json`;
    my $read = eval { decode_json($read_cmd) };
    is(ref $read, 'ARRAY', "Natural read returned record array");
    is($read->[1], "Book", "Natural read record value matches");

    # Read all using natural syntax: <token> read <table> all 0 10 json
    my $all_cmd = `"$perl_bin" -Ilib "$cli_path" $token read natural_items all 0 10 json`;
    my $all = eval { decode_json($all_cmd) };
    is($all->{count}, 1, "Natural read all returned count 1");

    # Field fetch using natural syntax: <token> fetch <table> <block> <value> json
    my $fetch_cmd = `"$perl_bin" -Ilib "$cli_path" $token fetch natural_items 1 "Book" json`;
    my $fetch = eval { decode_json($fetch_cmd) };
    is($fetch->{count}, 1, "Natural fetch returned count 1");

    # Search using natural syntax with positional offset & limit: <token> search <table> "query" 0 10 keys_only=1 json
    my $search_pos_cmd = `"$perl_bin" -Ilib "$cli_path" $token search natural_items "Book" 0 10 keys_only=1 json`;
    my $search_pos = eval { decode_json($search_pos_cmd) };
    ok(defined $search_pos->{records}, "Natural search with positional 0 10 returned records");
    cmp_ok(scalar(@{ $search_pos->{records} }), '<=', 10, "Search sliced with positional limit");

    # Field fetch using natural syntax with positional offset & limit: <token> fetch <table> <block> <value> 0 10 json
    my $fetch_pos_cmd = `"$perl_bin" -Ilib "$cli_path" $token fetch natural_items 1 "Book" 0 10 json`;
    my $fetch_pos = eval { decode_json($fetch_pos_cmd) };
    is($fetch_pos->{count}, 1, "Natural fetch with positional 0 10 returned count 1");

    # Info schema table
    my $info_cmd = `"$perl_bin" -Ilib "$cli_path" $token info natural_items json`;
    my $info = eval { decode_json($info_cmd) };
    is(ref $info, 'HASH', "Info returned hash schema");

    `"$perl_bin" -Ilib "$cli_path" $token disconnect`;
};

# ---------------------------------------------------------------------------
subtest '8. Session commands: config, path, attr & session error guard' => sub {
    plan tests => 6;

    # Attr without session must fail
    my $err_attr = `"$perl_bin" -Ilib "$cli_path" attr no_sess_tbl search_block=[1] 2>&1`;
    like($err_attr, qr/requires an active session/, "attr without session fails with error");

    # Connect to start session
    my $out_conn = `"$perl_bin" -Ilib "$cli_path" connect path-dbase_dir="$test_dbdir" format=json`;
    my $token = decode_json($out_conn)->{token};

    # Update config via session command
    my $cfg_cmd = `"$perl_bin" -Ilib "$cli_path" $token config no_write=1 json`;
    my $cfg_res = eval { decode_json($cfg_cmd) };
    is($cfg_res->{status}, 'ok', "config updated via session command");
    is($cfg_res->{cfg}->{no_write}, 1, "no_write set to 1");

    # Update path via session command
    my $path_cmd = `"$perl_bin" -Ilib "$cli_path" $token path dbase_dir="$test_dbdir" json`;
    my $path_res = eval { decode_json($path_cmd) };
    is($path_res->{status}, 'ok', "path updated via session command");

    # Set attr via session command
    my $attr_cmd = `"$perl_bin" -Ilib "$cli_path" $token attr sess_prod search_block=[1] keep_deleted=1 json`;
    my $attr_res = eval { decode_json($attr_cmd) };
    is($attr_res->{status}, 'ok', "attr updated via session command");
    is($attr_res->{attributes}->{keep_deleted}, 1, "keep_deleted stored in session attr");

    `"$perl_bin" -Ilib "$cli_path" $token disconnect`;
};

# ---------------------------------------------------------------------------
subtest '9. Direct (stateless) execution without token' => sub {
    plan tests => 2;

    # Direct execution using --db flag (no connect, no token)
    my $ins_direct = `"$perl_bin" -Ilib "$cli_path" --db="$test_dbdir" insert direct_tbl 1 data='["Widget",50]' json`;
    my $ins_res = eval { decode_json($ins_direct) };
    is($ins_res->{status}, 'ok', "Direct insert without session succeeded");

    my $read_direct = `"$perl_bin" -Ilib "$cli_path" --db="$test_dbdir" read direct_tbl 1 json`;
    my $read_res = eval { decode_json($read_direct) };
    is($read_res->[1], "Widget", "Direct read without session succeeded");
};

# ---------------------------------------------------------------------------
subtest '10. Execution elapsed time parameter (time, time=1, --time)' => sub {
    plan tests => 8;

    # 1. format=json time=1
    my $out_time1 = `"$perl_bin" -Ilib "$cli_path" --db="$test_dbdir" read direct_tbl 1 format=json time=1`;
    my ($json_part1, $time_part1) = split /\r?\n(?=\[Time:)/, $out_time1;
    my $data1 = eval { decode_json($json_part1) };
    is($data1->[1], "Widget", "Valid JSON output with time=1");
    like($time_part1 // '', qr/^\[Time: \d+\.\d+s \(\d+\.\d+ ms\)\]/, "Time line printed with format=json time=1");

    # 2. Bare trailing keywords: json time
    my $out_time2 = `"$perl_bin" -Ilib "$cli_path" --db="$test_dbdir" read direct_tbl 1 json time`;
    my ($json_part2, $time_part2) = split /\r?\n(?=\[Time:)/, $out_time2;
    my $data2 = eval { decode_json($json_part2) };
    is($data2->[1], "Widget", "Valid JSON output with trailing 'json time'");
    like($time_part2 // '', qr/^\[Time: \d+\.\d+s \(\d+\.\d+ ms\)\]/, "Time line printed with 'json time'");

    # 3. Bare trailing keywords: time json (reverse order)
    my $out_time3 = `"$perl_bin" -Ilib "$cli_path" --db="$test_dbdir" read direct_tbl 1 time json`;
    my ($json_part3, $time_part3) = split /\r?\n(?=\[Time:)/, $out_time3;
    my $data3 = eval { decode_json($json_part3) };
    is($data3->[1], "Widget", "Valid JSON output with trailing 'time json'");
    like($time_part3 // '', qr/^\[Time: \d+\.\d+s \(\d+\.\d+ ms\)\]/, "Time line printed with 'time json'");

    # 4. --time flag
    my $out_time4 = `"$perl_bin" -Ilib "$cli_path" --db="$test_dbdir" --time read direct_tbl 1 json`;
    like($out_time4, qr/\[Time: \d+\.\d+s \(\d+\.\d+ ms\)\]/, "Time line printed with --time flag");

    # 5. Output without time has no [Time: ...] line
    my $out_notime = `"$perl_bin" -Ilib "$cli_path" --db="$test_dbdir" read direct_tbl 1 json`;
    unlike($out_notime, qr/\[Time:/, "No time line printed when time option is omitted");
};

# ---------------------------------------------------------------------------
subtest '11. Positional connect database directory' => sub {
    plan tests => 6;

    # 1. Positional connect to custom path
    my $out_pos = `"$perl_bin" -Ilib "$cli_path" connect "$test_dbdir" format=json`;
    my $conn_pos = eval { decode_json($out_pos) };
    is($conn_pos->{status}, 'connected', "Positional connect to path succeeded");
    my $tok_pos = $conn_pos->{token};
    ok(defined $tok_pos && $tok_pos =~ /^\d{4}$/, "Positional connect token generated: $tok_pos");
    is(norm_path($conn_pos->{path}->{dbase_dir}), norm_path($test_dbdir), "Connected data dir matches positional path");

    my $disc_pos = `"$perl_bin" -Ilib "$cli_path" token=$tok_pos disconnect format=json`;
    my $dd_pos = eval { decode_json($disc_pos) };
    is($dd_pos->{status}, 'disconnected', "Positional connect disconnected cleanly");

    # 2. Positional connect with 'dbstore'
    my $out_dbstore = `"$perl_bin" -Ilib "$cli_path" connect dbstore format=json`;
    my $conn_dbstore = eval { decode_json($out_dbstore) };
    is($conn_dbstore->{status}, 'connected', "Connect dbstore succeeded");
    my $tok_db = $conn_dbstore->{token};

    my $disc_db = `"$perl_bin" -Ilib "$cli_path" token=$tok_db disconnect format=json`;
    my $dd_db = eval { decode_json($disc_db) };
    is($dd_db->{status}, 'disconnected', "Connect dbstore disconnected cleanly");
};

done_testing();

