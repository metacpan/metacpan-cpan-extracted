#!perl -w

# Transaction-flow tests for Database::Abstraction.
#
# Since Database::Abstraction is a read-only ORM, "transactions" here cover:
#   1.  Object lifecycle       — lazy-open → query → DESTROY sequencing
#   2.  Query idempotency      — repeated reads return identical state
#   3.  Multi-instance isolation — concurrent objects on the same data are independent
#   4.  CHI cache lifecycle    — MISS → SET → HIT → new-key sequence
#   5.  Gzip resource lifecycle — temp-file born, used, and unlinked on DESTROY
#   6.  Query-builder chain    — multi-step chains produce consistent results
#   7.  each_row() streaming   — lifecycle of a streaming cursor from open to completion
#   8.  base_criteria filter   — persistent filter applied uniformly across all query methods
#   9.  Schema/columns caching — introspection cache populated and reused per object
#  10.  Exception safety       — mid-flight failures leave the object in a usable state
#  11.  SQLite DBI lifecycle   — DSN-based connection open, query, and teardown
#
# Tests use sequences, not isolated function calls — each section walks through
# a multi-step flow and asserts state at every boundary.

use strict;
use warnings;

use FindBin    qw($Bin);
use File::Spec;
use File::Temp ();
use IO::Compress::Gzip qw(gzip $GzipError);
use Readonly;
use Test::Most  tests => 70;
use Test::NoWarnings;

use lib 't/lib';
use Database::test1;

Readonly my $DATA_DIR          => File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');
Readonly my $ENTRY_ONE         => 'one';
Readonly my $ENTRY_TWO         => 'two';
Readonly my $ENTRY_THREE       => 'three';
Readonly my $NUMBER_ONE        => 1;
Readonly my $NUMBER_TWO        => 2;
Readonly my $NUMBER_THREE      => 3;
Readonly my $EXPECTED_ROW_COUNT => 4;	# one, two, three, empty

# Optional-dependency flag for Section 11
Readonly my $HAVE_SQLITE => do { eval { require DBI; require DBD::SQLite }; !$@ };
Readonly my $SQLITE_ROW_COUNT => 3;

# ---------------------------------------------------------------------------
# Section 1: Object lifecycle — lazy-open → query → DESTROY
# ---------------------------------------------------------------------------
note('Section 1: object lifecycle');

{
	# T1-1: object created but _table_name not yet set — lazy open
	my $db = Database::test1->new($DATA_DIR);
	ok(!defined $db->{'_table_name'}, 'T1-1: _table_name is undef before first query (lazy open)');

	# T1-2: first query triggers _open; _table_name now populated
	my $n = $db->count();
	ok(defined $db->{'_table_name'}, 'T1-2: _table_name set after first query');

	# T1-3: slurp path — $self->{'data'} is a hashref after _open
	ok(ref($db->{'data'}) eq 'HASH', 'T1-3: slurped data stored as HASH ref');

	# T1-4: count() is consistent with selectall_arrayref() row count
	my $rows = $db->selectall_arrayref();
	cmp_ok($n, '==', scalar @{$rows}, 'T1-4: count() == scalar(@{ selectall_arrayref() })');

	# T1-5: fetchrow_hashref returns data consistent with selectall result
	my $row = $db->fetchrow_hashref(entry => $ENTRY_TWO);
	cmp_ok($row->{'number'}, '==', $NUMBER_TWO, 'T1-5: fetchrow_hashref(entry=two) -> number=2');

	# T1-6: DESTROY on a live, fully-opened object does not croak
	lives_ok { $db->DESTROY() } 'T1-6: explicit DESTROY on a live object does not croak';
}

# ---------------------------------------------------------------------------
# Section 2: Query idempotency — repeated reads return identical state
# ---------------------------------------------------------------------------
note('Section 2: query idempotency');

{
	my $db = Database::test1->new($DATA_DIR);

	# T2-1: count() returns the same value across three consecutive calls
	my $c1 = $db->count();
	my $c2 = $db->count();
	my $c3 = $db->count();
	ok($c1 == $c2 && $c2 == $c3 && $c1 == $EXPECTED_ROW_COUNT,
	    'T2-1: count() is idempotent across three consecutive calls');

	# T2-2: selectall_arrayref() called twice returns a deeply equal structure
	my $r1 = $db->selectall_arrayref();
	my $r2 = $db->selectall_arrayref();
	is_deeply($r1, $r2, 'T2-2: selectall_arrayref() is idempotent (deep equality)');

	# T2-3: fetchrow_hashref for the same key is deeply equal across two calls
	my $h1 = $db->fetchrow_hashref(entry => $ENTRY_ONE);
	my $h2 = $db->fetchrow_hashref(entry => $ENTRY_ONE);
	is_deeply($h1, $h2, 'T2-3: fetchrow_hashref() is idempotent for same key');

	# T2-4: AUTOLOAD column lookup returns the same scalar across three calls
	my $v1 = $db->number(entry => $ENTRY_THREE);
	my $v2 = $db->number(entry => $ENTRY_THREE);
	my $v3 = $db->number(entry => $ENTRY_THREE);
	ok($v1 == $NUMBER_THREE && $v2 == $NUMBER_THREE && $v3 == $NUMBER_THREE,
	    'T2-4: AUTOLOAD number(entry=three) is idempotent across three calls');
}

# ---------------------------------------------------------------------------
# Section 3: Multi-instance isolation — concurrent objects on the same data
# ---------------------------------------------------------------------------
note('Section 3: multi-instance isolation');

{
	my $db1 = Database::test1->new($DATA_DIR);
	my $db2 = Database::test1->new($DATA_DIR);

	# T3-1: both objects return the same row count
	my $c1 = $db1->count();
	my $c2 = $db2->count();
	cmp_ok($c1, '==', $c2, 'T3-1: two independent objects agree on row count');

	# T3-2: both objects have separate in-memory data refs — NOT the same reference
	my $d1 = $db1->{'data'};
	my $d2 = $db2->{'data'};
	isnt("$d1", "$d2", 'T3-2: db1 and db2 have independent data refs (no shared memory)');

	# T3-3 / T3-4: destroying $db2 mid-flight does not break $db1
	$db2->DESTROY();
	lives_ok { $db1->count() }    'T3-3: db1->count() succeeds after db2 is destroyed';
	my $row = $db1->fetchrow_hashref(entry => $ENTRY_TWO);
	cmp_ok($row->{'number'}, '==', $NUMBER_TWO,
	    'T3-4: db1 returns correct data after db2 destruction (no Data::Reuse cross-contamination)');

	# T3-5: a new object created after db1+db2 cycle sees the same data
	my $db3 = Database::test1->new($DATA_DIR);
	cmp_ok($db3->count(), '==', $c1,
	    'T3-5: newly created db3 sees same row count after db1+db2 lifecycle');
}

# ---------------------------------------------------------------------------
# Section 4: CHI cache lifecycle — MISS → SET → HIT → new-key
# ---------------------------------------------------------------------------
note('Section 4: CHI cache lifecycle');

SKIP: {
	eval { require CHI };
	skip 'CHI not installed', 6 if $@;

	my $cache = CHI->new(driver => 'RawMemory', global => 1);
	$cache->on_set_error('die');
	$cache->on_get_error('die');

	# T4-1: cache is empty before the first SQL query
	cmp_ok(scalar $cache->get_keys(), '==', 0,
	    'T4-1: cache starts empty before any query');

	# Force SQL path with max_slurp_size=>0 so cache is actually consulted.
	my $db_sql = Database::test1->new(
		directory      => $DATA_DIR,
		cache          => $cache,
		cache_duration => '1 hour',
		max_slurp_size => 0,
	);

	# T4-2: first selectall_arrayref() is a MISS and populates one cache entry
	my $fresh = $db_sql->selectall_arrayref();
	cmp_ok(scalar $cache->get_keys(), '==', 1,
	    'T4-2: after first selectall_arrayref(), cache has 1 key (MISS -> SET)');

	# T4-3: second identical query is a HIT — cache key count unchanged
	$db_sql->selectall_arrayref();
	cmp_ok(scalar $cache->get_keys(), '==', 1,
	    'T4-3: second identical query is a cache HIT (key count unchanged)');

	# T4-4: a parameterised selectall_arrayref produces a second cache key
	# (count() reads but never writes the cache, so we use selectall_arrayref)
	$db_sql->selectall_arrayref(entry => $ENTRY_ONE);
	cmp_ok(scalar $cache->get_keys(), '>=', 2,
	    'T4-4: parameterised selectall_arrayref produces a new cache key (MISS -> SET)');

	# T4-5: cached result is structurally identical to a repeat fresh call result
	my $cached = $db_sql->selectall_arrayref();
	is_deeply($fresh, $cached,
	    'T4-5: cache HIT returns data deeply equal to the original MISS result');

	# T4-6: a second object sharing the same cache gets a HIT for a key the first populated
	my $db_sql2 = Database::test1->new(
		directory      => $DATA_DIR,
		cache          => $cache,
		cache_duration => '1 hour',
		max_slurp_size => 0,
	);
	my $pre_keys = scalar $cache->get_keys();
	$db_sql2->selectall_arrayref();
	cmp_ok(scalar $cache->get_keys(), '==', $pre_keys,
	    "T4-6: second object sharing cache gets HIT from first object's entry (no new key added)");
}

# ---------------------------------------------------------------------------
# Section 5: Gzip resource lifecycle — temp file born, used, and unlinked
# ---------------------------------------------------------------------------
note('Section 5: gzip temp file resource lifecycle');

{
	# Build a gzip CSV in a temp directory.
	# test1 uses '!' as sep_char and has an 'entry' key column.
	my $tmpdir = File::Temp->newdir(CLEANUP => 1);
	my $csv_plain = "entry!number\n\"one\"!1\n\"two\"!2\n\"three\"!3\n";
	my $gz_path   = File::Spec->catfile("$tmpdir", 'test1.csv.gz');
	gzip \$csv_plain => $gz_path or die "gzip failed: $GzipError";

	# T5-1: gzip CSV opens and returns the correct row count
	my $db_gz = Database::test1->new("$tmpdir");
	cmp_ok($db_gz->count(), '==', 3, 'T5-1: gzip CSV opens and count() == 3');

	# T5-2: during lifetime, _temp_fh holds a File::Temp object (decompressed copy)
	ok(defined $db_gz->{'_temp_fh'}, 'T5-2: _temp_fh is set while gzip object is alive');

	# T5-3: the temp file actually exists on disk during object lifetime
	my $tmpfile_path = $db_gz->{'_temp_fh'}->filename();
	ok(-e $tmpfile_path, 'T5-3: decompressed temp file exists on disk during object lifetime');

	# T5-4: multiple queries use the same temp file (no re-extraction between calls)
	my $path_after_q2 = do { $db_gz->selectall_arrayref(); $db_gz->{'_temp_fh'}->filename() };
	is($path_after_q2, $tmpfile_path,
	    'T5-4: same temp file path after second query (no re-extraction)');

	# T5-5: after DESTROY, _temp_fh is cleared (File::Temp auto-unlinks it)
	$db_gz->DESTROY();
	ok(!defined $db_gz->{'_temp_fh'},
	    'T5-5: _temp_fh cleared after DESTROY (temp file auto-unlinked)');
}

# ---------------------------------------------------------------------------
# Section 6: Query-builder chain idempotency
# ---------------------------------------------------------------------------
note('Section 6: query-builder chain idempotency');

{
	my $db = Database::test1->new($DATA_DIR);

	# T6-1: where→limit→all delivers the expected filtered, limited result
	my $r1 = $db->query()
	            ->where(entry => $ENTRY_ONE)
	            ->limit(5)
	            ->all();
	ok(ref $r1 eq 'ARRAY' && scalar @{$r1} == 1 && $r1->[0]{'entry'} eq $ENTRY_ONE,
	    'T6-1: where(entry=one)->limit(5)->all() returns exactly 1 matching row');

	# T6-2: executing the identical chain a second time returns a deeply equal result
	my $r2 = $db->query()
	            ->where(entry => $ENTRY_ONE)
	            ->limit(5)
	            ->all();
	is_deeply($r1, $r2, 'T6-2: identical builder chain executed twice gives deeply equal results');

	# T6-3: query-builder count() is consistent with direct count() for same params
	my $qb_count     = $db->query()->where(entry => $ENTRY_TWO)->count();
	my $direct_count = $db->count(entry => $ENTRY_TWO);
	cmp_ok($qb_count, '==', $direct_count,
	    'T6-3: query-builder count() == direct count() for identical criteria');

	# T6-4: two independent chains on the same object return independent results
	my $chain_a = $db->query()->where(entry => $ENTRY_ONE)->all();
	my $chain_b = $db->query()->where(entry => $ENTRY_TWO)->all();
	isnt($chain_a->[0]{'entry'}, $chain_b->[0]{'entry'},
	    'T6-4: two independent builder chains return distinct result sets');
}

# ---------------------------------------------------------------------------
# Section 7: each_row() streaming transaction lifecycle
# Walk an each_row() call from open through sort/limit/offset/filter/exception.
# ---------------------------------------------------------------------------
note('Section 7: each_row() streaming lifecycle');

{
	# --- T7-1 : return value equals number of rows visited (matches count()) ---
	{
		my $db = Database::test1->new($DATA_DIR);
		my $visited = 0;
		my $n = $db->each_row(sub { $visited++ });
		cmp_ok($n, '==', $visited,
		    'T7-1: each_row() return value equals callback invocation count');
	}

	# --- T7-2 : callback receives hashrefs with the expected column data ---
	{
		my $db = Database::test1->new($DATA_DIR);
		my $one_row;
		$db->each_row(sub {
			my ($row) = @_;
			$one_row //= $row if (($row->{'entry'} // '') eq $ENTRY_ONE);
		});
		ok(defined $one_row && $one_row->{'number'} == $NUMBER_ONE,
		    'T7-2: each_row callback receives hashref with correct column data');
	}

	# --- T7-3 : sort_by DESC delivers highest-number row first ---
	# Rows by number (string) DESC: "3" > "2" > "1" > "" — so 'three' is first.
	{
		my $db = Database::test1->new($DATA_DIR);
		my $first_entry;
		$db->each_row(
			sub { $first_entry //= $_[0]->{'entry'} },
			sort_by => ['number', 'DESC'],
		);
		is($first_entry, $ENTRY_THREE,
		    'T7-3: sort_by number DESC delivers "three" (number=3) as first row');
	}

	# --- T7-4 : limit restricts the number of rows delivered to the callback ---
	{
		my $db = Database::test1->new($DATA_DIR);
		my $n = $db->each_row(sub { }, sort_by => 'entry', limit => 2);
		cmp_ok($n, '==', 2, 'T7-4: limit => 2 delivers exactly 2 rows');
	}

	# --- T7-5 : offset skips leading rows from the sorted stream ---
	# 4 rows total, offset 2 => 2 rows delivered.
	{
		my $db = Database::test1->new($DATA_DIR);
		my $n = $db->each_row(sub { }, sort_by => 'entry', offset => 2);
		cmp_ok($n, '==', 2, 'T7-5: offset => 2 on 4-row table delivers 2 rows');
	}

	# --- T7-6 : entry criteria filters the stream to matching rows only ---
	# Pass the entry key positionally: get_params('entry', 'one') -> {entry=>'one'}.
	{
		my $db = Database::test1->new($DATA_DIR);
		my $n = $db->each_row(sub { }, $ENTRY_ONE);
		cmp_ok($n, '==', 1, 'T7-6: each_row with entry criteria delivers exactly 1 row');
	}

	# --- T7-7 : (slurp path) callback exception propagates ---
	{
		my $db = Database::test1->new($DATA_DIR);
		$db->count();	# trigger slurp so each_row takes the in-memory path
		my $ex;
		eval {
			$db->each_row(sub { die 'deliberate-stop-slurp' });
		};
		$ex = $@;
		ok($ex =~ /deliberate-stop-slurp/,
		    'T7-7: (slurp) callback exception propagates out of each_row()');
	}

	# --- T7-8 : (slurp path) object is fully usable after a callback exception ---
	{
		my $db = Database::test1->new($DATA_DIR);
		eval { $db->each_row(sub { die 'deliberate-stop' }) };
		lives_ok { $db->count() }
		    'T7-8: (slurp) count() succeeds immediately after callback exception';
	}

	# --- T7-9 : (SQL/DBI path) callback exception propagates ---
	# Force SQL path via max_slurp_size => 0; the DBI eval-catch-rethrow path fires.
	{
		my $db = Database::test1->new(directory => $DATA_DIR, max_slurp_size => 0);
		my $ex;
		eval {
			$db->each_row(sub { die 'deliberate-stop-sql' });
		};
		$ex = $@;
		ok($ex =~ /deliberate-stop-sql/,
		    'T7-9: (SQL path) callback exception propagates out of each_row()');
	}

	# --- T7-10 : (SQL/DBI path) object is fully usable after a callback exception ---
	{
		my $db = Database::test1->new(directory => $DATA_DIR, max_slurp_size => 0);
		eval { $db->each_row(sub { die 'deliberate-stop' }) };
		lives_ok { $db->count() }
		    'T7-10: (SQL path) count() succeeds immediately after callback exception';
	}
}

# ---------------------------------------------------------------------------
# Section 8: base_criteria persistent filter lifecycle
# Walk through every public query method and assert each one applies the
# constructor filter without the caller needing to re-specify it.
# ---------------------------------------------------------------------------
note('Section 8: base_criteria persistent filter lifecycle');

{
	# base_criteria: only rows where number eq '1' pass — that is the 'one' entry.
	# test1.csv numbers: one=>1, two=>2, three=>3, empty=>"".
	my $db_bc = Database::test1->new(
		directory     => $DATA_DIR,
		base_criteria => { number => '1' },
	);

	# T8-1: count() applies the filter — only 1 row matches number=1
	cmp_ok($db_bc->count(), '==', 1,
	    'T8-1: count() respects base_criteria (number=1 => 1 matching row)');

	# T8-2: selectall_arrayref() returns only the 1 matching row
	my $rows = $db_bc->selectall_arrayref();
	cmp_ok(scalar @{$rows}, '==', 1,
	    'T8-2: selectall_arrayref() respects base_criteria');

	# T8-3: fetchrow_hashref for a matching entry returns the row
	my $row_one = $db_bc->fetchrow_hashref($ENTRY_ONE);
	ok(defined $row_one && $row_one->{'number'} == $NUMBER_ONE,
	    'T8-3: fetchrow_hashref(one) returns row when entry matches base_criteria');

	# T8-4: fetchrow_hashref for a non-matching entry returns undef
	# 'two' exists in the table, but its number=2 fails the base_criteria number=1 check.
	my $row_two = $db_bc->fetchrow_hashref($ENTRY_TWO);
	ok(!defined $row_two,
	    'T8-4: fetchrow_hashref(two) returns undef — entry exists but fails base_criteria');

	# T8-5: selectall_array() respects base_criteria
	my @arr = $db_bc->selectall_array();
	cmp_ok(scalar @arr, '==', 1,
	    'T8-5: selectall_array() respects base_criteria');

	# T8-6: each_row() streams only the matching rows
	my $stream_count = 0;
	$db_bc->each_row(sub { $stream_count++ });
	cmp_ok($stream_count, '==', 1,
	    'T8-6: each_row() delivers only base_criteria-matching rows');

	# T8-7: two independent objects with different base_criteria see different data
	my $db_bc1 = Database::test1->new(directory => $DATA_DIR, base_criteria => { number => '1' });
	my $db_bc2 = Database::test1->new(directory => $DATA_DIR, base_criteria => { number => '2' });
	cmp_ok($db_bc1->count(), '==', 1,
	    'T8-7a: db_bc1 (number=1) sees exactly 1 row');
	cmp_ok($db_bc2->count(), '==', 1,
	    'T8-7b: db_bc2 (number=2) sees exactly 1 row, independent of db_bc1');

	# T8-8: query-builder all() respects base_criteria
	my $db_bc3 = Database::test1->new(directory => $DATA_DIR, base_criteria => { number => '1' });
	my $qb_rows = $db_bc3->query()->all();
	cmp_ok(scalar @{$qb_rows}, '==', 1,
	    'T8-8: query builder all() respects base_criteria');

	# T8-9: mutating the caller's hash after construction has no effect on the filter
	# The constructor shallow-copies base_criteria, so the object holds its own copy.
	my %caller_bc = (number => '1');
	my $db_bc_mut = Database::test1->new(directory => $DATA_DIR, base_criteria => \%caller_bc);
	$caller_bc{'number'} = '999';	# mutate caller's copy
	cmp_ok($db_bc_mut->count(), '==', 1,
	    'T8-9: caller mutation of base_criteria hash after construction has no effect');
}

# ---------------------------------------------------------------------------
# Section 9: Schema / columns introspection caching lifecycle
# columns() and schema() each cache their result in the object.  Verify the
# cache is populated on first call and returned verbatim on subsequent calls.
# ---------------------------------------------------------------------------
note('Section 9: schema/columns introspection caching lifecycle');

{
	my $db = Database::test1->new($DATA_DIR);

	# T9-5: _schema and _columns are both undef before any introspection call
	is_deeply([$db->{'_schema'}, $db->{'_columns'}], [undef, undef],
	    'T9-5: _schema and _columns are undef before schema()/columns() first call');

	# T9-1: schema() returns a HASH containing the expected column keys
	my $schema = $db->schema();
	ok(ref($schema) eq 'HASH' && exists($schema->{'entry'}) && exists($schema->{'number'}),
	    'T9-1: schema() returns HASH with expected column keys (entry, number)');

	# T9-2: schema() second call returns the cached reference (same object in memory)
	my $schema2 = $db->schema();
	is("$schema", "$schema2",
	    'T9-2: schema() second call returns cached reference (same memory address)');

	# T9-3: columns() returns a sorted arrayref with the expected column names
	my $cols = $db->columns();
	is_deeply($cols, ['entry', 'number'],
	    'T9-3: columns() returns sorted arrayref [entry, number]');

	# T9-4: columns() second call returns the cached reference
	my $cols2 = $db->columns();
	is("$cols", "$cols2",
	    'T9-4: columns() second call returns cached reference (same memory address)');

	# T9-6: independent objects have independent schema caches (distinct memory)
	my $db_other = Database::test1->new($DATA_DIR);
	$db_other->schema();
	isnt("$schema", "$db_other->{'_schema'}",
	    'T9-6: independent objects hold independent schema caches');
}

# ---------------------------------------------------------------------------
# Section 10: Exception safety across the object lifecycle
# Mid-flight failures must not corrupt the object or leave handles dangling.
# ---------------------------------------------------------------------------
note('Section 10: exception safety across the lifecycle');

{
	# T10-1: passing a non-code-ref to each_row() croaks immediately
	{
		my $db = Database::test1->new($DATA_DIR);
		throws_ok { $db->each_row('not-a-coderef') }
		    qr/callback must be a code reference/i,
		    'T10-1: each_row() with non-code-ref argument croaks immediately';
	}

	# T10-2: (slurp path) callback die is rethrown out of each_row()
	{
		my $db = Database::test1->new($DATA_DIR);
		$db->count();	# trigger slurp
		eval {
			$db->each_row(sub { die 'slurp-kaboom' });
		};
		ok($@ =~ /slurp-kaboom/,
		    'T10-2: (slurp) callback die is rethrown verbatim from each_row()');
	}

	# T10-3: (slurp path) object is immediately usable after callback exception
	{
		my $db = Database::test1->new($DATA_DIR);
		eval { $db->each_row(sub { die 'transient' }) };
		lives_ok { my $c = $db->count() }
		    'T10-3: (slurp) count() succeeds after callback exception — no state corruption';
	}

	# T10-4: (slurp path) callback visit counter reflects rows reached before exception
	# Callback dies on the 2nd invocation; visits should be 2 when exception fires.
	{
		my $db = Database::test1->new($DATA_DIR);
		my $visits = 0;
		eval {
			$db->each_row(sub {
				$visits++;
				die 'stop-after-two' if $visits >= 2;
			});
		};
		cmp_ok($visits, '==', 2,
		    'T10-4: (slurp) visit counter shows exactly 2 rows reached before exception');
	}

	# T10-5: (SQL/DBI path) callback die is rethrown out of each_row()
	{
		my $db = Database::test1->new(directory => $DATA_DIR, max_slurp_size => 0);
		eval {
			$db->each_row(sub { die 'sql-kaboom' });
		};
		ok($@ =~ /sql-kaboom/,
		    'T10-5: (SQL path) callback die is rethrown verbatim from each_row()');
	}

	# T10-6: (SQL/DBI path) object is immediately usable after callback exception
	# The DBI each_row wraps the fetch loop in eval and calls sth->finish() before
	# re-throwing.  A subsequent query must not see a "fetch without execute" error.
	{
		my $db = Database::test1->new(directory => $DATA_DIR, max_slurp_size => 0);
		eval { $db->each_row(sub { die 'transient-sql' }) };
		lives_ok { my $c = $db->count() }
		    'T10-6: (SQL path) count() succeeds after callback exception — sth finished cleanly';
	}

	# T10-7: exception message is preserved verbatim through the rethrow mechanism
	# This guards that the eval-catch-die chain in the DBI path does not mangle $@.
	{
		my $db = Database::test1->new(directory => $DATA_DIR, max_slurp_size => 0);
		my $tag = 'UNIQUE-TAG-98765';
		eval {
			$db->each_row(sub { die $tag });
		};
		ok($@ =~ /$tag/,
		    'T10-7: original exception message preserved through each_row rethrow');
	}
}

# ---------------------------------------------------------------------------
# Section 11: SQLite DBI connection lifecycle
# Walk a DSN-based SQLite object from construction through query and teardown.
# Skipped when DBD::SQLite is not installed.
# ---------------------------------------------------------------------------
note('Section 11: SQLite DBI connection lifecycle');

SKIP: {
	skip 'DBD::SQLite not available', $SQLITE_ROW_COUNT * 2 unless $HAVE_SQLITE;

	# Build a minimal SQLite fixture in a temp directory.
	my $tmpdir11 = File::Temp->newdir(CLEANUP => 1);
	my $db_file  = File::Spec->catfile("$tmpdir11", 'tx11.sql');
	my $dsn      = "dbi:SQLite:dbname=$db_file";

	{
		package Database::tx11;
		use base 'Database::Abstraction';
	}

	my $setup = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
	$setup->do('CREATE TABLE tx11 (entry TEXT PRIMARY KEY, score INTEGER)');
	my $ins = $setup->prepare('INSERT INTO tx11 VALUES (?,?)');
	$ins->execute('alpha', 10);
	$ins->execute('beta',  20);
	$ins->execute('gamma', 30);
	$setup->disconnect();

	my $db11 = Database::tx11->new(dsn => $dsn);

	# T11-1: count() returns the expected row count
	cmp_ok($db11->count(), '==', $SQLITE_ROW_COUNT,
	    'T11-1: SQLite count() == 3 after first query on DSN connection');

	# T11-2: DBI handle is established in the object after the first query
	ok(defined $db11->{'tx11'} && $db11->{'tx11'}->isa('DBI::db'),
	    'T11-2: DBI handle is a DBI::db object after open');

	# T11-3: selectall_arrayref returns the correct number of rows
	my $sql_rows = $db11->selectall_arrayref();
	cmp_ok(scalar @{$sql_rows}, '==', $SQLITE_ROW_COUNT,
	    'T11-3: selectall_arrayref() returns all 3 SQLite rows');

	# T11-4: repeated queries are idempotent — count is identical on both calls
	my $c_a = $db11->count();
	my $c_b = $db11->count();
	cmp_ok($c_a, '==', $c_b,
	    'T11-4: SQLite count() is idempotent across two consecutive calls');

	# T11-5: schema() introspects column types via PRAGMA table_info
	my $sq_schema = $db11->schema();
	ok(ref($sq_schema) eq 'HASH'
	    && exists($sq_schema->{'entry'})
	    && exists($sq_schema->{'score'})
	    && ($sq_schema->{'score'}{'type'} // '') eq 'INTEGER',
	    'T11-5: schema() returns HASH with entry/score columns; score type is INTEGER');

	# T11-6: DESTROY disconnects and clears the DBI handle from the object
	$db11->DESTROY();
	ok(!defined $db11->{'tx11'},
	    'T11-6: DBI handle cleared from object state after DESTROY');
}
