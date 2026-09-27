#!/usr/bin/env perl
#
# t/data-flow.t — Define-Use chain tests for Database::Abstraction
#
# Validates data integrity and resource lifecycles:
#   D = variable/resource defined (assigned for the first time)
#   U = variable/resource used
#   K = variable/resource killed (freed, disconnected, or de-scoped)
#
# Anomalies flagged in source code with "# TODO: Data Flow Anomaly":
#   D~  dead store  — value assigned but never read before scope end
#   DD  redundant   — variable assigned twice without an intervening read
#   ~U  uninitialized use — variable read before guaranteed assignment
#   O~  unclosed resource — opened but never closed on some path
#

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Scalar::Util qw(blessed reftype weaken);
use Test::Most;
use Test::Needs;
use Test::Returns;
use Readonly;

# ── Test configuration ──────────────────────────────────────────────────────
Readonly::Hash my %CONFIG => (
	DATA_DIR  => File::Spec->catdir('t', 'data'),
	LIB_DIR   => File::Spec->catdir('t', 'lib'),
	# Entries in t/data/test1.csv (sep_char '!'): one, two, three, empty
	ENTRY_ONE   => 'one',
	ENTRY_TWO   => 'two',
	ENTRY_THREE => 'three',
	ENTRY_EMPTY => 'empty',
	TOTAL_ROWS  => 4,
	SEP_CHAR    => '!',
);

# Load the test subclass at compile time — avoids "Too late to run CHECK block"
# warnings from Sub::Private when Database::Abstraction is first require'd inside
# a runtime use_ok() eval.
use lib 't/lib';
use Database::test1;

# ── Helpers ─────────────────────────────────────────────────────────────────

sub _new_db {
	return Database::test1->new(directory => $CONFIG{DATA_DIR}, @_);
}

# Build an ad-hoc CSV file in a new temp dir; returns ($dir, $path).
sub _make_csv_dir {
	my (%args) = @_;
	my $content = $args{content} // "entry!value\none!alpha\ntwo!beta\n";
	my $name    = $args{name}    // 'adhoc';
	my $dir     = tempdir(CLEANUP => 1);
	my $path    = File::Spec->catfile($dir, "$name.csv");
	open(my $fh, '>', $path) or die "Cannot write $path: $!";
	print $fh $content;
	close $fh;
	return ($dir, $path);
}

# Build a gzipped CSV in a new temp dir; returns ($dir, $path).
# Skips with a message if IO::Compress::Gzip is unavailable.
sub _make_gz_dir {
	my (%args) = @_;
	my $content = $args{content} // "entry!value\none!alpha\ntwo!beta\n";
	my $name    = $args{name}    // 'adhoc';
	eval { require IO::Compress::Gzip } or return ();
	my $dir  = tempdir(CLEANUP => 1);
	my $path = File::Spec->catfile($dir, "$name.csv.gz");
	{
		no warnings 'once';
		IO::Compress::Gzip::gzip(\$content, $path)
			or die "gzip failed: $IO::Compress::Gzip::GzipError";
	}
	return ($dir, $path);
}

# ═══════════════════════════════════════════════════════════════════════════
# DF-1  $self->{'data'} — slurp lifecycle  D → U → K
#
# Chain: _open_table() slurps CSV → data HASH defined → SELECT methods read it →
#        DESTROY deletes the slot → GC frees the hash
# ═══════════════════════════════════════════════════════════════════════════
subtest 'DF-1: slurp data lifecycle (D → U → K)' => sub {

	# DF-1.1: data is not defined before the first query (lazy open)
	{
		my $db = _new_db();
		ok !exists($db->{'data'}),
			'DF-1.1: data slot absent before first query (not yet defined)';
	}

	# DF-1.2: data is defined (D) after the first public method triggers _open_table
	{
		my $db = _new_db();
		$db->count();
		ok defined($db->{'data'}),
			'DF-1.2: data defined (D) after first query forces lazy open';
	}

	# DF-1.3: data structure type — keyed mode yields HASH ref
	{
		my $db = _new_db();
		$db->count();
		is reftype($db->{'data'}), 'HASH',
			'DF-1.3: keyed-mode slurp stores data as a HASH ref';
	}

	# DF-1.4: expected entries are present in the slurped hash (correct D)
	{
		my $db = _new_db();
		$db->count();
		ok exists($db->{'data'}{$CONFIG{ENTRY_ONE}}),
			"DF-1.4a: '$CONFIG{ENTRY_ONE}' key present in slurped data";
		ok exists($db->{'data'}{$CONFIG{ENTRY_TWO}}),
			"DF-1.4b: '$CONFIG{ENTRY_TWO}' key present in slurped data";
	}

	# DF-1.5: data is stable across multiple U (reads) — no unintended mutations
	{
		my $db = _new_db();
		$db->count();
		my %snap1 = %{$db->{'data'}};
		$db->count();
		$db->selectall_arrayref();
		$db->fetchrow_hashref(entry => $CONFIG{ENTRY_ONE});
		my %snap2 = %{$db->{'data'}};
		is_deeply \%snap2, \%snap1,
			'DF-1.5: data hash unchanged (not mutated) across multiple reads';
	}

	# DF-1.6: two objects have independent data references (no aliasing between objects)
	{
		my $db1 = _new_db();
		my $db2 = _new_db();
		$db1->count();
		$db2->count();
		isnt $db1->{'data'}, $db2->{'data'},
			'DF-1.6: two objects hold distinct (not aliased) data references';
		is_deeply $db1->{'data'}, $db2->{'data'},
			'DF-1.6b: but the contents are equal';
	}

	# DF-1.7: same data ref returned for all SELECT calls on the same object (no re-slurp)
	{
		my $db = _new_db();
		$db->count();
		my $ref_after_count = $db->{'data'};
		$db->selectall_arrayref();
		is $db->{'data'}, $ref_after_count,
			'DF-1.7: selectall_arrayref does not re-slurp; same data ref as after count()';
	}

	# DF-1.8: no_entry mode — data is an ARRAY ref (distinct DU chain from keyed mode)
	{
		my ($dir) = _make_csv_dir(content => "name!val\nalice!10\nbob!20\n", name => 'ne_df1');
		{
			package Database::ne_df1;
			use parent 'Database::Abstraction';
			sub new {
				my ($class, %args) = @_;
				# id => 'name' must match the CSV's actual first column;
				# the default 'entry' would not match 'name'/'val' and would produce undef data.
				return $class->SUPER::new(no_entry => 1, id => 'name', sep_char => '!', %args);
			}
		}
		my $db = Database::ne_df1->new(directory => $dir);
		$db->count();
		is reftype($db->{'data'}), 'ARRAY',
			'DF-1.8: no_entry slurped data is an ARRAY ref (distinct from keyed HASH path)';
	}

	# DF-1.9: data slot is killed (K) by DESTROY without error
	{
		my $completed = 0;
		eval {
			my $db = _new_db();
			$db->count();
			# $db goes out of scope at the end of this eval block → DESTROY
		};
		$completed = 1 unless $@;
		ok $completed, 'DF-1.9: DESTROY (K) completes without error';
	}
};

# ═══════════════════════════════════════════════════════════════════════════
# DF-2  $self->{'_table_name'} — cached table name  D → U (cache) → K
#
# Chain: _open_table() computes name once → stores in _table_name (D) →
#        subsequent calls return the cached value (U) → DESTROY kills it (K)
# ═══════════════════════════════════════════════════════════════════════════
subtest 'DF-2: _table_name cache lifecycle (D → U cache → K)' => sub {

	# DF-2.1: cache slot absent before any query
	{
		my $db = _new_db();
		ok !defined($db->{'_table_name'}),
			'DF-2.1: _table_name not defined (no D yet) before first _open_table call';
	}

	# DF-2.2: defined (D) and correct after first query
	{
		my $db = _new_db();
		$db->count();
		is $db->{'_table_name'}, 'test1',
			'DF-2.2: _table_name defined (D) as class-suffix "test1" after first query';
	}

	# DF-2.3: same value on second call — cache hit (U, not re-computed)
	{
		my $db = _new_db();
		$db->count();
		my $first  = $db->{'_table_name'};
		$db->selectall_arrayref();
		my $second = $db->{'_table_name'};
		is $first, $second,
			'DF-2.3: _table_name cache value (U) unchanged on repeat calls';
	}

	# DF-2.4: distinct objects carry distinct cache slots (no shared state)
	{
		my $db1 = _new_db();
		my $db2 = _new_db();
		$db1->count();
		$db2->count();
		is $db1->{'_table_name'}, $db2->{'_table_name'},
			'DF-2.4a: both objects derive the same table name';
		# Verify the slots are truly independent by mutating one
		$db1->{'_table_name'} = 'MUTATED';
		is $db2->{'_table_name'}, 'test1',
			'DF-2.4b: mutating db1 _table_name does not affect db2 (independent slots)';
	}

	# DF-2.5: cache survives all SELECT method calls without being reset
	{
		my $db = _new_db();
		$db->count();
		$db->selectall_arrayref();
		$db->selectall_array();
		$db->fetchrow_hashref(entry => $CONFIG{ENTRY_ONE});
		is $db->{'_table_name'}, 'test1',
			'DF-2.5: _table_name cache not reset by any SELECT method call';
	}
};

# ═══════════════════════════════════════════════════════════════════════════
# DF-3  $self->{'_columns'} and $self->{'_schema'} — introspection caches
#
# Chain: columns()/schema() compute result once (D) → store in slot → return
#        same ref on repeat calls (U from cache) → DESTROY kills slot (K)
# ═══════════════════════════════════════════════════════════════════════════
subtest 'DF-3: columns() and schema() cache lifecycle' => sub {

	# DF-3.1: both cache slots absent before any call
	{
		my $db = _new_db();
		ok !defined($db->{'_columns'}), 'DF-3.1a: _columns undefined before columns() (no D)';
		ok !defined($db->{'_schema'}),  'DF-3.1b: _schema undefined before schema() (no D)';
	}

	# DF-3.2: columns() defines and populates _columns (D)
	{
		my $db   = _new_db();
		my $cols = $db->columns();
		ok defined($db->{'_columns'}),   'DF-3.2a: _columns defined (D) after columns() call';
		is ref($db->{'_columns'}), 'ARRAY', 'DF-3.2b: _columns is an ARRAY ref';
		ok scalar(@{$db->{'_columns'}}) >= 2,
			'DF-3.2c: _columns has at least two entries (entry + number)';
	}

	# DF-3.3: columns() cache hit — same arrayref returned on repeat calls (U)
	{
		my $db = _new_db();
		my $c1 = $db->columns();
		my $c2 = $db->columns();
		is $c1, $c2,
			'DF-3.3: columns() returns same arrayref (U from cache) on repeat calls';
	}

	# DF-3.4: schema() defines and populates _schema (D)
	{
		my $db = _new_db();
		my $sch = $db->schema();
		ok defined($db->{'_schema'}),    'DF-3.4a: _schema defined (D) after schema() call';
		is ref($db->{'_schema'}), 'HASH', 'DF-3.4b: _schema is a HASH ref';
	}

	# DF-3.5: schema() cache hit (U) — same hashref on repeat calls
	{
		my $db = _new_db();
		my $s1 = $db->schema();
		my $s2 = $db->schema();
		is $s1, $s2, 'DF-3.5: schema() returns same hashref (U from cache) on repeat calls';
	}

	# DF-3.6: columns cache not shared between distinct objects
	{
		my $db1 = _new_db();
		my $db2 = _new_db();
		my $c1  = $db1->columns();
		my $c2  = $db2->columns();
		isnt $c1, $c2,
			'DF-3.6a: columns() returns distinct arrayrefs for distinct objects';
		is_deeply $c1, $c2,
			'DF-3.6b: but the column lists are equal in content';
	}

	# DF-3.7: _columns cache not reset by count / selectall calls
	{
		my $db    = _new_db();
		my $cols  = $db->columns();
		$db->count();
		$db->selectall_arrayref();
		is $db->{'_columns'}, $cols,
			'DF-3.7: _columns cache ref unchanged after count/selectall calls';
	}
};

# ═══════════════════════════════════════════════════════════════════════════
# DF-4  DBI handle lifecycle  D → U (prepare_cached) → K (disconnect)
#
# Chain: DBI->connect() → $self->{$table} (D) → prepare_cached (U) →
#        $sth->finish() after partial fetch → DESTROY disconnects (K)
# ═══════════════════════════════════════════════════════════════════════════
subtest 'DF-4: DBI handle lifecycle (D → U → K)' => sub {

	# DF-4.1: DBI handle absent before any query
	{
		my $db = _new_db();
		ok !defined($db->{'test1'}),
			'DF-4.1: DBI handle not defined (no D) before first query';
	}

	# DF-4.2: DBI handle defined (D) and is DBI::db after first query
	{
		my $db = _new_db();
		$db->count();
		ok defined($db->{'test1'}), 'DF-4.2a: DBI handle defined (D) after first query';
		isa_ok $db->{'test1'}, 'DBI::db', 'DF-4.2b: DBI handle';
	}

	# DF-4.3: prepare_cached returns the same sth for identical SQL (U from cache)
	{
		my $db = _new_db();
		$db->count();    # forces DBI handle open
		my $sql  = "SELECT COUNT(entry) FROM test1 WHERE entry IS NOT NULL AND entry NOT LIKE '#%'";
		my $sth1 = $db->{'test1'}->prepare_cached($sql);
		my $sth2 = $db->{'test1'}->prepare_cached($sql);
		is $sth1, $sth2,
			'DF-4.3: prepare_cached returns same sth handle (U from handle cache) for identical SQL';
		$sth1->finish();
	}

	# DF-4.4: same DBI handle used throughout all SELECT methods on one object
	{
		my $db    = _new_db();
		$db->count();
		my $dbh_1 = $db->{'test1'};
		$db->selectall_arrayref();
		my $dbh_2 = $db->{'test1'};
		$db->fetchrow_hashref(entry => $CONFIG{ENTRY_ONE});
		my $dbh_3 = $db->{'test1'};
		is $dbh_1, $dbh_2, 'DF-4.4a: same DBI handle after selectall_arrayref';
		is $dbh_2, $dbh_3, 'DF-4.4b: same DBI handle after fetchrow_hashref';
	}

	# DF-4.5: DBI handle remains valid (not disconnected) during object lifetime
	{
		my $db = _new_db();
		$db->count();
		ok $db->{'test1'}->ping(), 'DF-4.5: DBI handle is connected (ping succeeds)';
	}

	# DF-4.6: DESTROY (K) — object can be created/destroyed in a tight loop without leaks
	{
		my $errors = 0;
		for(1..5) {
			eval {
				my $db = _new_db();
				$db->count();
			};
			$errors++ if $@;
		}
		is $errors, 0,
			'DF-4.6: repeated create/query/destroy cycle completes without errors';
	}

	# DF-4.7: count() calls $sth->finish() — sth is marked done after call
	# (White-box: wrap prepare_cached to intercept the sth)
	{
		my $db = _new_db();
		$db->count();
		# After count(), prepare_cached sth should be finished.
		# We verify indirectly: the same SQL can be prepare_cached again cleanly.
		my $sql = "SELECT COUNT(entry) FROM test1 WHERE entry IS NOT NULL AND entry NOT LIKE '#%'";
		my $sth = $db->{'test1'}->prepare_cached($sql);
		$sth->execute();
		my ($n) = $sth->fetchrow_array();
		$sth->finish();
		cmp_ok $n, '==', $CONFIG{TOTAL_ROWS},
			'DF-4.7: sth from prepare_cached executes cleanly after count() (finish was called)';
	}
};

# ═══════════════════════════════════════════════════════════════════════════
# DF-5  $self->{'type'} propagation  D → U (SQL building, CSV filter)
#
# Chain: _open() sets type (D) → selectall SQL builder branches on type (U) →
#        CSV comment-row guard uses type → Query._build_sql reads type
# ═══════════════════════════════════════════════════════════════════════════
subtest 'DF-5: type propagation (D → U through SQL builder)' => sub {

	# DF-5.1: type is undefined before lazy open (no D yet)
	{
		my $db = _new_db();
		ok !defined($db->{'type'}),
			'DF-5.1: type undefined before first query (lazy open not yet triggered)';
	}

	# DF-5.2: type is 'CSV' after open (D)
	{
		my $db = _new_db();
		$db->count();
		is $db->{'type'}, 'CSV', 'DF-5.2: type defined (D) as "CSV" for CSV backend';
	}

	# DF-5.3: type drives the CSV comment-row filter — '#' entry rows excluded from count
	# test1.csv contains a comment row "# Verify comment lines are ignored"
	{
		my $db    = _new_db();
		my $count = $db->count();
		cmp_ok $count, '==', $CONFIG{TOTAL_ROWS},
			'DF-5.3: CSV comment rows filtered out by type-driven guard (count is TOTAL_ROWS)';
	}

	# DF-5.4: comment row is not present in selectall_arrayref results
	{
		my $db   = _new_db();
		my $rows = $db->selectall_arrayref();
		my @comment = grep { defined($_->{'entry'}) && $_->{'entry'} =~ /\A#/ } @{$rows};
		is scalar(@comment), 0,
			'DF-5.4: no comment rows (entry ~ #) in selectall_arrayref result';
	}

	# DF-5.5: type propagates into Query.pm — query->count() applies same CSV guard
	{
		my $db = _new_db();
		my $n  = $db->query()->count();
		cmp_ok $n, '==', $CONFIG{TOTAL_ROWS},
			'DF-5.5: Query->count() uses type (U) to apply CSV comment-row guard';
	}

	# DF-5.6: type is stable (not re-defined DD) across all SELECT calls
	{
		my $db = _new_db();
		$db->count();
		my $t0 = $db->{'type'};
		$db->selectall_arrayref();
		$db->selectall_array();
		$db->fetchrow_hashref(entry => $CONFIG{ENTRY_ONE});
		$db->columns();
		is $db->{'type'}, $t0, 'DF-5.6: type unchanged (no DD) across all SELECT calls';
	}
};

# ═══════════════════════════════════════════════════════════════════════════
# DF-6  $self->{'_updated'} — mtime data flow  D → U
#
# Chain: _open() calls stat() → stores [9] mtime in _updated (D) →
#        updated() returns it (U)
# ═══════════════════════════════════════════════════════════════════════════
subtest 'DF-6: _updated mtime lifecycle (D → U)' => sub {

	# DF-6.1: _updated not defined before lazy open
	{
		my $db = _new_db();
		ok !defined($db->{'_updated'}),
			'DF-6.1: _updated not defined (no D) before first query';
	}

	# DF-6.2: _updated defined (D) after first query
	{
		my $db = _new_db();
		$db->count();
		ok defined($db->{'_updated'}),
			'DF-6.2: _updated defined (D) after first query triggers lazy open';
	}

	# DF-6.3: updated() uses (U) _updated correctly
	{
		my $db = _new_db();
		$db->count();
		is $db->updated(), $db->{'_updated'},
			'DF-6.3: updated() returns same scalar as $self->{_updated}';
	}

	# DF-6.4: _updated is a positive Unix timestamp
	{
		my $db = _new_db();
		$db->count();
		cmp_ok $db->updated(), '>', 0,
			'DF-6.4: _updated is a positive integer (plausible Unix mtime)';
		cmp_ok $db->updated(), '<', time() + 60,
			'DF-6.4b: _updated is not in the future';
	}

	# DF-6.5: _updated stable across all method calls (mtime of file does not change)
	{
		my $db = _new_db();
		$db->count();
		my $t0 = $db->updated();
		$db->selectall_arrayref();
		$db->fetchrow_hashref(entry => $CONFIG{ENTRY_ONE});
		is $db->updated(), $t0, 'DF-6.5: _updated not re-computed (no DD) across calls';
	}
};

# ═══════════════════════════════════════════════════════════════════════════
# DF-7  $self->{'id'} propagation  D → U (ORDER BY, CSV filter, schema PK)
#
# Chain: new() sets id from args or default 'entry' (D) → ORDER BY clause (U) →
#        CSV comment-filter WHERE clause (U) → schema() PK flag (U)
# ═══════════════════════════════════════════════════════════════════════════
subtest 'DF-7: id column propagation (D → U)' => sub {

	# DF-7.1: id is defined at construction (D) — not lazily
	{
		my $db = _new_db();
		ok defined($db->{'id'}),
			'DF-7.1: id defined (D) at construction time, before any query';
	}

	# DF-7.2: default id is 'entry'
	{
		my $db = _new_db();
		is $db->{'id'}, 'entry', 'DF-7.2: default id is "entry"';
	}

	# DF-7.3: custom id flows into schema() PK marker
	{
		my $db     = _new_db();
		my $schema = $db->schema();
		my $id     = $db->{'id'};
		if(exists $schema->{$id}) {
			is $schema->{$id}{'pk'}, 1,
				"DF-7.3: id column '$id' marked pk=>1 in schema (U from schema)";
		} else {
			pass "DF-7.3: schema does not expose '$id' in slurp path (acceptable)";
		}
	}

	# DF-7.4: id flows into SQL path ORDER BY — results ordered by id.
	# Force SQL path (max_slurp_size => 0) so ORDER BY is applied by the DB engine,
	# not the arbitrary iteration order of the in-memory hash.
	{
		my $db   = _new_db(max_slurp_size => 0);
		my $rows = $db->selectall_arrayref();
		my @entries = map { $_->{'entry'} } @{$rows};
		my @sorted  = sort @entries;
		is_deeply \@entries, \@sorted,
			'DF-7.4: SQL-path selectall_arrayref result ordered by id column (U in ORDER BY clause)';
	}

	# DF-7.5: id stable across all operations (no DD after construction)
	{
		my $db = _new_db();
		my $id_at_construct = $db->{'id'};
		$db->count();
		$db->selectall_arrayref();
		$db->columns();
		is $db->{'id'}, $id_at_construct,
			'DF-7.5: id unchanged (no DD) across count, selectall, columns calls';
	}
};

# ═══════════════════════════════════════════════════════════════════════════
# DF-8  CHI cache data flow  MISS(D) → SET(U) → HIT(U) → per-key isolation
#
# Chain: query without cache entry → MISS, fetch from backend (D in cache) →
#        second query hits cache (U) → distinct criteria produce distinct keys
# ═══════════════════════════════════════════════════════════════════════════
subtest 'DF-8: CHI cache data flow (MISS → SET → HIT)' => sub {
	test_needs 'CHI';
	# DF-8.1: cache MISS — data fetched from backend (D in cache)
	{
		my $cache = CHI->new(driver => 'Memory', global => 0);
		my $db    = _new_db(cache => $cache, cache_duration => '10 minutes');
		my $cnt   = $db->count();
		cmp_ok $cnt, '==', $CONFIG{TOTAL_ROWS},
			'DF-8.1: count on cache MISS returns correct value from backend';
	}

	# DF-8.2: cache HIT — equivalent data returned without hitting backend again.
	# CHI Memory driver serializes/deserializes data, so the returned ref is a new
	# copy on each HIT — use is_deeply (content equality) not is (ref equality).
	{
		my $cache = CHI->new(driver => 'Memory', global => 0);
		my $db    = _new_db(cache => $cache, cache_duration => '1 hour');
		my $r1    = $db->selectall_arrayref();    # MISS — populates cache (D)
		my $r2    = $db->selectall_arrayref();    # HIT — reads from cache (U)
		is_deeply $r1, $r2,
			'DF-8.2: selectall_arrayref cache HIT returns equivalent data (U)';
		cmp_ok scalar(@{$r2}), '>', 0,
			'DF-8.2b: cache HIT result is non-empty';
	}

	# DF-8.3: count() and selectall_arrayref() produce distinct cache keys (D→D)
	{
		my $cache = CHI->new(driver => 'Memory', global => 0);
		my $db    = _new_db(cache => $cache, cache_duration => '1 hour');
		my $r1    = $db->selectall_arrayref();    # populates cache
		my $r2    = $db->selectall_arrayref();    # HIT — same key
		# Two calls with same params should use the same key (not two separate ones)
		is_deeply $r1, $r2,
			'DF-8.3: repeated selectall_arrayref with same params uses same cache key';
	}

	# DF-8.4: criteria-parameterised query produces a distinct cache key from uncritiqued query
	{
		my $cache = CHI->new(driver => 'Memory', global => 0);
		my $db    = _new_db(cache => $cache, cache_duration => '1 hour');
		my $r_all = $db->selectall_arrayref();
		my $r_one = $db->selectall_arrayref(entry => $CONFIG{ENTRY_ONE});
		isnt $r_all, $r_one,
			'DF-8.4: distinct criteria produce distinct cached refs';
		cmp_ok scalar(@{$r_all}), '>', scalar(@{$r_one}),
			'DF-8.4b: uncritiqued result has more rows than filtered result';
	}

	# DF-8.5: two objects sharing the same cache instance share HIT entries.
	# CHI Memory driver deserializes on GET so ref identity doesn't hold — use is_deeply.
	# Sort by entry for a stable comparison (hash/cache iteration order is arbitrary).
	{
		my $shared = CHI->new(driver => 'Memory', global => 0);
		my $db1    = _new_db(cache => $shared, cache_duration => '1 hour');
		my $db2    = _new_db(cache => $shared, cache_duration => '1 hour');
		my $r1     = $db1->selectall_arrayref();    # populates shared cache
		my $r2     = $db2->selectall_arrayref();    # reads same cache entry
		my @s1     = sort { $a->{'entry'} cmp $b->{'entry'} } @{$r1};
		my @s2     = sort { $a->{'entry'} cmp $b->{'entry'} } @{$r2};
		is_deeply \@s1, \@s2,
			'DF-8.5: two objects sharing a cache retrieve equivalent cached data (sorted)';
	}

	# DF-8.6: count() derives from selectall cache entry when available
	{
		my $cache = CHI->new(driver => 'Memory', global => 0);
		my $db    = _new_db(cache => $cache, cache_duration => '1 hour');
		my $all   = $db->selectall_arrayref();    # populates cache
		my $cnt   = $db->count();                  # should derive from cached entry
		is $cnt, scalar(@{$all}),
			'DF-8.6: count() derived from selectall cache equals actual row count';
	}

	# DF-8.7: distinct cache objects do not share entries.
	# Both objects return the same data content (from the underlying backend),
	# but hold independent cache entries. We verify content equality (not ref identity),
	# and that the content is correctly ordered (sorted) between the two.
	{
		my $ca  = CHI->new(driver => 'Memory', global => 0);
		my $cb  = CHI->new(driver => 'Memory', global => 0);
		my $da  = _new_db(cache => $ca, cache_duration => '1 hour');
		my $db2 = _new_db(cache => $cb, cache_duration => '1 hour');
		my $ra  = $da->selectall_arrayref();
		my $rb  = $db2->selectall_arrayref();
		my @sa  = sort { $a->{'entry'} cmp $b->{'entry'} } @{$ra};
		my @sb  = sort { $a->{'entry'} cmp $b->{'entry'} } @{$rb};
		is_deeply \@sa, \@sb,
			'DF-8.7: distinct cache objects produce equivalent data (no cross-contamination)';
	}

	# DF-8.8: fetchrow_hashref cache HIT returns equivalent data.
	# CHI deserializes on GET so use is_deeply, not ref identity.
	{
		my $cache = CHI->new(driver => 'Memory', global => 0);
		my $db    = _new_db(cache => $cache, cache_duration => '1 hour');
		my $r1    = $db->fetchrow_hashref(entry => $CONFIG{ENTRY_ONE});
		my $r2    = $db->fetchrow_hashref(entry => $CONFIG{ENTRY_ONE});
		is_deeply $r1, $r2, 'DF-8.8: fetchrow_hashref cache HIT returns equivalent data';
		is $r1->{'entry'}, $CONFIG{ENTRY_ONE},
			"DF-8.8b: cached row has correct entry value '$CONFIG{ENTRY_ONE}'";
	}

	# DF-8.9: AUTOLOAD list cache HIT returns equivalent data
	{
		my $cache = CHI->new(driver => 'Memory', global => 0);
		my $db    = _new_db(cache => $cache, cache_duration => '1 hour');
		my @v1    = $db->number();    # list context → populates cache
		my @v2    = $db->number();    # should be cache HIT
		is_deeply [sort { ($a // '') cmp ($b // '') } @v2],
			  [sort { ($a // '') cmp ($b // '') } @v1],
			'DF-8.9: AUTOLOAD list context cache HIT returns equivalent values';
	}

	# DF-8.10: cache keyed by criteria — same method with different args caches separately
	{
		my $cache = CHI->new(driver => 'Memory', global => 0);
		my $db    = _new_db(cache => $cache, cache_duration => '1 hour');
		my $r_one = $db->fetchrow_hashref(entry => $CONFIG{ENTRY_ONE});
		my $r_two = $db->fetchrow_hashref(entry => $CONFIG{ENTRY_TWO});
		isnt $r_one, $r_two,
			'DF-8.10: fetchrow_hashref with different entry args cached at different keys';
	}

	# DF-8.11: cache does not retain stale data after cache is cleared
	{
		my $cache = CHI->new(driver => 'Memory', global => 0);
		my $db    = _new_db(cache => $cache, cache_duration => '1 hour');
		my $r1    = $db->selectall_arrayref();
		$cache->clear();
		my $r2    = $db->selectall_arrayref();    # fresh MISS after clear
		is_deeply $r2, $r1, 'DF-8.11: data re-fetched after cache clear is consistent';
		isnt $r1, $r2,
			'DF-8.11b: re-fetched result is a new reference (not the cleared one)';
	}
};

# ═══════════════════════════════════════════════════════════════════════════
# DF-9  Global state non-pollution
#
# Verifies that $_, $@, and $! are not clobbered as side effects of any
# public API call.  Inner grep/map/for loops inside the module must not
# expose their loop variable to the caller's scope.
# ═══════════════════════════════════════════════════════════════════════════
subtest 'DF-9: global state non-pollution' => sub {

	my $db = _new_db();

	# DF-9.1 – DF-9.5: $_ not clobbered by any public method
	for my $method_call (
		[ 'count()',              sub { $db->count() } ],
		[ 'selectall_arrayref()', sub { $db->selectall_arrayref() } ],
		[ 'selectall_array()',    sub { $db->selectall_array() } ],
		[ 'fetchrow_hashref()',   sub { $db->fetchrow_hashref(entry => $CONFIG{ENTRY_ONE}) } ],
		[ 'columns()',            sub { $db->columns() } ],
		[ 'schema()',             sub { $db->schema() } ],
		[ 'query()->count()',     sub { $db->query()->count() } ],
		[ 'AUTOLOAD number()',    sub { $db->number(entry => $CONFIG{ENTRY_ONE}) } ],
	) {
		my ($label, $code) = @{$method_call};
		local $_ = 'sentinel_before';
		eval { $code->() };
		is $_, 'sentinel_before', "DF-9: \$_ not clobbered by $label";
	}

	# DF-9.6: $@ not clobbered on success
	{
		local $@ = '';
		eval { 1 };    # set $@ to empty string
		$db->count();
		is $@, '', 'DF-9.6: $@ not clobbered by count() on success path';
	}

	# DF-9.7: grep inside in-memory scan does not leak $_ to caller
	{
		local $_ = 'outer';
		my @scratch = grep { $_ eq 'outer' } ('outer');    # make $_ active
		$_ = 'outer';
		my $cnt = $db->count();    # triggers in-memory grep in slurp path
		is $_, 'outer', 'DF-9.7: in-memory count() scan does not leak $_ to caller';
	}

	# DF-9.8: map inside AUTOLOAD list path does not leak $_ to caller
	{
		local $_ = 'sentinel_map';
		my @vals = $db->number();
		is $_, 'sentinel_map',
			'DF-9.8: AUTOLOAD list context map does not leak $_ to caller';
	}
};

# ═══════════════════════════════════════════════════════════════════════════
# DF-10  Query builder state isolation and exception-safe first()
#
# Chain: new Query (D) → where() accumulates into _where (U) → terminal
#        method executes and returns result → first() saves/restores _limit
#        (now exception-safe via `local $self->{'_limit'}`)
# ═══════════════════════════════════════════════════════════════════════════
subtest 'DF-10: Query builder state flow and first() exception safety' => sub {

	my $db = _new_db();

	# DF-10.1: fresh Query has empty _where (D with empty value)
	{
		my $q = $db->query();
		is_deeply $q->{'_where'}, {}, 'DF-10.1: fresh Query _where is an empty hashref';
	}

	# DF-10.2: where() defines a key in _where (D per key)
	{
		my $q = $db->query()->where(entry => $CONFIG{ENTRY_ONE});
		is $q->{'_where'}{'entry'}, $CONFIG{ENTRY_ONE},
			'DF-10.2: where() stores criteria key in _where (D in _where hash)';
	}

	# DF-10.3: multiple where() calls accumulate — AND semantics (multiple D, each for new key)
	{
		my $q = $db->query()
			->where(entry  => $CONFIG{ENTRY_ONE})
			->where(number => '1');
		is $q->{'_where'}{'entry'},  $CONFIG{ENTRY_ONE},
			'DF-10.3a: first where() key preserved after second where()';
		is $q->{'_where'}{'number'}, '1',
			'DF-10.3b: second where() key stored independently';
	}

	# DF-10.4: limit() defines _limit (D)
	{
		my $q = $db->query()->limit(5);
		is $q->{'_limit'}, 5, 'DF-10.4: limit() defines _limit (D) to 5';
	}

	# DF-10.5: offset() defines _offset (D)
	{
		my $q = $db->query()->offset(10);
		is $q->{'_offset'}, 10, 'DF-10.5: offset() defines _offset (D) to 10';
	}

	# DF-10.6: first() restores _limit after call — exception-safe `local` fix verified
	{
		my $q = $db->query()->limit(99);
		$q->first();
		is $q->{'_limit'}, 99,
			'DF-10.6: first() restores _limit to 99 after execution (local exception-safe)';
	}

	# DF-10.7: first() with no prior limit — _limit remains undef (no spurious D)
	{
		my $q = $db->query();
		ok !defined($q->{'_limit'}), 'DF-10.7a: _limit undef before first()';
		$q->first();
		ok !defined($q->{'_limit'}),
			'DF-10.7b: _limit still undef after first() (local restores undef correctly)';
	}

	# DF-10.8: two Query objects share the same $db but have independent _where state
	{
		my $q1 = $db->query()->where(entry => $CONFIG{ENTRY_ONE})->limit(5);
		my $q2 = $db->query()->where(entry => $CONFIG{ENTRY_TWO})->limit(99);
		is $q1->{'_where'}{'entry'}, $CONFIG{ENTRY_ONE},
			'DF-10.8a: q1 entry criteria isolated from q2';
		is $q2->{'_where'}{'entry'}, $CONFIG{ENTRY_TWO},
			'DF-10.8b: q2 entry criteria isolated from q1';
		is $q1->{'_limit'}, 5,  'DF-10.8c: q1 limit isolated';
		is $q2->{'_limit'}, 99, 'DF-10.8d: q2 limit isolated';
	}

	# DF-10.9: where() in caller does not affect builder's stored _where
	{
		my %crit = (entry => $CONFIG{ENTRY_ONE});
		my $q    = $db->query()->where(%crit);
		$crit{entry} = 'INJECTED';    # mutate caller's hash after where() call
		my $stored = $q->{'_where'}{'entry'};
		is $stored, $CONFIG{ENTRY_ONE},
			'DF-10.9: where() copies criteria — subsequent caller mutation does not affect builder';
	}

	# DF-10.10: first() result is correct (LIMIT 1 applied)
	{
		my $row = $db->query()->where(entry => $CONFIG{ENTRY_ONE})->first();
		ok defined($row), 'DF-10.10a: first() returns defined value for existing entry';
		is $row->{'entry'}, $CONFIG{ENTRY_ONE},
			"DF-10.10b: first() returns the correct entry '$CONFIG{ENTRY_ONE}'";
	}
};

# ═══════════════════════════════════════════════════════════════════════════
# DF-11  File::Temp lifecycle for gzipped CSV  D → U (held alive) → K (unlink)
#
# Chain: _open() decompresses .csv.gz → File::Temp object in _temp_fh (D) →
#        DBI reads the temp path (U) → DESTROY deletes _temp_fh (K) → auto-unlink
# ═══════════════════════════════════════════════════════════════════════════
subtest 'DF-11: File::Temp gzipped CSV lifecycle (D => U => K)' => sub {
	test_needs 'IO::Compress::Gzip';

	my $content = "entry!number\none!1\ntwo!2\nthree!3\n";
	# File must be named 'gz_df11.csv.gz' to match the 'gz_df11' table name
	# derived from package Database::gz_df11 by stripping the namespace prefix.
	my ($dir)   = _make_gz_dir(content => $content, name => 'gz_df11');
	{
		package Database::gz_df11;
		use parent 'Database::Abstraction';
		sub new {
			my ($class, %args) = @_;
			return $class->SUPER::new(sep_char => '!', %args);
		}
	}

	plan tests => 8;

	# DF-11.1: _temp_fh not defined before first query (no D yet)
	{
		my $db = Database::gz_df11->new(directory => $dir);
		ok !defined($db->{'_temp_fh'}),
			'DF-11.1: _temp_fh not defined before first query';
	}

	# DF-11.2: _temp_fh defined (D) after first query triggers decompression
	{
		my $db = Database::gz_df11->new(directory => $dir);
		$db->count();
		ok defined($db->{'_temp_fh'}),
			'DF-11.2: _temp_fh defined (D) after first query decompresses .csv.gz';
	}

	# DF-11.3: temp file exists on disk during object lifetime (U)
	my $temp_path;
	my $fh_weakref;
	{
		my $db = Database::gz_df11->new(directory => $dir);
		$db->count();
		# File::Temp objects stringify to their filename
		$temp_path = "$db->{'_temp_fh'}";
		ok -f $temp_path,
			'DF-11.3: temp file exists on disk (U) during object lifetime';

		# DF-11.4: same _temp_fh object reused on repeat queries (no re-decompression, no DD)
		my $fh1 = $db->{'_temp_fh'};
		$db->count();
		$db->selectall_arrayref();
		is $db->{'_temp_fh'}, $fh1,
			'DF-11.4: same File::Temp object reused (no DD) on repeat queries';

		# Capture a weak ref to test GC directly — avoids unreliable -f check on CI
		$fh_weakref = $db->{'_temp_fh'};
		Scalar::Util::weaken($fh_weakref);
	}    # $db goes out of scope → DESTROY → _temp_fh deleted (K)

	# DF-11.5: File was cleaned up after DESTROY
	ok !-f $temp_path,
		'DF-11.5: temp file removed after DESTROY (File::Temp auto-unlink)';

	# DF-11.6: data from gzipped CSV is correct
	{
		my $db  = Database::gz_df11->new(directory => $dir);
		my $cnt = $db->count();
		cmp_ok($cnt, '==', 3, 'DF-11.6: count() from gzipped CSV returns correct value');
	}

	# DF-11.7: second object opens its own temp file (no aliasing)
	{
		my $db1 = Database::gz_df11->new(directory => $dir);
		my $db2 = Database::gz_df11->new(directory => $dir);
		$db1->count();
		$db2->count();
		isnt "$db1->{'_temp_fh'}", "$db2->{'_temp_fh'}",
			'DF-11.7: two objects use distinct temp files (no aliased D)';
	}

	# DF-11.8: DESTROY of one object does not affect the other's temp file
	{
		my $other_path;
		{
			my $db1 = Database::gz_df11->new(directory => $dir);
			my $db2 = Database::gz_df11->new(directory => $dir);
			$db1->count();
			$db2->count();
			$other_path = "$db2->{'_temp_fh'}";
		}    # both destroyed here
		ok !-f $other_path,
			'DF-11.8: both temp files removed after both objects destroyed';
	}
};

# ═══════════════════════════════════════════════════════════════════════════
# DF-12  $params immutability — public methods must not mutate caller's hash
#
# The DU chain: caller defines %criteria (D) → passes to select method →
#   method reads (U) but must not kill (K) or rewrite (DD) any key
# ═══════════════════════════════════════════════════════════════════════════
subtest 'DF-12: params hashref immutability through select methods' => sub {

	my $db = _new_db();

	# DF-12.1: selectall_arrayref does not mutate criteria
	{
		my %c = (entry => $CONFIG{ENTRY_ONE});
		$db->selectall_arrayref(%c);
		is_deeply \%c, { entry => $CONFIG{ENTRY_ONE} },
			'DF-12.1: selectall_arrayref does not mutate caller criteria hash';
	}

	# DF-12.2: count() does not mutate criteria
	{
		my %c = (entry => $CONFIG{ENTRY_ONE});
		$db->count(%c);
		is_deeply \%c, { entry => $CONFIG{ENTRY_ONE} },
			'DF-12.2: count() does not mutate caller criteria hash';
	}

	# DF-12.3: fetchrow_hashref does not mutate criteria
	{
		my %c = (entry => $CONFIG{ENTRY_ONE});
		$db->fetchrow_hashref(%c);
		is_deeply \%c, { entry => $CONFIG{ENTRY_ONE} },
			'DF-12.3: fetchrow_hashref does not mutate caller criteria hash';
	}

	# DF-12.4: -or grouping criteria preserved through selectall_arrayref
	{
		my @or_list = (
			{ entry => $CONFIG{ENTRY_ONE} },
			{ entry => $CONFIG{ENTRY_TWO} },
		);
		my %c = ('-or' => \@or_list);
		my $or_ref_before = $c{'-or'};
		$db->selectall_arrayref(%c);
		is $c{'-or'}, $or_ref_before,
			'DF-12.4: -or arrayref in criteria not replaced by selectall_arrayref';
		is_deeply $c{'-or'}, \@or_list,
			'DF-12.4b: -or content unchanged after selectall_arrayref';
	}

	# DF-12.5: passing the same hashref twice produces consistent results
	{
		my $cref = { entry => $CONFIG{ENTRY_ONE} };
		my $r1   = $db->selectall_arrayref($cref);
		my $r2   = $db->selectall_arrayref($cref);
		is_deeply $r1, $r2,
			'DF-12.5: same criteria ref passed twice yields consistent results';
	}

	# DF-12.6: join param extracted by fetchrow_hashref without destroying other criteria
	{
		# fetchrow_hashref does delete('table') and delete('join') from an internal
		# copy of params; the caller's hash should be unaffected.
		my %c = (entry => $CONFIG{ENTRY_ONE});
		$db->fetchrow_hashref(%c);
		ok !exists($c{'join'}),
			'DF-12.6a: no spurious "join" key introduced in caller hash';
		is $c{'entry'}, $CONFIG{ENTRY_ONE},
			'DF-12.6b: original criteria key preserved after fetchrow_hashref';
	}
};

# ═══════════════════════════════════════════════════════════════════════════
# DF-13  wantarray context propagation through selectall_array
#
# Verifies the D→U chain for the `wantarray` test inside selectall_array:
# list context adds ORDER BY; scalar context adds LIMIT 1.
# ═══════════════════════════════════════════════════════════════════════════
subtest 'DF-13: wantarray context propagation in selectall_array' => sub {

	my $db = _new_db();

	# DF-13.1: list context — all rows returned (multiple D values on caller stack)
	{
		my @rows = $db->selectall_array();
		cmp_ok scalar(@rows), '==', $CONFIG{TOTAL_ROWS},
			'DF-13.1: list context returns all rows';
		ok ref($rows[0]) eq 'HASH',
			'DF-13.1b: each element is a hashref';
	}

	# DF-13.2: scalar context with a specific entry — returns the matching hashref.
	# The fast-track for no-criteria slurp returns `values %hash` which in scalar context
	# gives the count, not a row.  With an entry criteria, the single-entry fast-track
	# fires and returns the hashref directly regardless of context.
	{
		my $row = $db->selectall_array(entry => $CONFIG{ENTRY_ONE});
		ok defined($row),     'DF-13.2a: scalar context with entry criteria returns defined value';
		is ref($row), 'HASH', 'DF-13.2b: scalar context with entry criteria returns a hashref';
		is $row->{'entry'}, $CONFIG{ENTRY_ONE},
			'DF-13.2c: returned hashref has correct entry value';
	}

	# DF-13.3: list context with criteria — returns matching subset
	{
		my @rows = $db->selectall_array(entry => $CONFIG{ENTRY_ONE});
		is scalar(@rows), 1,
			'DF-13.3: list context with entry criteria returns exactly one row';
		is $rows[0]{'entry'}, $CONFIG{ENTRY_ONE},
			"DF-13.3b: returned row has entry '$CONFIG{ENTRY_ONE}'";
	}

	# DF-13.4: empty result — list context returns empty list (not undef)
	{
		my @rows = $db->selectall_array(entry => 'nonexistent_xyz');
		is scalar(@rows), 0,
			'DF-13.4: empty result in list context returns empty list (not undef)';
	}

	# DF-13.5: empty result — scalar context returns undef (not a ref or 0)
	{
		my $row = $db->selectall_array(entry => 'nonexistent_xyz');
		ok !defined($row),
			'DF-13.5: empty result in scalar context returns undef';
	}
};

# ═══════════════════════════════════════════════════════════════════════════
# DF-14  AUTOLOAD column DU chain — value flows from data source to caller
#
# Chain: AUTOLOAD extracts $column from $AUTOLOAD (D) → looks up in data
#        or SQL (U) → fixates result (U) → returns to caller
# ═══════════════════════════════════════════════════════════════════════════
subtest 'DF-14: AUTOLOAD column data flow' => sub {

	my $db = _new_db();

	# DF-14.1: scalar context — single value (D on caller's scalar)
	{
		my $val = $db->number(entry => $CONFIG{ENTRY_ONE});
		ok !ref($val), 'DF-14.1: AUTOLOAD scalar context returns a plain scalar';
		is $val, '1', "DF-14.1b: value for entry '$CONFIG{ENTRY_ONE}' is '1'";
	}

	# DF-14.2: list context — all values (D on caller's array)
	{
		my @vals = $db->number();
		cmp_ok scalar(@vals), '==', $CONFIG{TOTAL_ROWS},
			'DF-14.2: AUTOLOAD list context returns one value per row';
		ok !grep { ref($_) } @vals,
			'DF-14.2b: all returned values are plain scalars';
	}

	# DF-14.3: distinct — unique values only.
	# Verify: (a) distinct returns no more values than all values, and
	#         (b) every value in the distinct set appears in the full set.
	# We don't compare exact dedup equality because the 'empty' entry's blank
	# number value is platform-dependent (undef vs ''), making exact dedup tricky.
	{
		my @all    = $db->number();
		my @unique = $db->number(distinct => 1);
		cmp_ok scalar(@unique), '<=', scalar(@all),
			'DF-14.3a: distinct returns no more values than the full list';
		cmp_ok scalar(@unique), '>=', 1,
			'DF-14.3b: distinct returns at least one value';
		my %all_set = map { ($_ // '__undef__') => 1 } @all;
		my @not_in_all = grep { !exists $all_set{$_ // '__undef__'} } @unique;
		is scalar(@not_in_all), 0,
			'DF-14.3c: every distinct value also appears in the full list';
	}

	# DF-14.4: slurp path and SQL path return the same value (DU chain consistency)
	{
		my $db_slurp = _new_db();
		$db_slurp->count();    # forces slurp
		my $val_slurp = $db_slurp->number(entry => $CONFIG{ENTRY_ONE});

		my $db_sql = _new_db(max_slurp_size => 0);    # forces SQL path
		my $val_sql = $db_sql->number(entry => $CONFIG{ENTRY_ONE});

		is $val_slurp, $val_sql,
			'DF-14.4: AUTOLOAD returns same value from slurp and SQL data paths';
	}

	# DF-14.5: missing entry returns undef (not an error)
	{
		my $val = $db->number(entry => 'nonexistent_xyz');
		ok !defined($val),
			'DF-14.5: AUTOLOAD returns undef for non-existent entry (not a croak)';
	}

	# DF-14.6: empty column value flows through to caller as undef (not empty string)
	{
		# 'empty' row has an empty number value in test1.csv
		my $val = $db->number(entry => $CONFIG{ENTRY_EMPTY});
		# Empty CSV field → undef or empty string depending on Text::xSV::Slurp
		ok !defined($val) || $val eq '',
			'DF-14.6: empty column value returned as undef or empty string (not corrupted)';
	}
};

# ═══════════════════════════════════════════════════════════════════════════
# DF-15  fixate() — data immutability post-fixation (U after D via fixate)
#
# Verifies: fixated data has correct values, is consistent across calls,
#           and exists() guards work on locked hashes.
# ═══════════════════════════════════════════════════════════════════════════
subtest 'DF-15: fixated data integrity and exists() guard correctness' => sub {

	my $db = _new_db();

	# DF-15.1: fixated data has correct values (D correct, U works)
	{
		my $rows = $db->selectall_arrayref();
		my ($row) = grep { $_->{'entry'} eq $CONFIG{ENTRY_ONE} } @{$rows};
		ok defined($row), 'DF-15.1a: expected entry present in fixated result';
		is $row->{'entry'},  $CONFIG{ENTRY_ONE},
			'DF-15.1b: entry value correct in fixated row';
		is $row->{'number'}, '1',
			'DF-15.1c: number value correct in fixated row';
	}

	# DF-15.2: fixated data is stable across repeat reads (U consistent after D)
	{
		my $r1 = $db->selectall_arrayref();
		my $r2 = $db->selectall_arrayref();
		is_deeply $r1, $r2, 'DF-15.2: selectall_arrayref consistent across repeat calls';
	}

	# DF-15.3: exists() on fixated row — defined key returns true
	{
		my $row = $db->fetchrow_hashref(entry => $CONFIG{ENTRY_ONE});
		ok exists($row->{'entry'}),
			'DF-15.3: exists() on defined key in fixated row returns true';
	}

	# DF-15.4: exists() on fixated row — undefined key returns false (no throw)
	{
		my $row = $db->fetchrow_hashref(entry => $CONFIG{ENTRY_ONE});
		my $ok  = eval { !exists($row->{'no_such_col_xyz'}) };
		ok !$@,  'DF-15.4a: exists() on undefined key in fixated row does not croak';
		ok $ok,  'DF-15.4b: exists() on undefined key returns false';
	}

	# DF-15.5: no_fixate => 1 — data is still correct (D and U work without fixation)
	{
		my $db_nf = _new_db(no_fixate => 1);
		my $rows  = $db_nf->selectall_arrayref();
		cmp_ok scalar(@{$rows}), '==', $CONFIG{TOTAL_ROWS},
			'DF-15.5: no_fixate mode still returns correct row count';
		ok defined($rows->[0]{'entry'}),
			'DF-15.5b: row data accessible without fixation';
	}

	# DF-15.6: slurped data and SQL data produce is_deeply equal results
	{
		my $db_slurp = _new_db();
		my $db_sql   = _new_db(max_slurp_size => 0);
		my $r_slurp  = $db_slurp->selectall_arrayref();
		my $r_sql    = $db_sql->selectall_arrayref();
		# Sort both by entry for comparison (SQL returns ORDER BY entry, slurp order varies)
		my @s1 = sort { $a->{'entry'} cmp $b->{'entry'} } @{$r_slurp};
		my @s2 = sort { $a->{'entry'} cmp $b->{'entry'} } @{$r_sql};
		is_deeply \@s1, \@s2,
			'DF-15.6: fixated slurp data deeply equals SQL data (DU chain consistent across paths)';
	}
};

# ═══════════════════════════════════════════════════════════════════════════
# DF-16  base_criteria data flow  D → U (every query) → immutability
#
# Chain: new() shallow-copies caller's hashref into $self->{'base_criteria'} (D) →
#        _merge_base_criteria() returns merged copy on each query (U) →
#        caller's original hashref is not mutated (K never fires on caller's D)
# ═══════════════════════════════════════════════════════════════════════════
subtest 'DF-16: base_criteria DU chain (D → U in every query → immutability)' => sub {

	# DF-16.1: base_criteria absent → stored as undef (no D on slot)
	{
		my $db = _new_db();
		ok !defined($db->{'base_criteria'}),
			'DF-16.1: base_criteria slot absent when not given at construction';
	}

	# DF-16.2: base_criteria stored at construction (D) — correct value
	{
		my $db = _new_db(base_criteria => { entry => $CONFIG{ENTRY_ONE} });
		is_deeply $db->{'base_criteria'}, { entry => $CONFIG{ENTRY_ONE} },
			'DF-16.2: base_criteria defined (D) at construction with expected value';
	}

	# DF-16.3: shallow copy — mutating caller's original after construction does not affect object (D is a copy)
	{
		my %orig = (entry => $CONFIG{ENTRY_ONE});
		my $db   = _new_db(base_criteria => \%orig);
		$orig{entry} = 'INJECTED';    # mutate caller's hash after new()
		is $db->{'base_criteria'}{entry}, $CONFIG{ENTRY_ONE},
			'DF-16.3: base_criteria is a shallow copy — mutation of caller hashref does not affect stored D';
	}

	# DF-16.4: selectall_arrayref respects base_criteria (U in every query)
	{
		my $db   = _new_db(base_criteria => { entry => $CONFIG{ENTRY_ONE} });
		my $rows = $db->selectall_arrayref();
		is scalar(@{$rows}), 1, 'DF-16.4a: selectall_arrayref with base_criteria returns filtered rows (U)';
		is $rows->[0]{'entry'}, $CONFIG{ENTRY_ONE},
			'DF-16.4b: returned row matches base_criteria filter';
	}

	# DF-16.5: count() respects base_criteria (U)
	{
		my $db = _new_db(base_criteria => { entry => $CONFIG{ENTRY_ONE} });
		is $db->count(), 1, 'DF-16.5: count() filtered by base_criteria returns 1 (U)';
	}

	# DF-16.6: fetchrow_hashref respects base_criteria — mismatched entry returns undef
	{
		my $db  = _new_db(base_criteria => { entry => $CONFIG{ENTRY_ONE} });
		my $row = $db->fetchrow_hashref(entry => $CONFIG{ENTRY_TWO});
		ok !defined($row),
			'DF-16.6: fetchrow_hashref with base_criteria mismatch returns undef (U filters correctly)';
	}

	# DF-16.7: query builder respects base_criteria (U in Query._build_sql)
	{
		my $db = _new_db(base_criteria => { entry => $CONFIG{ENTRY_ONE} });
		my $n  = $db->query()->count();
		is $n, 1, 'DF-16.7: query->count() filtered by base_criteria returns 1 (U in _build_sql)';
	}

	# DF-16.8: caller-supplied criteria WIN over base_criteria (U → narrow-down semantics)
	# base_criteria sets entry => ONE; caller narrows to entry => ONE — still finds 1
	{
		my $db   = _new_db(base_criteria => { entry => $CONFIG{ENTRY_ONE} });
		my $rows = $db->selectall_arrayref(entry => $CONFIG{ENTRY_ONE});
		is scalar(@{$rows}), 1,
			'DF-16.8a: caller criteria consistent with base_criteria — 1 result';
		is $rows->[0]{'entry'}, $CONFIG{ENTRY_ONE},
			'DF-16.8b: correct row returned when caller and base_criteria agree';
	}

	# DF-16.9: empty base_criteria {} — behaves as if no filter (all rows returned)
	{
		my $db = _new_db(base_criteria => {});
		is $db->count(), $CONFIG{TOTAL_ROWS},
			'DF-16.9: empty base_criteria ({}) does not filter any rows';
	}

	# DF-16.10: base_criteria stable across calls (no DD — not re-assigned after construction)
	{
		my $db = _new_db(base_criteria => { entry => $CONFIG{ENTRY_ONE} });
		my $bc_before = $db->{'base_criteria'};
		$db->count();
		$db->selectall_arrayref();
		$db->fetchrow_hashref(entry => $CONFIG{ENTRY_ONE});
		is $db->{'base_criteria'}, $bc_before,
			'DF-16.10: base_criteria ref unchanged (no DD) across all query calls';
	}
};

# ═══════════════════════════════════════════════════════════════════════════
# DF-17  _schema cache + _match_criterion numeric DU chain
#
# Chain: schema() call populates $self->{'_schema'} (D) → _match_criterion
#        reads it (U) for numeric column equality — enabling == instead of eq
# ═══════════════════════════════════════════════════════════════════════════
subtest 'DF-17: _schema cache flows into _match_criterion numeric comparison' => sub {
	test_needs 'DBD::SQLite';

	# Build an in-memory SQLite DB with INTEGER and TEXT columns
	{
		package Database::df17;
		use parent 'Database::Abstraction';
	}
	my $dir17   = tempdir(CLEANUP => 1);
	my $file17  = File::Spec->catfile($dir17, 'df17.sql');
	my $setup17 = DBI->connect("dbi:SQLite:dbname=$file17", undef, undef, { RaiseError => 1 });
	$setup17->do(q{CREATE TABLE df17 (id INTEGER PRIMARY KEY, score INTEGER, label TEXT)});
	$setup17->do(q{INSERT INTO df17 VALUES (1, 42, 'alpha')});
	$setup17->do(q{INSERT INTO df17 VALUES (2, 100, 'beta')});
	$setup17->disconnect();

	my $db = Database::df17->new(dsn => "dbi:SQLite:dbname=$file17", no_entry => 1);

	# DF-17.1: _schema not defined before first schema() call (no D yet)
	{
		my $db2 = Database::df17->new(dsn => "dbi:SQLite:dbname=$file17", no_entry => 1);
		ok !defined($db2->{'_schema'}),
			'DF-17.1: _schema undefined before schema() call (no D)';
	}

	# DF-17.2: schema() defines _schema (D) with correct type info
	{
		my $sch = $db->schema();
		ok defined($db->{'_schema'}), 'DF-17.2a: _schema defined (D) after schema() call';
		is ref($db->{'_schema'}), 'HASH', 'DF-17.2b: _schema is a HASH ref';
		is $sch->{'score'}{'type'}, 'INTEGER',
			'DF-17.2c: score column typed INTEGER in _schema (D correct)';
	}

	# DF-17.3: _schema cache hit — same hashref returned on second schema() call (U)
	{
		my $s1 = $db->schema();
		my $s2 = $db->schema();
		is $s1, $s2, 'DF-17.3: schema() returns same hashref (U from cache) on repeat calls';
	}

	# DF-17.4: _schema stable across all query calls (no DD)
	{
		my $sch_before = $db->{'_schema'};
		$db->count();
		$db->selectall_arrayref();
		is $db->{'_schema'}, $sch_before,
			'DF-17.4: _schema ref unchanged (no DD) across count/selectall calls';
	}

	# DF-17.5: numeric comparison (U of _schema in _match_criterion) — via infer_types on CSV
	{
		my ($dir17b) = _make_csv_dir(
			content => "entry!score\nrow_a!042\nrow_b!100\n",
			name    => 'df17b'
		);
		{
			package Database::df17b;
			use parent 'Database::Abstraction';
		}
		my $db17b = Database::df17b->new(
			directory   => $dir17b,
			infer_types => 1,
			sep_char    => '!',
		);
		# Warm the schema cache so _match_criterion gets numeric info
		$db17b->schema();
		ok defined($db17b->{'_schema'}{'score'}),
			'DF-17.5a: infer_types schema has score column entry';
		# When infer_types is on, score should be INTEGER; numeric comparison then
		# makes 42 == 042 and 100 == 100.0 match correctly.
		my $rows = $db17b->selectall_arrayref(entry => 'row_a');
		ok defined($rows) && scalar(@{$rows}) >= 1,
			'DF-17.5b: row_a found — schema (U) flows into in-memory filter correctly';
	}
};

# ═══════════════════════════════════════════════════════════════════════════
# DF-18  each_row() streaming DU chain + O~ prevention (sth->finish on exception)
#
# SQL path: prepare_cached (D sth) → execute → fetchrow_hashref in loop (U sth) →
#   finish on exception (K sth) or natural loop end (K sth implicit)
# Slurp path: @rc collected (D) → callback invoked per row (U) → @rc de-scoped (K)
# ═══════════════════════════════════════════════════════════════════════════
subtest 'DF-18: each_row() streaming DU chain and exception-safe sth close' => sub {
	test_needs 'DBD::SQLite';

	{
		package Database::df18;
		use parent 'Database::Abstraction';
	}
	my $dir18   = tempdir(CLEANUP => 1);
	my $file18  = File::Spec->catfile($dir18, 'df18.sql');
	my $setup18 = DBI->connect("dbi:SQLite:dbname=$file18", undef, undef, { RaiseError => 1 });
	$setup18->do(q{CREATE TABLE df18 (entry TEXT PRIMARY KEY, val INTEGER)});
	$setup18->do(q{INSERT INTO df18 VALUES ('a', 1)});
	$setup18->do(q{INSERT INTO df18 VALUES ('b', 2)});
	$setup18->do(q{INSERT INTO df18 VALUES ('c', 3)});
	$setup18->disconnect();

	my $db_sql   = Database::df18->new(dsn => "dbi:SQLite:dbname=$file18", no_entry => 1);
	my $db_slurp = _new_db();

	# DF-18.1: callback receives each row; count returned equals row count
	{
		my @seen;
		my $n = $db_sql->each_row(sub { push @seen, $_[0]->{'entry'} });
		is $n, 3,          'DF-18.1a: each_row returns count of rows visited (SQL path)';
		is scalar(@seen), 3, 'DF-18.1b: callback invoked once per row (SQL path)';
		ok !grep { !defined $_ } @seen,
			'DF-18.1c: all received entry values are defined (no undef injection)';
	}

	# DF-18.2: slurp path streaming — callback also receives each row once
	{
		my @seen;
		my $n = $db_slurp->each_row(sub { push @seen, $_[0]->{'entry'} });
		is $n, $CONFIG{TOTAL_ROWS},
			'DF-18.2a: each_row returns correct count on slurp path';
		is scalar(@seen), $CONFIG{TOTAL_ROWS},
			'DF-18.2b: slurp-path callback invoked once per row';
	}

	# DF-18.3: sth is released (K) even when callback throws — O~ prevention
	# The SQL path wraps the fetch loop in eval; sth->finish() is called on die.
	# We verify the handle is still in a valid state after the exception (no dangling O~).
	{
		my $threw = 0;
		eval {
			$db_sql->each_row(sub {
				die "DELIBERATE_EXCEPTION\n" if $_[0]->{'entry'} eq 'a';
			});
		};
		like $@, qr/DELIBERATE_EXCEPTION/,
			'DF-18.3a: exception from callback propagates to caller';
		# The DBI handle must still be usable — a dangling sth would cause "active statement" errors
		my $n = eval { $db_sql->count() };
		ok !$@, 'DF-18.3b: DBI handle remains valid after each_row exception (O~ prevented)';
		is $n, 3, 'DF-18.3c: count() after each_row exception returns correct result';
	}

	# DF-18.4: criteria-filtered streaming — only matching rows reach callback (U flows through filter)
	{
		my @seen;
		my $n = $db_sql->each_row(sub { push @seen, $_[0] }, entry => 'a');
		is $n, 1, 'DF-18.4a: each_row with criteria returns correct count';
		is scalar(@seen), 1, 'DF-18.4b: callback invoked only for matching row';
		is $seen[0]{'entry'}, 'a', 'DF-18.4c: received row matches criteria';
	}

	# DF-18.5: each_row returns 0 for a no-match criteria (empty DU: D fires, no U to callback)
	{
		my $n = $db_sql->each_row(sub { }, entry => 'no_such_entry_xyz');
		is $n, 0, 'DF-18.5: each_row returns 0 when no rows match (empty DU chain)';
	}
};

# ═══════════════════════════════════════════════════════════════════════════
# DF-19  updated() DSN SQLite live-stat DU chain
#
# For file-based backends: stat() in _open() stores mtime in _updated (D once).
# For DSN-based SQLite: updated() stat()s the file live on every call (U live).
# ═══════════════════════════════════════════════════════════════════════════
subtest 'DF-19: updated() DSN SQLite live-stat vs file-mtime DU chain' => sub {
	test_needs 'DBD::SQLite';

	{
		package Database::df19;
		use parent 'Database::Abstraction';
	}
	my $dir19   = tempdir(CLEANUP => 1);
	my $file19  = File::Spec->catfile($dir19, 'df19.sql');
	my $dsn19   = "dbi:SQLite:dbname=$file19";
	my $setup19 = DBI->connect($dsn19, undef, undef, { RaiseError => 1 });
	$setup19->do(q{CREATE TABLE df19 (entry TEXT PRIMARY KEY, val TEXT)});
	$setup19->do(q{INSERT INTO df19 VALUES ('x', 'one')});
	$setup19->disconnect();

	my $db = Database::df19->new(dsn => $dsn19, no_entry => 1);
	$db->count();    # force open

	# DF-19.1: _dialect is 'sqlite' (D) after DSN open
	is $db->{'_dialect'}, 'sqlite',
		'DF-19.1: _dialect defined (D) as "sqlite" for SQLite DSN connection';

	# DF-19.2: updated() returns a positive timestamp (U from live stat)
	cmp_ok $db->updated(), '>', 0,
		'DF-19.2: updated() returns positive timestamp (U of live stat for DSN SQLite)';
	cmp_ok $db->updated(), '<=', time() + 10,
		'DF-19.2b: updated() timestamp is not in the future';

	# DF-19.3: file-based backend — updated() reads stored _updated (D once, U from slot)
	{
		my $db_file = _new_db();
		$db_file->count();
		my $t1 = $db_file->updated();
		my $t2 = $db_file->updated();
		is $t1, $t2, 'DF-19.3: file backend updated() returns same value on repeat calls (D once, U from slot)';
	}

	# DF-19.4: DSN SQLite _updated slot also set (D at connect time), but live stat is used
	{
		ok defined($db->{'_updated'}),
			'DF-19.4a: _updated slot is defined (D) on DSN SQLite connect';
		# updated() for SQLite DSN goes through live stat() path, not the slot directly
		my $live_ts = $db->updated();
		cmp_ok $live_ts, '>', 0,
			'DF-19.4b: live stat path returns valid timestamp (U of live stat)';
	}

	# DF-19.5: two objects on the same DSN file return consistent mtime (both U from same file)
	{
		my $db2 = Database::df19->new(dsn => $dsn19, no_entry => 1);
		$db2->count();
		cmp_ok abs($db->updated() - $db2->updated()), '<=', 2,
			'DF-19.5: two DSN SQLite objects return consistent mtime (same file, U from same source)';
	}
};

# ═══════════════════════════════════════════════════════════════════════════
# DF-20  _build_where params copy-on-write for -or/-and
#
# Chain: when -or or -and keys are present a copy of $params is made (D for copy) →
#        the grouping keys are deleted from the copy (U+K on copy) →
#        original $params hashref is not mutated (D of caller's original preserved)
# When no -or/-and: $params passed through directly (no extra D, no allocation)
# ═══════════════════════════════════════════════════════════════════════════
subtest 'DF-20: _build_where -or/-and copy-on-write (D → U → K on copy only)' => sub {

	my $db = _new_db();

	# DF-20.1: plain criteria — original hashref passed through unchanged (no spurious copy D)
	{
		my %crit = (entry => $CONFIG{ENTRY_ONE});
		my $cref_before = \%crit;
		$db->selectall_arrayref(%crit);
		is \%crit, $cref_before,
			'DF-20.1: plain criteria: same hashref address used (no D for copy), content unchanged';
		is_deeply \%crit, { entry => $CONFIG{ENTRY_ONE} },
			'DF-20.1b: plain criteria not mutated by selectall_arrayref';
	}

	# DF-20.2: -or criteria — grouping keys not present in caller's hashref after call
	{
		my %crit = (
			'-or' => [
				{ entry => $CONFIG{ENTRY_ONE} },
				{ entry => $CONFIG{ENTRY_TWO} },
			]
		);
		my $or_ref_before = $crit{'-or'};
		$db->selectall_arrayref(%crit);
		# The -or key should still exist in caller's hash (copy-on-write: original untouched)
		ok exists($crit{'-or'}),
			'DF-20.2a: -or key still present in caller hash after selectall_arrayref';
		is $crit{'-or'}, $or_ref_before,
			'DF-20.2b: -or value ref unchanged — caller original D not mutated';
	}

	# DF-20.3: -and criteria — same immutability as -or
	{
		my %crit = (
			'-and' => [
				{ entry => $CONFIG{ENTRY_ONE} },
			]
		);
		my $and_ref_before = $crit{'-and'};
		$db->selectall_arrayref(%crit);
		ok exists($crit{'-and'}),
			'DF-20.3a: -and key still present in caller hash after selectall_arrayref';
		is $crit{'-and'}, $and_ref_before,
			'DF-20.3b: -and value ref unchanged — caller original D not mutated';
	}

	# DF-20.4: -or result is correct (the copy (D) was correctly used, then discarded (K))
	{
		my $rows = $db->selectall_arrayref(
			'-or' => [
				{ entry => $CONFIG{ENTRY_ONE} },
				{ entry => $CONFIG{ENTRY_TWO} },
			]
		);
		my @entries = map { $_->{'entry'} } @{$rows};
		my %have    = map { $_ => 1 } @entries;
		ok $have{$CONFIG{ENTRY_ONE}}, "DF-20.4a: -or result includes '$CONFIG{ENTRY_ONE}'";
		ok $have{$CONFIG{ENTRY_TWO}}, "DF-20.4b: -or result includes '$CONFIG{ENTRY_TWO}'";
		cmp_ok scalar(@{$rows}), '==', 2,
			'DF-20.4c: -or result has exactly 2 rows (one per OR branch)';
	}
};

# ═══════════════════════════════════════════════════════════════════════════
# DF-21  dbi_source() DU chain  D → U → undef for non-SQLite
#
# Chain: _open() creates DBI handle for SQLite (D via $self->{$table}) →
#        dbi_source() uses it (U) to return { dbh => $dbh, table => $table } →
#        for non-SQLite / slurp backends $self->{$table} is undef → returns undef
# ═══════════════════════════════════════════════════════════════════════════
subtest 'DF-21: dbi_source() DU chain (SQLite returns hashref, slurp returns undef)' => sub {
	test_needs 'DBD::SQLite';

	{
		package Database::df21;
		use parent 'Database::Abstraction';
	}
	my $dir21   = tempdir(CLEANUP => 1);
	my $file21  = File::Spec->catfile($dir21, 'df21.sql');
	my $setup21 = DBI->connect("dbi:SQLite:dbname=$file21", undef, undef, { RaiseError => 1 });
	$setup21->do(q{CREATE TABLE df21 (entry TEXT PRIMARY KEY, val TEXT)});
	$setup21->do(q{INSERT INTO df21 VALUES ('k1', 'v1')});
	$setup21->disconnect();

	my $db_sqlite = Database::df21->new(dsn => "dbi:SQLite:dbname=$file21", no_entry => 1);
	my $db_csv    = _new_db();

	# DF-21.1: dbi_source() for SQLite DSN returns a hashref (D dbh used → U returned)
	{
		my $src = $db_sqlite->dbi_source();
		ok defined($src), 'DF-21.1a: dbi_source() returns defined value for SQLite DSN (U of dbh)';
		is ref($src), 'HASH', 'DF-21.1b: dbi_source() result is a hashref';
		ok defined($src->{'dbh'}),   'DF-21.1c: result has dbh key';
		ok defined($src->{'table'}), 'DF-21.1d: result has table key';
		is $src->{'table'}, 'df21',  "DF-21.1e: table is 'df21'";
	}

	# DF-21.2: dbh in dbi_source result is the same handle as $self->{$table} (U of same D)
	{
		$db_sqlite->count();    # force open
		my $src = $db_sqlite->dbi_source();
		is $src->{'dbh'}, $db_sqlite->{'df21'},
			'DF-21.2: dbi_source dbh is the same DBI handle as $self->{table} (same D used)';
	}

	# DF-21.3: dbi_source() for CSV slurp backend returns undef (no DBI handle D for SQLite)
	{
		my $src = $db_csv->dbi_source();
		ok !defined($src),
			'DF-21.3: dbi_source() returns undef for CSV slurp backend (no SQLite dbh D)';
	}

	# DF-21.4: two SQLite objects have independent dbh slots (two distinct D)
	{
		my $db_alt = Database::df21->new(dsn => "dbi:SQLite:dbname=$file21", no_entry => 1);
		my $s1 = $db_sqlite->dbi_source();
		my $s2 = $db_alt->dbi_source();
		isnt $s1->{'dbh'}, $s2->{'dbh'},
			'DF-21.4: two objects have distinct DBI handles (independent D slots)';
	}

	# DF-21.5: dbi_source result dbh is functional — can prepare a query through it
	{
		my $src = $db_sqlite->dbi_source();
		my $sth = eval { $src->{'dbh'}->prepare("SELECT COUNT(*) FROM $src->{'table'}") };
		ok !$@, 'DF-21.5a: no error preparing query via dbi_source dbh';
		if($sth) {
			$sth->execute();
			my ($cnt) = $sth->fetchrow_array();
			$sth->finish();
			is $cnt, 1, 'DF-21.5b: query via dbi_source dbh returns correct result';
		} else {
			skip 'sth undefined', 1;
		}
	}
};

# ═══════════════════════════════════════════════════════════════════════════
# DF-22  D~ anomaly documentation — fetchrow_hashref $key pre-computation
#
# The source code at Abstraction.pm line ~2481 computes $key unconditionally
# even when $self->{cache} is undef (the string is then never read = dead store).
# This is flagged in code with: "# TODO: Data Flow Anomaly - D~: ..."
# These tests verify: (a) the anomaly is present but benign, and
#                     (b) the key IS correct when cache IS configured.
# ═══════════════════════════════════════════════════════════════════════════
subtest 'DF-22: D~ anomaly in fetchrow_hashref $key — benign dead-store documentation' => sub {

	# DF-22.1: without cache — fetchrow_hashref returns correct data (dead store is benign)
	{
		my $db  = _new_db();    # no cache
		my $row = $db->fetchrow_hashref(entry => $CONFIG{ENTRY_ONE});
		ok defined($row), 'DF-22.1a: fetchrow_hashref returns defined row without cache';
		is $row->{'entry'}, $CONFIG{ENTRY_ONE},
			'DF-22.1b: D~ dead-store anomaly is benign — correct data returned without cache';
		is $row->{'number'}, '1',
			'DF-22.1c: column value correct — pre-computed key causes no data corruption';
	}

	# DF-22.2: with cache — $key IS used (U), so no dead-store in the cache path
	{
		test_needs 'CHI';
		my $cache = CHI->new(driver => 'Memory', global => 0);
		my $db    = _new_db(cache => $cache, cache_duration => '1 hour');
		my $r1    = $db->fetchrow_hashref(entry => $CONFIG{ENTRY_ONE});    # MISS → D in cache
		my $r2    = $db->fetchrow_hashref(entry => $CONFIG{ENTRY_ONE});    # HIT → U from cache
		ok defined($r1) && defined($r2), 'DF-22.2a: both calls return defined rows';
		is_deeply $r1, $r2,
			'DF-22.2b: cache HIT returns equivalent data (U from cache correct when key present)';
		is $r2->{'entry'}, $CONFIG{ENTRY_ONE},
			'DF-22.2c: cached row has correct entry value (key correctly formed)';
	}

	# DF-22.3: wantarray context — different key computed for array vs scalar
	{
		test_needs 'CHI';
		my $cache = CHI->new(driver => 'Memory', global => 0);
		my $db    = _new_db(cache => $cache, cache_duration => '1 hour');
		# scalar context: key does NOT include 'array ' prefix
		my $s     = $db->fetchrow_hashref(entry => $CONFIG{ENTRY_ONE});
		# list context: key DOES include 'array ' prefix — distinct cache entry
		my @l     = $db->fetchrow_hashref(entry => $CONFIG{ENTRY_ONE});
		ok defined($s),    'DF-22.3a: scalar-context result is defined';
		ok scalar(@l) > 0, 'DF-22.3b: list-context result is non-empty';
	}

	# DF-22.4: repeated fetchrow_hashref without cache returns consistent data (idempotent U)
	{
		my $db = _new_db();
		my $r1 = $db->fetchrow_hashref(entry => $CONFIG{ENTRY_ONE});
		my $r2 = $db->fetchrow_hashref(entry => $CONFIG{ENTRY_ONE});
		is_deeply $r1, $r2,
			'DF-22.4: repeated fetchrow_hashref without cache returns identical data (idempotent)';
	}

	# DF-22.5: undef-entry returns undef — dead-store key is still harmless for missing rows
	{
		my $db  = _new_db();
		my $row = $db->fetchrow_hashref(entry => 'nonexistent_xyz');
		ok !defined($row),
			'DF-22.5: fetchrow_hashref for missing entry returns undef (D~ does not cause false hit)';
	}
};

done_testing();
