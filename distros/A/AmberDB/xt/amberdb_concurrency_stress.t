#!/usr/bin/perl

# xt/amberdb_concurrency_stress.t - Author & Release Multi-process Concurrency & Stress Tests
# Supports Linux, Unix, macOS (POSIX fork+exec) and Windows (Native MSWin32 spawn / MSYS2 fork+exec)

use 5.016000;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Time::HiRes qw(sleep usleep);

use lib 'lib';
use AmberDB;

my $IS_MSWIN32 = ( $^O eq 'MSWin32' ) ? 1 : 0;

# Helper to spawn a single worker process across platforms
sub spawn_process {
    my ( $script_path, @args ) = @_;

    if ($IS_MSWIN32) {
        my $pid = system( 1, $^X, '-Ilib', $script_path, @args );
        die "Failed to spawn worker ($script_path): $!" if !defined $pid || $pid < 0;
        return $pid;
    }
    else {
        my $pid = fork();
        die "Failed to fork worker ($script_path): $!" unless defined $pid;
        if ( $pid == 0 ) {
            exec( $^X, '-Ilib', $script_path, @args );
            exit(1);
        }
        return $pid;
    }
}

# Helper to spawn multiple identical worker processes cleanly
sub run_workers {
    my ( $tmpdir, $script_filename, $script_code, $num_workers, @extra_args ) = @_;

    my $script_path = "$tmpdir/$script_filename";
    open my $fh, ">", $script_path or die "Cannot write worker script ($script_path): $!";
    print $fh $script_code;
    close $fh;

    my @pids;
    for my $w ( 1 .. $num_workers ) {
        my $pid = spawn_process( $script_path, $w, @extra_args );
        push @pids, $pid;
    }

    my $all_clean = 1;
    for my $pid (@pids) {
        waitpid( $pid, 0 );
        $all_clean = 0 if $? != 0;
    }
    return $all_clean;
}

# Schema template for concurrent catalog tables
sub make_schema {
    my ($name) = @_;
    return {
        name         => $name || "Concurrent Products",
        record_index => 1,
        match_block  => [ 1, 2 ],
        search_block => [3],
        facet_block  => [ 1, 2 ],
        use_facet    => 1,
        slug_block   => [3],
        blocks       => [
            { id => "id",       name => "ID",       type => "auto_id" },
            { id => "cat_id",   name => "Kategori", type => "text" },
            { id => "brand_id", name => "Marka",    type => "text" },
            { id => "title",    name => "Başlık",   type => "text" },
            { id => "stock",    name => "Stok",     type => "text" },
            { id => "price",    name => "Fiyat",    type => "text" },
        ],
    };
}

# ---------------------------------------------------------------------------
subtest '1. Concurrent Multi-Process Inserts (Parallel Writers)' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    my $tbl_name = "catalog_writers";
    my $table_schema = make_schema("Concurrent Writers Table");

    my $num_workers    = 4;
    my $recs_per_proc  = 15;
    my $expected_total = $num_workers * $recs_per_proc;

    my $worker_code = <<'PERL';
use strict;
use warnings;
use lib 'lib';
use AmberDB;
use Time::HiRes qw(usleep);

my ($w, $tmpdir, $tbl_name, $recs_per_proc) = @ARGV;
my $db = AmberDB->new( path => { dbase_dir => $tmpdir }, cfg => { simple => 0 } );
$db->{_table}->{$tbl_name} = {
    name         => "Concurrent Writers Table",
    record_index => 1,
    match_block  => [ 1, 2 ],
    search_block => [3],
    facet_block  => [ 1, 2 ],
    use_facet    => 1,
    slug_block   => [3],
};

for my $i ( 1 .. $recs_per_proc ) {
    my $rid      = $w * 1000 + $i;
    my $cat_id   = ( $i % 4 ) + 1;
    my $brand_id = ( $i % 3 ) + 1;
    my $title    = "Worker_${w}_Product_${i}";
    my $stock    = 10;
    my $price    = 100 + $i;

    my $id = $db->insert_id( $tbl_name, $rid, $cat_id, $brand_id, $title, $stock, $price );
    unless (defined $id) {
        usleep(5000);
        $id = $db->insert_id( $tbl_name, $rid, $cat_id, $brand_id, $title, $stock, $price );
    }
    usleep(1000);
}
$db->close_all();
exit(0);
PERL

    my $clean = run_workers( $tmpdir, "worker_writers.pl", $worker_code, $num_workers, $tmpdir, $tbl_name, $recs_per_proc );
    ok( $clean, "All $num_workers writer processes completed with exit code 0" );

    # Parent inspects final database consistency
    my $parent_db = AmberDB->new( path => { dbase_dir => $tmpdir }, cfg => { simple => 0 } );
    $parent_db->{_table}->{$tbl_name} = $table_schema;

    my $total_count = $parent_db->table_count($tbl_name);
    is( $total_count, $expected_total, "Table count matches exact sum of all concurrent writes ($expected_total)" );

    my @all_keys = $parent_db->table_keys($tbl_name);
    is( scalar(@all_keys), $expected_total, "table_keys array contains exactly $expected_total unique IDs" );

    # Verify no duplicate IDs
    my %seen_ids;
    for my $k (@all_keys) { $seen_ids{$k}++; }
    is( scalar( keys %seen_ids ), $expected_total, "All generated IDs are 100% unique (no ID collisions)" );

    # Verify index integrity (.inx contains all keys)
    my $inx_file = "$tmpdir/table/${tbl_name}.inx";
    my ( undef, @inx_keys ) = $parent_db->index_get( $inx_file, "keys" );
    is( scalar(@inx_keys), $expected_total, "Primary binary index (.inx) contains exactly $expected_total keys" );

    # Verify match index (Category 1)
    my @cat1_recs = $parent_db->field_fetch( $tbl_name, 1, "1" );
    ok( scalar(@cat1_recs) > 0, "Match index .fld is consistent and returned " . scalar(@cat1_recs) . " Category 1 records" );
};

# ---------------------------------------------------------------------------
subtest '2. Concurrent Read & Write Interleaving' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    my $tbl_name = "catalog_interleave";
    my $table_schema = make_schema("Interleave Table");

    my $num_writers = 2;
    my $num_readers = 2;
    my $writes_each = 10;

    my $writer_code = <<'PERL';
use strict;
use warnings;
use lib 'lib';
use AmberDB;
use Time::HiRes qw(usleep);

my ($w, $tmpdir, $tbl_name, $writes_each) = @ARGV;
my $db = AmberDB->new( path => { dbase_dir => $tmpdir }, cfg => { simple => 0 } );
$db->{_table}->{$tbl_name} = {
    name         => "Interleave Table",
    record_index => 1,
    match_block  => [ 1, 2 ],
    search_block => [3],
};

for my $i ( 1 .. $writes_each ) {
    my $rid   = $w * 1000 + $i;
    my $title = "Interleaved_${w}_${i}";
    $db->insert_id( $tbl_name, $rid, "1", "1", $title, "5", "50" );
    usleep(1000);
}
$db->close_all();
exit(0);
PERL

    my $reader_code = <<'PERL';
use strict;
use warnings;
use lib 'lib';
use AmberDB;
use Time::HiRes qw(usleep);

my ($r, $tmpdir, $tbl_name) = @ARGV;
my $read_success = 1;
for ( 1 .. 8 ) {
    my $db = AmberDB->new( path => { dbase_dir => $tmpdir }, cfg => { simple => 0 } );
    $db->{_table}->{$tbl_name} = {
        name         => "Interleave Table",
        record_index => 1,
        match_block  => [ 1, 2 ],
        search_block => [3],
    };
    eval {
        my ($cnt, @recs) = $db->field_fetch( $tbl_name, 1, "1" );
        my @all = $db->read_all($tbl_name, 0, 5);
    };
    if ($@) {
        $read_success = 0;
    }
    $db->close_all();
    usleep(1000);
}
exit( $read_success ? 0 : 1 );
PERL

    # Write scripts to disk
    my $writer_script = "$tmpdir/worker_interleave_writer.pl";
    open my $wfh, ">", $writer_script or die $!;
    print $wfh $writer_code;
    close $wfh;

    my $reader_script = "$tmpdir/worker_interleave_reader.pl";
    open my $rfh, ">", $reader_script or die $!;
    print $rfh $reader_code;
    close $rfh;

    my @pids;
    for my $w ( 1 .. $num_writers ) {
        my $pid = spawn_process( $writer_script, $w, $tmpdir, $tbl_name, $writes_each );
        push @pids, $pid;
    }

    for my $r ( 1 .. $num_readers ) {
        my $pid = spawn_process( $reader_script, $r, $tmpdir, $tbl_name );
        push @pids, $pid;
    }

    my $all_clean = 1;
    for my $pid (@pids) {
        waitpid( $pid, 0 );
        $all_clean = 0 if $? != 0;
    }
    ok( $all_clean, "Writers and readers concurrently executed without crashing or deadlocking" );
};

# ---------------------------------------------------------------------------
subtest '3. Concurrent Independent Transactions & Crash Recovery' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    my $tbl_name = "catalog_transact";
    my $table_schema = make_schema("Transaction Table", "num");

    my $txn_worker_code = <<'PERL';
use strict;
use warnings;
use lib 'lib';
use AmberDB;

my ($action, $tmpdir, $tbl_name) = @ARGV;
my $db = AmberDB->new( path => { dbase_dir => $tmpdir }, cfg => { simple => 0 } );
$db->{_table}->{$tbl_name} = {
    name         => "Transaction Table",
    record_index => 1,
    match_block  => [ 1, 2 ],
    search_block => [3],
};

if ($action eq 'commit') {
    $db->transact_start();
    $db->insert_id( $tbl_name, undef, "2", "2", "Committed_Book_A", "10", "150" );
    $db->insert_id( $tbl_name, undef, "2", "2", "Committed_Book_B", "10", "150" );
    my $res = $db->transact_end();
    my $ok = ( $res && $res->{status} eq 'commit' ) ? 0 : 1;
    $db->close_all();
    exit($ok);
}
elsif ($action eq 'rollback') {
    $db->transact_start();
    my $rid = $db->insert_id( $tbl_name, undef, "2", "2", "RolledBack_Book_C", "10", "150" );
    my $res = $db->transact_rollback();
    my $ok = ( $res && $res->{status} eq 'rollback' && !$db->exist_id( $tbl_name, $rid ) ) ? 0 : 1;
    $db->close_all();
    exit($ok);
}
elsif ($action eq 'crash') {
    $db->transact_start();
    $db->insert_id( $tbl_name, undef, "2", "2", "Crashed_Book_D", "10", "150" );
    # Abruptly exit without commit or rollback, leaving active .txn file
    exit(42);
}
PERL

    my $txn_script = "$tmpdir/worker_txn.pl";
    open my $fh, ">", $txn_script or die $!;
    print $fh $txn_worker_code;
    close $fh;

    # Worker A: Commit
    my $pid_commit = spawn_process( $txn_script, 'commit', $tmpdir, $tbl_name );
    waitpid( $pid_commit, 0 );
    is( $?, 0, "Worker A transaction committed cleanly" );

    my $parent_db = AmberDB->new( path => { dbase_dir => $tmpdir }, cfg => { simple => 0 } );
    $parent_db->{_table}->{$tbl_name} = $table_schema;

    # Verify committed records exist
    ok( $parent_db->exist_id( $tbl_name, 1 ), "Worker A record 1 committed successfully" );
    ok( $parent_db->exist_id( $tbl_name, 2 ), "Worker A record 2 committed successfully" );

    # Worker B: Rollback
    my $pid_rb = spawn_process( $txn_script, 'rollback', $tmpdir, $tbl_name );
    waitpid( $pid_rb, 0 );
    is( $?, 0, "Worker B transaction rolled back cleanly" );

    # Worker C: Abrupt Crash
    my $pid_crash = spawn_process( $txn_script, 'crash', $tmpdir, $tbl_name );
    waitpid( $pid_crash, 0 );

    # Recover orphans left by crashed worker C
    my $recovered = $parent_db->transact_recover();
    ok( $recovered, "transact_recover executed cleanly" );

    # Verify crashed record was undone and table count is exactly 2
    my $total = $parent_db->table_count($tbl_name);
    is( $total, 2, "Table count is exactly 2 (crashed and rolled back records removed)" );
};

# ---------------------------------------------------------------------------
subtest '4. Concurrent URL Slug Collisions (Duplicate Title Stress)' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    my $tbl_name = "catalog_slug";
    my $table_schema = make_schema("Slug Table");

    my $num_workers = 3;
    my $recs_each   = 8;
    my $total_dups  = $num_workers * $recs_each;

    my $slug_worker_code = <<'PERL';
use strict;
use warnings;
use lib 'lib';
use AmberDB;
use Time::HiRes qw(usleep);

my ($w, $tmpdir, $tbl_name, $recs_each) = @ARGV;
my $db = AmberDB->new( path => { dbase_dir => $tmpdir }, cfg => { simple => 0 } );
$db->{_table}->{$tbl_name} = {
    name         => "Slug Table",
    record_index => 1,
    match_block  => [ 1, 2 ],
    search_block => [3],
    slug_block   => [3],
};

for my $i ( 1 .. $recs_each ) {
    my $rid = $w * 1000 + $i;
    # All workers write with the EXACT same title simultaneously under distinct cat 99
    my $id = $db->insert_id( $tbl_name, $rid, "99", "3", "Nutuk Mustafa Kemal Ataturk", "10", "120" );
    unless (defined $id) {
        usleep(5000);
        $id = $db->insert_id( $tbl_name, $rid, "99", "3", "Nutuk Mustafa Kemal Ataturk", "10", "120" );
    }
    usleep(1000);
}
$db->close_all();
exit(0);
PERL

    my $clean = run_workers( $tmpdir, "worker_slug.pl", $slug_worker_code, $num_workers, $tmpdir, $tbl_name, $recs_each );
    ok( $clean, "All $num_workers slug worker processes finished cleanly" );

    my $parent_db = AmberDB->new( path => { dbase_dir => $tmpdir }, cfg => { simple => 0 } );
    $parent_db->{_table}->{$tbl_name} = $table_schema;

    # Fetch all records and verify slug map bijection
    my @all_prods = $parent_db->field_fetch( $tbl_name, 1, "99" );
    is( scalar(@all_prods), $total_dups, "Total duplicate records added is exact ($total_dups)" );

    my %seen_slugs;
    my $all_bijective = 1;

    for my $prod (@all_prods) {
        my $rid = $prod->[0];
        my $slug_map = $parent_db->get_slug( $tbl_name, 0, $rid );
        my $slug = $slug_map->{$rid};

        if ( !defined $slug || $seen_slugs{$slug} ) {
            $all_bijective = 0;
            last;
        }
        $seen_slugs{$slug} = $rid;

        # Reverse check: slug -> rid
        my $rev_map = $parent_db->get_slug( $tbl_name, 1, $slug );
        if ( !defined $rev_map->{$slug} || $rev_map->{$slug} ne $rid ) {
            $all_bijective = 0;
            last;
        }
    }

    ok( $all_bijective, "All $total_dups concurrent duplicate titles received distinct, 100% bidirectional slugs" );
};

# ---------------------------------------------------------------------------
subtest '5. High-Concurrency Inventory Update with Record Locks (flock_open)' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    my $tbl_name = "catalog_lock";
    my $table_schema = make_schema("Lock Table", "num");
    my $shared_id = 9999;

    my $parent_db = AmberDB->new( path => { dbase_dir => $tmpdir }, cfg => { simple => 0 } );
    $parent_db->{_table}->{$tbl_name} = $table_schema;
    $parent_db->insert_id( $tbl_name, $shared_id, "5", "5", "Limited Edition Book", 50, 500 );

    my $workers = 2;
    my $decrements_each = 10; # Total 20 decrements -> remaining stock must be 50 - 20 = 30

    my $lock_worker_code = <<'PERL';
use strict;
use warnings;
use lib 'lib';
use AmberDB;
use Time::HiRes qw(usleep);

my ($w, $tmpdir, $tbl_name, $shared_id, $decrements_each) = @ARGV;
my $db = AmberDB->new( path => { dbase_dir => $tmpdir }, cfg => { simple => 0 } );
$db->{_table}->{$tbl_name} = {
    name         => "Lock Table",
    record_index => 1,
    match_block  => [ 1, 2 ],
    search_block => [3],
};

for ( 1 .. $decrements_each ) {
    if ( $db->flock_open( $tbl_name, "write", $shared_id ) ) {
        my @rec = $db->read_id( $tbl_name, $shared_id );
        if (@rec) {
            $rec[4] -= 1; # Stock decrement
            $db->modify_id( $tbl_name, $shared_id, @rec[ 1 .. $#rec ] );
        }
        $db->flock_close( $tbl_name, $shared_id );
    }
    usleep(1000);
}
$db->close_all();
exit(0);
PERL

    my $clean = run_workers( $tmpdir, "worker_lock.pl", $lock_worker_code, $workers, $tmpdir, $tbl_name, $shared_id, $decrements_each );
    ok( $clean, "All $workers lock worker processes finished cleanly" );

    my @final = $parent_db->read_id( $tbl_name, $shared_id );
    is( $final[4], 30, "Shared record inventory correctly decremented from 50 to 30 without lost updates" );
};

done_testing();
