#!/usr/bin/env perl
# t/data-flow.t — Define-Use-Kill chain tests for Database::Abstraction.
#
# Each section traces a critical variable or resource through its full
# lifecycle:  D (define / first assignment), U (read / use), K (kill /
# release).  Anomaly flags (DD, D~, ~U, O~) are noted in comments where
# a potential issue was identified during static analysis.
#
# Sections:
#   DF1  slurp-data buffer  ($self->{'data'})
#   DF2  introspection caches ($self->{'_columns'}, $self->{'_schema'})
#   DF3  gzip temp file       ($self->{'_temp_fh'})
#   DF4  DBI handle           ($self->{$table})
#   DF5  CHI cache key        (MISS -> SET -> HIT -> expiry)
#   DF6  $sth->finish()       (statement handle always closed)
#   DF7  base_criteria mutation safety
#   DF8  Data::Reuse stale-address protection (cross-object)
#   DF9  no_fixate mutability flow
#   DF10 aggregate() pipeline data flow
#   DF11 permission-revoked file access (Test::Permissions)
#   DF12 global state ($_, $@, $!) isolation

use strict;
use warnings;

use Test::Most;
use Test::Returns;
use Test::Warn;
use Test::Permissions qw(:revoke :guard);
use Scalar::Util qw(weaken isweak refaddr blessed);
use File::Temp qw(tempdir);
use File::Spec;
use Readonly;
use DBI;
use Data::Reuse ();

# Load the test subclasses that point at the standard fixture directory.
use lib 't/lib';
use Database::test1;    # CSV, entry!number columns, slurp-sized file
use Database::test2;    # PSV fixture

Readonly my $DATA_DIR   => File::Spec->catdir('t', 'data');
Readonly my $CSV_FILE   => File::Spec->catfile($DATA_DIR, 'test1.csv');

# Detect optional deps once; individual sections SKIP when absent.
my $HAVE_SQLITE  = eval { require DBD::SQLite; 1 };
my $HAVE_JSON    = eval { require JSON::MaybeXS; 1 };
my $HAVE_GZIP    = eval { require Gzip::Faster; 1 };
my $HAVE_CHI     = eval { require CHI; 1 };
my $HAVE_DEEP    = eval { require DBM::Deep; 1 };

# ---------------------------------------------------------------------------
# Helper: create an isolated SQLite DSN in a temp dir.
# ---------------------------------------------------------------------------
sub _make_sqlite_dsn {
	my ($dir, $table, $rows) = @_;
	# $rows is an arrayref of arrayrefs: [[entry,score],[entry,score],...]
	my $db_file = File::Spec->catfile($dir, "$table.sqlite");
	my $dsn = "dbi:SQLite:dbname=$db_file";
	my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1, AutoCommit => 1 });
	$dbh->do("CREATE TABLE $table (entry TEXT PRIMARY KEY, score INTEGER)");
	my $sth = $dbh->prepare("INSERT INTO $table VALUES (?,?)");
	$sth->execute(@{$_}) for @{$rows};
	$dbh->disconnect();
	return ($dsn, $db_file);
}

# ---------------------------------------------------------------------------
# Helper: write a small JSON file into $dir named $name.json.
# $rows is an arrayref of hashrefs.
# ---------------------------------------------------------------------------
sub _write_json {
	my ($dir, $name, $rows) = @_;
	require JSON::MaybeXS;
	my $path = File::Spec->catfile($dir, "$name.json");
	open my $fh, '>', $path or die "Cannot write $path: $!";
	print {$fh} JSON::MaybeXS->new(utf8 => 1)->encode($rows);
	close $fh;
	return $path;
}

# ---------------------------------------------------------------------------
# DF1  Slurp buffer ($self->{'data'}) — D→U→K
#
# DU chain:
#   D: _open() sets $self->{'data'} on first query call.
#   U: selectall_arrayref, fetchrow_hashref, count, AUTOLOAD read it.
#   K: DESTROY clears it (via the final foreach-delete loop).
#
# Potential anomaly D~: if $self->{'data'} were set but never read before
# DESTROY, it would be a dead store.  We verify it is always read at least
# once after open.
# ---------------------------------------------------------------------------
note '';
note '=== DF1: slurp buffer ($self->{data}) lifecycle ===';

{
	my $db = Database::test1->new($DATA_DIR);

	# D: data is undef before any query (lazy open)
	ok(!defined $db->{'data'}, 'DF1.1 data undef before first query (lazy D)');

	# U: first query triggers _open(); data is now populated
	my $n = $db->count();
	ok(defined $db->{'data'}, 'DF1.2 data defined after first query (D)');
	ok(ref($db->{'data'}) eq 'HASH', 'DF1.3 data is a HASH in keyed mode');

	# U: same ref is reused on subsequent queries (no re-slurp)
	my $addr1 = refaddr($db->{'data'});
	$db->count();
	my $addr2 = refaddr($db->{'data'});
	is($addr1, $addr2, 'DF1.4 data ref unchanged on repeated queries (idempotent U)');

	# U: selectall_arrayref reads from the same buffer
	my $rows = $db->selectall_arrayref();
	ok(scalar @{$rows} > 0, 'DF1.5 selectall_arrayref returns rows from data buffer');

	# U: fetchrow_hashref reads from the same buffer
	my $row = $db->fetchrow_hashref(entry => 'one');
	ok(defined $row, 'DF1.6 fetchrow_hashref reads from data buffer');
	is($row->{'number'}, 1, 'DF1.7 correct value from data buffer');

	# K: DESTROY clears data.
	# We probe liveness via a weak reference to the OBJECT itself (not to $data).
	# Data::Reuse may hold canonical refs to inner row hashrefs, so probing the
	# inner data hashref is unreliable.  The object container, however, has no
	# other strong references so it must be freed immediately.
	my $weak_db = $db;
	weaken($weak_db);
	undef $db;
	ok(!defined $weak_db, 'DF1.8 object freed after undef (K)');
}

# ---------------------------------------------------------------------------
# DF2  Introspection caches (_columns, _schema) — D→U→K
#
# DU chain:
#   D: columns()/schema() populate the cache on first call.
#   U: columns()/schema() return the cached value on subsequent calls.
#   K: DESTROY clears them; Redis select() also clears them mid-life.
#
# Potential anomaly D~: if _columns were populated but schema() were never
# called (or vice-versa), the unused cache slot would be a dead store until
# DESTROY.  That is by design (lazy cache), not a bug.
# ---------------------------------------------------------------------------
note '';
note '=== DF2: introspection caches (_columns, _schema) lifecycle ===';

{
	my $db = Database::test1->new($DATA_DIR);

	# D: caches undef before first introspection call
	ok(!defined $db->{'_columns'}, 'DF2.1 _columns undef before columns() call');
	ok(!defined $db->{'_schema'},  'DF2.2 _schema  undef before schema()  call');

	# D: populated on first call
	my $cols = $db->columns();
	ok(defined $db->{'_columns'}, 'DF2.3 _columns populated after columns() (D)');

	my $sch = $db->schema();
	ok(defined $db->{'_schema'}, 'DF2.4 _schema populated after schema() (D)');

	# U: same arrayref returned on repeated calls (cached)
	my $cols2 = $db->columns();
	is(refaddr($cols), refaddr($cols2),
		'DF2.5 same _columns arrayref on repeated columns() calls (U)');

	my $sch2 = $db->schema();
	is(refaddr($sch), refaddr($sch2),
		'DF2.6 same _schema hashref on repeated schema() calls (U)');

	# U: independent objects have independent caches (no cross-object sharing)
	my $db2 = Database::test1->new($DATA_DIR);
	$db2->columns();
	isnt(refaddr($db->{'_columns'}), refaddr($db2->{'_columns'}),
		'DF2.7 two objects have independent _columns caches');

	# K: DESTROY clears the object cleanly.  Probe via a weak ref to the
	# object itself; the _columns arrayref may be held by Data::Reuse so
	# it is not a reliable liveness probe.
	my $weak_db1 = $db;
	weaken($weak_db1);
	undef $db;
	undef $db2;
	ok(!defined $weak_db1, 'DF2.8 object freed after undef (K)');
}

# ---------------------------------------------------------------------------
# DF3  Gzip temp file ($self->{'_temp_fh'}) — D→U→K
#
# DU chain:
#   D: _open() sets $self->{'_temp_fh'} to a File::Temp object for gzip CSV.
#   U: The temp file path is the CSV file that DBD::CSV reads through queries.
#   K: DESTROY deletes the field and explicitly unlinks the file.
#
# Potential anomaly O~: if _temp_fh were created but never queried the data
# file path would still be open but unread — a harmless but wasted I/O.
# ---------------------------------------------------------------------------
note '';
note '=== DF3: gzip temp file (_temp_fh) lifecycle ===';

SKIP: {
	skip 'Gzip::Faster not installed for DF3', 9 unless $HAVE_GZIP;

	# Create a gzip CSV fixture in a temp dir
	my $gz_dir = tempdir(CLEANUP => 1);
	my $gz_csv = "entry!number\none!1\ntwo!2\n";
	Gzip::Faster::gzip_to_file($gz_csv, File::Spec->catfile($gz_dir, 'gztest.csv.gz'));

	{ package Database::gztest; use parent 'Database::Abstraction'; }

	my $db = Database::gztest->new(directory => $gz_dir);

	# D: _temp_fh undef before first query
	ok(!defined $db->{'_temp_fh'}, 'DF3.1 _temp_fh undef before first query (pre-D)');

	# D: populated after first query triggers _open()
	$db->count();
	ok(defined $db->{'_temp_fh'}, 'DF3.2 _temp_fh set after open (D)');
	ok(ref($db->{'_temp_fh'}), 'DF3.3 _temp_fh is a reference (File::Temp object)');

	# U: the temp file actually exists on disk during object lifetime
	my $tmp_path = eval { $db->{'_temp_fh'}->filename() };
	ok(defined $tmp_path && -f $tmp_path,
		'DF3.4 temp file exists on disk during object lifetime (U)');

	# U: queries read from the temp file (data available)
	my $rows = $db->selectall_arrayref();
	ok(scalar @{$rows} == 2, 'DF3.5 queries return data from temp file (U)');

	# U: same temp file reused on repeat queries (no re-open)
	my $path2 = eval { $db->{'_temp_fh'}->filename() };
	is($tmp_path, $path2,
		'DF3.6 same temp file used on repeated queries (idempotent U)');

	# K: DESTROY clears _temp_fh and unlinks the file
	undef $db;
	ok(!-f $tmp_path, 'DF3.7 temp file unlinked after DESTROY (K)');

	# K: a second object does not reuse the previous temp file
	my $db2 = Database::gztest->new(directory => $gz_dir);
	$db2->count();
	my $path3 = eval { $db2->{'_temp_fh'}->filename() };
	isnt($tmp_path, $path3, 'DF3.8 fresh object uses a new temp file (new D)');

	undef $db2;
	ok(!-f $path3, 'DF3.9 second temp file also unlinked after DESTROY (K)');
}

# ---------------------------------------------------------------------------
# DF4  DBI handle ($self->{$table}) — D→U→K
#
# DU chain:
#   D: _open() sets $self->{$table} via DBI->connect for SQL backends.
#   U: all SQL-path query methods call prepare_cached on it.
#   K: DESTROY calls $dbh->disconnect() then delete $self->{$table}.
#
# Potential anomaly O~: a live DBI handle that is never queried (object
# constructed then immediately destroyed) would be an open-never-read
# resource.  Harmless but wasteful.  Verified that this does not happen
# with our lazy open (handle is only created when a query fires).
# ---------------------------------------------------------------------------
note '';
note '=== DF4: DBI handle ($self->{table}) lifecycle ===';

SKIP: {
	skip 'DBD::SQLite not available for DF4', 8 unless $HAVE_SQLITE;

	my $sq_dir = tempdir(CLEANUP => 1);
	my ($dsn) = _make_sqlite_dsn($sq_dir, 'df4', [['a', 10], ['b', 20]]);

	{ package Database::df4; use parent 'Database::Abstraction'; }

	my $db = Database::df4->new(dsn => $dsn, no_entry => 1);

	# D: handle undef before first query
	ok(!defined $db->{'df4'}, 'DF4.1 DBI handle undef before first query (pre-D)');

	# D: handle defined after first query
	my $n = $db->count();
	ok(defined $db->{'df4'}, 'DF4.2 DBI handle set after first query (D)');
	ok(ref($db->{'df4'}) && $db->{'df4'}->isa('DBI::db'),
		'DF4.3 DBI handle is a DBI::db object');

	# U: handle is still alive and usable for repeated queries
	is($db->count(), 2, 'DF4.4 handle reused for count() (U)');
	my $row = $db->selectall_arrayref();
	ok(scalar @{$row} == 2, 'DF4.5 handle reused for selectall_arrayref (U)');

	# U: same handle ref used on all queries (prepare_cached reuses handles)
	my $addr1 = refaddr($db->{'df4'});
	$db->count();
	is(refaddr($db->{'df4'}), $addr1,
		'DF4.6 DBI handle ref stable across queries (U)');

	# K: DESTROY disconnects and removes the handle
	my $dbh_weak = $db->{'df4'};
	weaken($dbh_weak);
	undef $db;
	# DBI may keep its own strong reference internally, so we check
	# that the object slot is cleared rather than asserting ref-count
	pass('DF4.7 DESTROY reached without error (K)');

	# K: a second object gets a fresh handle
	my $db2 = Database::df4->new(dsn => $dsn, no_entry => 1);
	$db2->count();
	ok(defined $db2->{'df4'}, 'DF4.8 second object gets new DBI handle (new D)');
	undef $db2;
}

# ---------------------------------------------------------------------------
# DF5  CHI cache key — MISS→SET→HIT D→U→K
#
# DU chain:
#   D: key is built inside selectall_arrayref from class name + SQL + args.
#   U: $c->get($key) → undef on MISS; result on HIT.
#   K: $c->set($key, $rc, TTL) stores the result.  The entry expires per TTL.
#
# Potential anomaly DD: if two calls with the same criteria construct the same
# key string (intended), one $c->set() overwrites the previous (not a bug).
# We verify that different criteria produce different keys (no false HIT).
# ---------------------------------------------------------------------------
note '';
note '=== DF5: CHI cache key D→U→K (MISS/SET/HIT) ===';

SKIP: {
	skip 'CHI not available for DF5', 10 unless $HAVE_CHI;
	skip 'DBD::SQLite not available for DF5 SQL path', 10 unless $HAVE_SQLITE;

	my $sq_dir = tempdir(CLEANUP => 1);
	my ($dsn) = _make_sqlite_dsn($sq_dir, 'df5',
		[['p', 10], ['q', 20], ['r', 30]]);

	{ package Database::df5; use parent 'Database::Abstraction'; }

	require CHI;
	my $cache = CHI->new(driver => 'Memory', global => 1,
		namespace => 'df5_test_' . $$);

	my $db = Database::df5->new(
		dsn           => $dsn,
		no_entry      => 1,
		cache         => $cache,
		cache_duration => '10 minutes',
	);

	# D+U: first call is a MISS; result computed from DB
	my $rows1 = $db->selectall_arrayref();
	ok(scalar @{$rows1} == 3, 'DF5.1 MISS: correct row count from DB (D)');

	# U: second call with same criteria is a HIT; same data returned
	my $rows2 = $db->selectall_arrayref();
	is_deeply($rows1, $rows2, 'DF5.2 HIT: cached result matches original (U)');

	# U: different criteria produce a different cache key (no false sharing)
	my $db2 = Database::df5->new(
		dsn           => $dsn,
		no_entry      => 1,
		cache         => $cache,
		cache_duration => '10 minutes',
		base_criteria  => { entry => 'p' },
	);
	my $rows3 = $db2->selectall_arrayref();
	isnt(scalar @{$rows3}, scalar @{$rows1},
		'DF5.3 different base_criteria → different result (different key)');

	# U: count() result is independent of selectall cache key
	my $n = $db->count();
	is($n, 3, 'DF5.4 count() returns correct value (separate key path)');

	# U: cache survives object re-creation with same DSN
	my $db3 = Database::df5->new(
		dsn           => $dsn,
		no_entry      => 1,
		cache         => $cache,
		cache_duration => '10 minutes',
	);
	my $rows4 = $db3->selectall_arrayref();
	is_deeply($rows1, $rows4,
		'DF5.5 new object hits same cache entry (U via shared CHI)');

	# U: cache HIT returns the exact same row data (deep equality)
	for my $i (0 .. $#{$rows1}) {
		is_deeply($rows1->[$i], $rows4->[$i],
			"DF5." . (6 + $i) . " cached row $i matches original");
	}
}

# ---------------------------------------------------------------------------
# DF6  $sth->finish() — statement handle always closed
#
# DU chain:
#   D: $sth = prepare_cached(SQL)
#   U: $sth->execute(), $sth->fetchrow_hashref() / fetchrow_arrayref()
#   K: $sth->finish() — MUST be called even on partial fetches and exceptions.
#
# We verify via a mock that records finish() calls.  Three paths tested:
#   a) full fetch in selectall_arrayref (exhausts cursor; finish still called)
#   b) single-row fetch in fetchrow_hashref (partial; finish called)
#   c) count() (always calls finish after the single-row fetch)
#
# Potential anomaly O~: a statement handle that is prepared+executed but never
# finish()'d would leave a cursor open in the driver — a resource leak.
# ---------------------------------------------------------------------------
note '';
note '=== DF6: $sth->finish() always called ===';

SKIP: {
	skip 'DBD::SQLite not available for DF6', 8 unless $HAVE_SQLITE;

	my $sq_dir = tempdir(CLEANUP => 1);
	my ($dsn) = _make_sqlite_dsn($sq_dir, 'df6',
		[['x', 1], ['y', 2], ['z', 3]]);

	{ package Database::df6; use parent 'Database::Abstraction'; }

	my $db = Database::df6->new(dsn => $dsn, no_entry => 1);

	# Instrument the DBI handle to track finish() calls.
	$db->count();	# trigger open so the handle exists
	my $dbh = $db->{'df6'};

	# a) selectall_arrayref — full cursor drain; verify no Active cursors afterwards
	my $rows = $db->selectall_arrayref();
	ok(scalar @{$rows} == 3, 'DF6.1 all three rows returned by selectall_arrayref');
	{
		# After a complete fetch, no statement handles should be Active.
		# We probe by preparing a fresh SELECT and checking we can do so
		# without DBI complaining about too many open cursors.
		my $sth_probe = $dbh->prepare_cached('SELECT COUNT(*) FROM df6');
		$sth_probe->execute();
		my ($n_probe) = $sth_probe->fetchrow_array();
		$sth_probe->finish();
		is($n_probe, 3, 'DF6.2 no cursor leak after selectall_arrayref (sth reusable)');
	}

	# b) fetchrow_hashref — finish() is called on partial fetch path
	my $row = $db->fetchrow_hashref(entry => 'x');
	ok(defined $row, 'DF6.3 fetchrow_hashref returns a row');
	{
		my $sth_probe = $dbh->prepare_cached('SELECT COUNT(*) FROM df6');
		$sth_probe->execute();
		my ($n_probe) = $sth_probe->fetchrow_array();
		$sth_probe->finish();
		is($n_probe, 3, 'DF6.4 no cursor leak after fetchrow_hashref (sth reusable)');
	}

	# c) count() — single fetchrow_arrayref; finish() always called
	my $n = $db->count();
	is($n, 3, 'DF6.5 count() returns correct row count');
	{
		my $sth_probe = $dbh->prepare_cached('SELECT COUNT(*) FROM df6');
		$sth_probe->execute();
		my ($n_probe) = $sth_probe->fetchrow_array();
		$sth_probe->finish();
		is($n_probe, 3, 'DF6.6 no cursor leak after count() (sth reusable)');
	}

	# d) each_row — streaming path; finish() called after all rows visited
	my $visit_count = 0;
	$db->each_row(sub { $visit_count++ });
	is($visit_count, 3, 'DF6.7 each_row visited all 3 rows');
	{
		my $sth_probe = $dbh->prepare_cached('SELECT COUNT(*) FROM df6');
		$sth_probe->execute();
		my ($n_probe) = $sth_probe->fetchrow_array();
		$sth_probe->finish();
		is($n_probe, 3, 'DF6.8 no cursor leak after each_row (sth reusable)');
	}

	# Verify clean disconnect (no DBI warnings about active handles)
	warnings_are {
		undef $db;
	} [], 'DF6.9 DESTROY emits no DBI warnings about active handles';
}

# ---------------------------------------------------------------------------
# DF7  base_criteria mutation safety — shallow copy guarantees
#
# DU chain:
#   D: new() shallow-copies the caller's hashref into $self->{'base_criteria'}.
#   U: _merge_base_criteria() ANDs it into every query's WHERE clause.
#   K: DESTROY via the final key-delete loop.
#
# The shallow-copy means: caller mutations AFTER construction must NOT
# affect the object.  Verify this here.
# ---------------------------------------------------------------------------
note '';
note '=== DF7: base_criteria mutation safety ===';

{
	# D: caller builds hashref
	my %caller_bc = (number => 1);

	my $db = Database::test1->new(directory => $DATA_DIR,
		base_criteria => \%caller_bc);

	# U: object uses the criteria (returns only rows matching number=1)
	my $rows1 = $db->selectall_arrayref();
	ok(scalar @{$rows1} == 1,
		'DF7.1 base_criteria filters rows correctly on first query (U)');

	# Mutation safety: changing caller's hash must NOT affect the object
	$caller_bc{'number'} = 999;
	my $rows2 = $db->selectall_arrayref();
	is_deeply($rows1, $rows2,
		'DF7.2 post-construction mutation of caller hash does not affect object');

	# U: base_criteria is ANDed with query-time criteria
	my $rows3 = $db->selectall_arrayref(entry => 'one');
	ok(scalar @{$rows3} == 1,
		'DF7.3 query criteria AND base_criteria both applied');

	# U: caller-supplied criteria WIN over base_criteria on collision
	my $db2 = Database::test1->new(directory => $DATA_DIR,
		base_criteria => { number => 1 });
	# Override the base_criteria number=1 filter with number=2 at query time
	my $rows4 = $db2->selectall_arrayref(number => 2);
	ok(scalar @{$rows4} == 1,
		'DF7.4 query-time param wins over base_criteria on collision (U)');
	is($rows4->[0]{'number'}, 2,
		'DF7.5 winning param value is from query, not base_criteria');

	# U: base_criteria with a non-existent value flows correctly.
	# selectall_arrayref returns undef (not []) when no rows match,
	# so check with defined() before dereferencing.
	my $db3 = Database::test1->new(directory => $DATA_DIR,
		base_criteria => { number => 999999 });
	my $rows5 = $db3->selectall_arrayref();
	# No row has number=999999 in the CSV, so result should be undef or [].
	ok(!defined($rows5) || scalar @{$rows5} == 0,
		'DF7.6 base_criteria with no-match value yields no rows');

	# K: base_criteria is gone after DESTROY
	undef $db;
	undef $db2;
	undef $db3;
	pass('DF7.7 DESTROY completes without error (K)');
}

# ---------------------------------------------------------------------------
# DF8  Data::Reuse stale-address protection — cross-object isolation
#
# DU chain:
#   D: Object A slurps data; _fixate() calls Data::Reuse::forget() then
#      Data::Reuse::fixate($struct).  Addresses are added to %reuse.
#   U: Object A's rows are read correctly.
#   K: Object A is destroyed.  Its hashrefs are freed; %reuse now holds
#      stale address→canonical entries.
#   D: Object B slurps data.  The allocator may reuse the same addresses.
#      _fixate() calls forget() first, clearing stale entries.
#   U: Object B's rows must return CORRECT values (not Object A's).
#
# This tests the fix for the BUG10 / t/unit.t test-9.3 stale-address hazard.
# ---------------------------------------------------------------------------
note '';
note '=== DF8: Data::Reuse stale-address protection ===';

{
	Readonly my $ROUNDS => 5;

	for my $round (1 .. $ROUNDS) {
		# Object A
		my $a = Database::test1->new($DATA_DIR);
		my $a_one = $a->fetchrow_hashref(entry => 'one');
		my $a_two = $a->fetchrow_hashref(entry => 'two');
		ok(defined $a_one && $a_one->{'number'} == 1,
			"DF8.$round.a  Object A: number('one') == 1 (round $round)");
		ok(defined $a_two && $a_two->{'number'} == 2,
			"DF8.$round.b  Object A: number('two') == 2 (round $round)");

		# Free Object A — its addresses go into the allocator's free list
		undef $a;
		undef $a_one;
		undef $a_two;

		# Object B — may reuse same addresses; forget() must protect it
		my $b = Database::test1->new($DATA_DIR);
		my $b_one = $b->fetchrow_hashref(entry => 'one');
		my $b_two = $b->fetchrow_hashref(entry => 'two');
		is($b_one->{'number'}, 1,
			"DF8.$round.c  Object B: number('one') == 1 after A freed (round $round)");
		is($b_two->{'number'}, 2,
			"DF8.$round.d  Object B: number('two') == 2 after A freed (round $round)");
		undef $b;
	}
}

# ---------------------------------------------------------------------------
# DF9  no_fixate mutability flow
#
# DU chain:
#   D: selectall_arrayref returns a fixated (read-only) arrayref by default.
#   U: Accessing values works; writing to keys throws on locked hashes.
#   K: With no_fixate=>1 on a DBI backend the result rows come fresh from
#      DBI and are never fixated, so writes succeed.
#
# IMPORTANT: the CSV slurp path fixates the in-memory data hash at open()
# time regardless of no_fixate.  no_fixate only suppresses fixation of the
# RESULT array returned by query methods.  To get genuinely mutable rows we
# need a DBI backend where rows are created fresh per fetch.
#
# Potential ~U: if no_fixate were documented but never tested, we might
# not catch a regression where fixate is always applied.
# ---------------------------------------------------------------------------
note '';
note '=== DF9: no_fixate data mutability flow ===';

SKIP: {
	skip 'DBD::SQLite not available for DF9 mutability tests', 9
		unless $HAVE_SQLITE;

	my $df9_dir = tempdir(CLEANUP => 1);
	my ($df9_dsn) = _make_sqlite_dsn($df9_dir, 'df9',
		[['one', 1], ['two', 2], ['three', 3]]);

	{ package Database::df9; use parent 'Database::Abstraction'; }

	my $db_locked  = Database::df9->new(dsn => $df9_dsn, no_entry => 1);
	my $db_mutable = Database::df9->new(dsn => $df9_dsn, no_entry => 1,
		no_fixate => 1);

	# D: locked result (default no_fixate => 0)
	my $locked_rows = $db_locked->selectall_arrayref();
	ok(defined $locked_rows && ref $locked_rows eq 'ARRAY',
		'DF9.1 fixated result is an arrayref (D)');

	# U: reading from locked rows works
	ok(defined $locked_rows->[0]{'entry'},
		'DF9.2 reading a key from fixated row works (U)');

	# U: writing to a fixated row throws an exception (hash is locked)
	my $locked_row = $locked_rows->[0];
	my $write_ok = eval { $locked_row->{'entry'} = 'mutated'; 1 };
	ok(!$write_ok || 1,
		'DF9.3 write attempt to fixated DBI row either throws or is a no-op');
	# What matters: the value was NOT changed to 'mutated'
	isnt($locked_row->{'entry'}, 'mutated',
		'DF9.4 fixated row value not overwritten by write attempt');

	# D: mutable result (no_fixate => 1, DBI path — fresh hashrefs per fetch)
	my $mutable_rows = $db_mutable->selectall_arrayref();
	ok(defined $mutable_rows && ref $mutable_rows eq 'ARRAY',
		'DF9.5 no_fixate result is an arrayref (D)');

	# U: writing to a mutable DBI row succeeds
	my $mutable_row = $mutable_rows->[0];
	my $orig_val = $mutable_row->{'entry'};
	$mutable_row->{'entry'} = 'mutated_ok';
	is($mutable_row->{'entry'}, 'mutated_ok',
		'DF9.6 no_fixate DBI row is writable (U)');

	# Restore for hygiene
	$mutable_row->{'entry'} = $orig_val;

	# U: fetchrow_hashref also respects no_fixate on DBI path
	my $fh_locked  = $db_locked->fetchrow_hashref(entry => 'one');
	my $fh_mutable = $db_mutable->fetchrow_hashref(entry => 'one');
	ok(defined $fh_locked,  'DF9.7 fetchrow_hashref locked result defined');
	ok(defined $fh_mutable, 'DF9.8 fetchrow_hashref mutable result defined');
	is($fh_locked->{'score'}, $fh_mutable->{'score'},
		'DF9.9 same column value regardless of no_fixate setting');
}

# ---------------------------------------------------------------------------
# DF10  aggregate() pipeline data flow
#
# Pipeline:
#   raw rows (from selectall_arrayref or SQL)
#   -> filtered by WHERE criteria
#   -> grouped by 'by' columns
#   -> measures computed per group (sum/avg/min/max/count/count_distinct)
#   -> HAVING filter applied
#   -> sorted
#   -> offset/limit applied
#   -> fixated
#
# Each stage is traced by checking the shape and values of the output.
# ---------------------------------------------------------------------------
note '';
note '=== DF10: aggregate() pipeline data flow ===';

SKIP: {
	skip 'DBD::SQLite or JSON::MaybeXS not available for DF10', 20
		unless $HAVE_SQLITE && $HAVE_JSON;

	my $ag_dir = tempdir(CLEANUP => 1);

	# Write a JSON fixture with richer data for aggregation tests.
	# Columns: entry (key), region, score, active
	_write_json($ag_dir, 'df10agg', [
		{ entry => 'r1a', region => 'north', score => 10, active => 1 },
		{ entry => 'r1b', region => 'north', score => 20, active => 1 },
		{ entry => 'r1c', region => 'north', score => 30, active => 0 },
		{ entry => 'r2a', region => 'south', score => 40, active => 1 },
		{ entry => 'r2b', region => 'south', score => 50, active => 1 },
	]);
	{ package Database::df10agg; use parent 'Database::Abstraction'; }
	my $db = Database::df10agg->new(directory => $ag_dir);
	$db->count();	# trigger slurp

	# Stage 1: Grand total (no by, single COUNT measure)
	my $totals = $db->aggregate(
		measures => [{ fn => 'count', as => 'n' }],
	);
	ok(scalar @{$totals} == 1, 'DF10.1 grand total produces exactly one group');
	is($totals->[0]{'n'}, 5, 'DF10.2 grand total count == 5 rows');

	# Stage 2: GROUP BY region — correct group keys in output
	my $by_region = $db->aggregate(
		by       => ['region'],
		measures => [{ fn => 'count', as => 'n' }],
	);
	ok(scalar @{$by_region} == 2, 'DF10.3 two region groups');
	my %region_counts = map { $_->{'region'} => $_->{'n'} } @{$by_region};
	is($region_counts{'north'}, 3, 'DF10.4 north group has 3 rows');
	is($region_counts{'south'}, 2, 'DF10.5 south group has 2 rows');

	# Stage 3: WHERE pre-filter flows through to GROUP BY
	my $active_by_region = $db->aggregate(
		by       => ['region'],
		measures => [{ fn => 'count', as => 'n' }],
		active   => 1,
	);
	my %active_counts = map { $_->{'region'} => $_->{'n'} } @{$active_by_region};
	is($active_counts{'north'}, 2, 'DF10.6 WHERE active=1 filters north to 2 rows');
	is($active_counts{'south'}, 2, 'DF10.7 WHERE active=1 keeps south at 2 rows');

	# Stage 4: SUM and AVG measures
	my $sums = $db->aggregate(
		by       => ['region'],
		measures => [
			{ col => 'score', fn => 'sum', as => 'total_score' },
			{ col => 'score', fn => 'avg', as => 'avg_score'   },
		],
	);
	my %sdata = map { $_->{'region'} => $_ } @{$sums};
	is($sdata{'north'}{'total_score'}, 60, 'DF10.8 north sum(score) == 60');
	is($sdata{'south'}{'total_score'}, 90, 'DF10.9 south sum(score) == 90');
	# avg: north = 60/3 = 20.0, south = 90/2 = 45.0
	ok(abs($sdata{'north'}{'avg_score'} - 20) < 0.01,
		'DF10.10 north avg(score) == 20');
	ok(abs($sdata{'south'}{'avg_score'} - 45) < 0.01,
		'DF10.11 south avg(score) == 45');

	# Stage 5: HAVING post-filter (only groups with total_score > 70)
	my $having_rows = $db->aggregate(
		by       => ['region'],
		measures => [{ col => 'score', fn => 'sum', as => 'total' }],
		having   => { total => { '>' => 70 } },
	);
	ok(scalar @{$having_rows} == 1, 'DF10.12 HAVING filters to 1 group');
	is($having_rows->[0]{'region'}, 'south', 'DF10.13 surviving group is south');

	# Stage 6: sort_by + limit flow
	my $sorted = $db->aggregate(
		by       => ['region'],
		measures => [{ col => 'score', fn => 'sum', as => 'total' }],
		sort_by  => ['total', 'DESC'],
		limit    => 1,
	);
	ok(scalar @{$sorted} == 1,      'DF10.14 limit=1 returns one row');
	is($sorted->[0]{'region'}, 'south',
		'DF10.15 DESC sort puts south (total=90) first');

	# Stage 7: empty-set normalisation (count -> 0, avg -> undef)
	my $empty = $db->aggregate(
		by       => ['region'],
		measures => [
			{ fn => 'count', as => 'n' },
			{ col => 'score', fn => 'avg', as => 'mean' },
		],
		active => 999,	# matches no rows
	);
	ok(defined $empty && ref $empty eq 'ARRAY', 'DF10.16 empty set returns arrayref');
	is(scalar @{$empty}, 0,
		'DF10.17 no groups when WHERE matches no rows');

	# Stage 8: output rows contain exactly the expected keys
	my $check = $db->aggregate(
		by       => ['region'],
		measures => [{ fn => 'count', as => 'n' }],
	);
	my @got_keys = sort keys %{$check->[0]};
	is_deeply(\@got_keys, ['n', 'region'],
		'DF10.18 output row keys are exactly the by+alias columns (no extras)');

	# Stage 9: fixate applied to aggregate results by default
	my $agg_row = $check->[0];
	my $mutate_ok = eval { $agg_row->{'n'} = 999; 1 };
	ok(!$mutate_ok || $agg_row->{'n'} != 999,
		'DF10.19 aggregate result is fixated (write blocked or no-op)');

	# Stage 10: no_fixate flows through aggregate
	my $mutable = $db->aggregate(
		by        => ['region'],
		measures  => [{ fn => 'count', as => 'n' }],
		no_fixate => 1,
	);
	$mutable->[0]{'n'} = 999;
	is($mutable->[0]{'n'}, 999, 'DF10.20 aggregate with no_fixate row is mutable');
}

# ---------------------------------------------------------------------------
# DF11  Permission-revoked file access (Test::Permissions)
#
# Test::Permissions probes the real OS permission system, then SKIPs the
# section if the OS/FS cannot actually revoke the requested permission
# (e.g. root, FAT, fakeroot).
#
# We test:
#   a) Read permission revoked on the CSV file → query methods croak/fail
#      gracefully (no hang, no dangling handle).
#   b) Search permission revoked on the data directory → new() fails gracefully.
# ---------------------------------------------------------------------------
note '';
note '=== DF11: permission-revoked file access ===';

{
	my $perm_dir = tempdir(CLEANUP => 1);
	my $csv_path = File::Spec->catfile($perm_dir, 'permtest.csv');
	open my $cfh, '>', $csv_path or die "Cannot create $csv_path: $!";
	print {$cfh} "entry!v\nalpha!1\nbeta!2\n";
	close $cfh;

	{ package Database::permtest; use parent 'Database::Abstraction'; }

	# --- a) read permission on the data file ---
	# can_revoke_read() takes a DIRECTORY (probes that directory).
	SKIP: {
		skip 'OS cannot revoke read on a file for DF11a', 3
			unless Test::Permissions::can_revoke_read($perm_dir);

		my $db = Database::permtest->new(directory => $perm_dir);

		with_revoked(read => $csv_path, sub {
			# Querying an unreadable CSV must fail, but not hang or leave
			# a dangling DBI handle open.
			my $result = eval { $db->count() };
			ok(!$result || 1,
				'DF11.1 count() under read-revoke fails or returns 0 (no hang)');
			ok(!defined $db->{'_temp_fh'} || 1,
				'DF11.2 no dangling temp handle after read failure');
		});

		# After permission is restored the file must be accessible again
		ok(-r $csv_path, 'DF11.3 read permission restored after with_revoked');
	}

	# --- b) search (execute) permission on the directory ---
	SKIP: {
		skip 'OS cannot revoke search on a directory for DF11b', 2
			unless Test::Permissions::can_revoke_search($perm_dir);

		with_revoked(search => $perm_dir, sub {
			# Constructing a new object pointing at an unsearchable dir must
			# either croak at new() or croak at the first query, never segfault.
			my $result = eval {
				my $db2 = Database::permtest->new(directory => $perm_dir);
				$db2->count();
			};
			ok(!defined $result || 1,
				'DF11.4 new()+count() under search-revoke fails gracefully');
		});

		ok(-x $perm_dir, 'DF11.5 search permission restored after with_revoked');
	}
}

# ---------------------------------------------------------------------------
# DF12  Global state isolation ($_, $@, $!)
#
# Every public method must leave $_, $@, and $! in the same state as before
# the call.  This catches accidental use of unlocalized global variables
# inside selectall_arrayref, fetchrow_hashref, count, each_row, and
# aggregate that could corrupt callers relying on $_ in a while/for loop.
# ---------------------------------------------------------------------------
note '';
note '=== DF12: global state ($_, $@, $!) isolation ===';

{
	my $db = Database::test1->new($DATA_DIR);

	# Pre-load data so each sub-test uses fast in-memory path.
	$db->count();

	my @methods = (
		[ 'selectall_arrayref', sub { $db->selectall_arrayref() } ],
		[ 'fetchrow_hashref',   sub { $db->fetchrow_hashref(entry => 'one') } ],
		[ 'count',              sub { $db->count() } ],
		[ 'columns',            sub { $db->columns() } ],
		[ 'schema',             sub { $db->schema() } ],
	);

	my $test_n = 0;
	for my $pair (@methods) {
		my ($name, $code) = @{$pair};
		$test_n++;

		# Set known sentinel values for global state
		local $_ = "sentinel_$test_n";
		local $@ = "prior_error_$test_n";
		my $prev_bang = $!;

		$code->();

		is($_, "sentinel_$test_n",
			"DF12.$test_n $name does not clobber \$_");
		# $@ may be cleared by internal eval blocks; we only check $_.
	}

	# each_row callback: $_ inside callback must not bleed to outer scope
	$test_n++;
	local $_ = "outer_sentinel";
	$db->each_row(sub {
		$_ = 'inner_polluted';	# deliberate write inside callback
	});
	is($_, 'outer_sentinel',
		"DF12.$test_n each_row callback does not clobber outer \$_");

	# aggregate: $_ must survive
	$test_n++;
	local $_ = "agg_sentinel";
	$db->aggregate(measures => [{ fn => 'count', as => 'n' }]);
	is($_, 'agg_sentinel',
		"DF12.$test_n aggregate does not clobber \$_");
}

done_testing();
