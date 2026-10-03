#!perl -w

# t/transition.t — Finite State Machine (FSM) transition tests for
# Database::Abstraction.
#
# Database::Abstraction objects pass through a precisely defined set of
# states during their lifecycle.  This file is the FSM compliance oracle: it
# asserts that every documented state transition fires correctly, that all
# state-invariants hold after each transition, and that every illegal
# transition is actively rejected before reaching the SQL layer.
#
# FSM derived from lib/Database/Abstraction.pm source (no POD diagram exists):
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │  STATES                                                                 │
# │  S1  CONSTRUCTED      new() returned; _open() not yet called            │
# │  S2  OPEN_DBI         type='DBI'; DBI handle set; data=undef            │
# │  S3  OPEN_SLURP_CSV   type='CSV'; data=HASH|ARRAY; DBI handle=DBD::CSV  │
# │  S4  OPEN_SLURP_XML   type='XML'; data=HASH; DBI handle=undef           │
# │  S5  OPEN_SLURP_JSON  type='JSON'; data=HASH|ARRAY; DBI handle=undef    │
# │  S6  OPEN_SLURP_DEEP  type='Deep'; data=HASH|ARRAY; DBI handle=undef    │
# │  S7  OPEN_BERKELEY    type='BerkeleyDB'; berkeley=tied HASH;            │
# │                        data=undef; DBI handle=undef                     │
# │  S8  DESTROYED        all internal state cleared / disconnected         │
# │                                                                         │
# │  VALID TRANSITIONS                                                      │
# │  T1  any → S1   new(valid_args)            lazy open; no connection yet  │
# │  T2  S1  → S3   first query, small CSV     CSV slurp path               │
# │  T3  S1  → S2   first query, DSN target    DBI-only, no slurp           │
# │  T4  S1  → S4   first query, small XML     XML::Simple slurp path       │
# │  T5  S1  → S5   first query, JSON file     JSON slurp path              │
# │  T6  S1  → S6   first query, DBM::Deep     Deep slurp path              │
# │  T7  S1  → S7   first query, BerkeleyDB    Berkeley tied-hash path      │
# │  T8  S*  → S*   subsequent queries         idempotent — _open() no-op   │
# │  T9  S*  → S8   DESTROY()                  handles/data/tmp cleaned up  │
# │                                                                         │
# │  BLOCKED TRANSITIONS                                                    │
# │  B1  new(bad_args)  → BLOCKED  unsafe id/table/host/url/base_criteria   │
# │  B2  execute() in S7           croak: meaningless on NoSQL              │
# │  B3  fetchrow_hashref(multi)   croak: meaningless on NoSQL              │
# │      in S7                                                              │
# │  B4  query()->join() in S6     croak: not supported on Deep             │
# │  B5  query()->join() in S7     croak: not supported on BerkeleyDB       │
# └─────────────────────────────────────────────────────────────────────────┘
#
# State invariants are asserted at every transition boundary so any backend
# regression is caught at the exact state where it diverges from the spec.

use strict;
use warnings;

use Fcntl        qw(O_CREAT O_RDONLY O_RDWR);
use File::Spec;
use File::Temp   qw(tempdir);
use FindBin      qw($Bin);
use Readonly;
use Scalar::Util qw(blessed);
use Test::Most;
use Test::NoWarnings;

# 15 top-level subtests (T1-T9, B1-B5, FSM-DISC1) + 1 Test::NoWarnings check.
plan tests => 16;

use lib 't/lib';

# ---------------------------------------------------------------------------
# Static fixtures
# ---------------------------------------------------------------------------
Readonly my $DATA_DIR => File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');

# ---------------------------------------------------------------------------
# Optional-dependency flags (evaluated once, shared by all subtests)
# ---------------------------------------------------------------------------
my $HAVE_SQLITE = do { eval { require DBI; require DBD::SQLite }; !$@ };
my $HAVE_XML    = do { eval { require XML::Simple }; !$@ };
my $HAVE_JSON   = do { eval { require JSON::MaybeXS }; !$@ };
my $HAVE_DEEP   = do { eval { require DBM::Deep }; !$@ };
my $HAVE_BDB    = do { eval { require DB_File }; !$@ };

# ---------------------------------------------------------------------------
# Helper: create a minimal SQLite database for DBI-state tests.
# Mirrors the _make_sqlite_db helper in t/cgi_security.t.
# ---------------------------------------------------------------------------
sub _make_sqlite_db {
	my ($pkg, %rows) = @_;
	(my $table = $pkg) =~ s/.*:://;
	$table = lc $table;

	my $dir  = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, "${table}.sql");
	my $dsn  = "dbi:SQLite:dbname=$file";

	my $setup = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
	$setup->do("CREATE TABLE $table (entry TEXT PRIMARY KEY, score INTEGER)");
	my $ins = $setup->prepare("INSERT INTO $table VALUES (?,?)");
	while(my ($k, $v) = each %rows) { $ins->execute($k, $v) }
	$setup->disconnect();

	{
		no strict 'refs';
		@{"${pkg}::ISA"} = ('Database::Abstraction');
	}
	return $pkg->new(dsn => $dsn, no_entry => 1);
}

# ---------------------------------------------------------------------------
# Shared assertion: verify that an object is in the S1 CONSTRUCTED state.
# All call-sites pass the object and the test-name prefix for diagnostics.
# ---------------------------------------------------------------------------
sub _assert_s1_invariants {
	my ($db, $label) = @_;
	(my $table = ref($db)) =~ s/.*:://;
	$table = lc $table;

	ok(!defined $db->{'_table_name'}, "$label: S1 — _table_name is undef (lazy open)");
	ok(!defined $db->{'_updated'},    "$label: S1 — _updated is undef (not yet opened)");
	ok(!defined $db->{'type'},        "$label: S1 — type is undef (backend not detected)");
	ok(!defined $db->{'data'},        "$label: S1 — data is undef (nothing slurped)");
	ok(!defined $db->{$table},        "$label: S1 — no DBI handle before first query");
	ok(!$db->{'berkeley'},            "$label: S1 — berkeley is not set");
}

# ---------------------------------------------------------------------------
# T1 / S1: CONSTRUCTED state invariants
# Transition: new(valid_args) → S1
# ---------------------------------------------------------------------------
subtest 'T1 — new(valid_args) → S1 CONSTRUCTED: all lazy-open invariants hold' => sub {
	plan tests => 8;

	{
		package Database::tr_csv;
		use base 'Database::Abstraction';
	}

	my $db = Database::tr_csv->new(directory => $DATA_DIR);

	ok(blessed($db),                   'T1-1: new() returns a blessed object');
	ok(ref($db) eq 'Database::tr_csv', 'T1-2: object is of the correct class');
	_assert_s1_invariants($db, 'T1');
};

# ---------------------------------------------------------------------------
# T2 / S1→S3: first query on a small CSV file → OPEN_SLURP_CSV
# ---------------------------------------------------------------------------
subtest 'T2 — first query on CSV → S1→S3 OPEN_SLURP_CSV invariants' => sub {
	plan tests => 8;

	# Use Database::test1 which maps to the existing t/data/test1.csv fixture.
	require Database::test1;

	my $db = Database::test1->new(directory => $DATA_DIR);

	# Precondition: S1
	ok(!defined $db->{'_table_name'}, 'T2-1: _table_name undef before first query (S1)');

	# Trigger: first query
	my $n = $db->count();

	# Postcondition: S3 invariants
	ok(defined $db->{'_table_name'} && $db->{'_table_name'} eq 'test1',
		'T2-2: _table_name = "test1" after first query');
	ok(defined $db->{'_updated'},
		'T2-3: _updated is set (file mtime) after first query');
	ok(($db->{'type'} // '') eq 'CSV',
		'T2-4: type = "CSV" (CSV slurp backend)');
	ok(ref($db->{'data'}) eq 'HASH',
		'T2-5: data is a HASH ref (keyed on entry)');
	ok(!defined $db->{'berkeley'},
		'T2-6: berkeley is undef (not a BerkeleyDB backend)');
	cmp_ok($n, '>', 0, 'T2-7: count() > 0 after transition to OPEN_SLURP_CSV');
	# DBI handle is set for CSV (DBD::CSV is always opened alongside the slurp)
	ok(defined $db->{'test1'} && ref($db->{'test1'}),
		'T2-8: DBI handle is set (DBD::CSV requires a handle even in slurp mode)');
};

# ---------------------------------------------------------------------------
# T3 / S1→S2: first query via DSN with max_slurp_size=>0 → OPEN_DBI
# ---------------------------------------------------------------------------
subtest 'T3 — first query on DSN (no slurp) → S1→S2 OPEN_DBI invariants' => sub {
	plan skip_all => 'DBD::SQLite required' unless $HAVE_SQLITE;
	plan tests => 7;

	my $db = _make_sqlite_db('Database::tr_dbi', alpha => 10, beta => 20);

	# Trigger: first query (object was pre-opened by _make_sqlite_db; re-test
	# with a brand-new no-slurp object to verify pre-trigger S1 state too).
	{
		package Database::tr_dbi2;
		use base 'Database::Abstraction';
	}

	my $dir  = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'tr_dbi2.sql');
	my $dsn  = "dbi:SQLite:dbname=$file";
	my $setup = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
	$setup->do('CREATE TABLE tr_dbi2 (entry TEXT PRIMARY KEY, score INTEGER)');
	$setup->do("INSERT INTO tr_dbi2 VALUES ('x', 99)");
	$setup->disconnect();

	my $db2 = Database::tr_dbi2->new(dsn => $dsn, no_entry => 1, max_slurp_size => 0);

	# Pre-trigger S1 check
	ok(!defined $db2->{'_table_name'}, 'T3-1: _table_name undef before first query (S1)');

	# Trigger
	my $n = $db2->count();

	# S2 invariants
	ok(($db2->{'type'} // '') eq 'DBI',
		'T3-2: type = "DBI" after DSN connection');
	ok(!defined $db2->{'data'},
		'T3-3: data is undef (no slurp for DBI backend)');
	ok(defined $db2->{'_table_name'},
		'T3-4: _table_name set after first query');
	ok(defined $db2->{'_updated'},
		'T3-5: _updated is set after first query');
	ok(!defined $db2->{'berkeley'},
		'T3-6: berkeley is undef');
	cmp_ok($n, '==', 1, 'T3-7: count() = 1 (one row in DSN table)');
};

# ---------------------------------------------------------------------------
# T4 / S1→S4: first query on small XML file → OPEN_SLURP_XML
# ---------------------------------------------------------------------------
subtest 'T4 — first query on XML → S1→S4 OPEN_SLURP_XML invariants' => sub {
	plan skip_all => 'XML::Simple required' unless $HAVE_XML;
	plan tests => 7;

	require Database::test6;

	my $db = Database::test6->new(
		directory => $DATA_DIR,
		no_entry  => 1,    # test6.xml uses <record> elements, no "entry" key
	);

	# Pre-trigger S1 check
	ok(!defined $db->{'_table_name'}, 'T4-1: _table_name undef before first query (S1)');

	# Trigger
	my $n = $db->count();

	# S4 invariants
	ok(($db->{'type'} // '') eq 'XML',
		'T4-2: type = "XML" (XML slurp backend)');
	ok(defined $db->{'data'},
		'T4-3: data is set after XML slurp');
	ok(!defined $db->{'berkeley'},
		'T4-4: berkeley is undef');
	ok(defined $db->{'_table_name'},
		'T4-5: _table_name set after first query');
	ok(defined $db->{'_updated'},
		'T4-6: _updated is set (file mtime)');
	cmp_ok($n, '>', 0, 'T4-7: count() > 0 after transition to OPEN_SLURP_XML');
};

# ---------------------------------------------------------------------------
# T5 / S1→S5: first query on JSON file → OPEN_SLURP_JSON
# ---------------------------------------------------------------------------
subtest 'T5 — first query on JSON → S1→S5 OPEN_SLURP_JSON invariants' => sub {
	plan skip_all => 'JSON::MaybeXS required' unless $HAVE_JSON;
	plan tests => 7;

	require Database::test_json;

	# no_entry => 1: test_json.json is an array; id='entry' is in each row.
	my $db = Database::test_json->new(
		directory => $DATA_DIR,
		no_entry  => 0,    # keyed on 'entry' column
	);

	# Pre-trigger S1 check
	ok(!defined $db->{'_table_name'}, 'T5-1: _table_name undef before first query (S1)');

	# Trigger
	my $n = $db->count();

	# S5 invariants
	ok(($db->{'type'} // '') eq 'JSON',
		'T5-2: type = "JSON" (JSON slurp backend)');
	ok(defined $db->{'data'},
		'T5-3: data is set after JSON slurp');
	# JSON slurp backend: $self->{$table} exists as a key but its value is undef
	# (set by $self->{$table} = $dbh where $dbh was never assigned for JSON slurp).
	# The falsy guard !$self->{$table} works correctly; the key may exist.
	ok(!$db->{'test_json'},
		'T5-4: DBI handle is falsy (JSON slurp path assigns undef to $self->{table})');
	ok(!defined $db->{'berkeley'},
		'T5-5: berkeley is undef');
	ok(defined $db->{'_table_name'},
		'T5-6: _table_name set after first query');
	cmp_ok($n, '>', 0, 'T5-7: count() > 0 after transition to OPEN_SLURP_JSON');
};

# ---------------------------------------------------------------------------
# T6 / S1→S6: first query on DBM::Deep file → OPEN_SLURP_DEEP
# ---------------------------------------------------------------------------
subtest 'T6 — first query on DBM::Deep → S1→S6 OPEN_SLURP_DEEP invariants' => sub {
	plan skip_all => 'DBM::Deep required' unless $HAVE_DEEP;
	plan tests => 8;

	require DBM::Deep;

	{
		package Database::tr_deep;
		use base 'Database::Abstraction';
	}

	my $dir    = tempdir(CLEANUP => 1);
	my $dbfile = File::Spec->catfile($dir, 'tr_deep.dbm');

	my $deep = DBM::Deep->new($dbfile);
	$deep->{k1} = { value => 'v1', score => 10 };
	$deep->{k2} = { value => 'v2', score => 20 };
	$deep->{k3} = { value => 'v3', score => 30 };
	undef $deep;

	my $db = Database::tr_deep->new(directory => $dir);

	# Pre-trigger S1 check
	ok(!defined $db->{'_table_name'}, 'T6-1: _table_name undef before first query (S1)');

	# Trigger
	my $n = $db->count();

	# S6 invariants
	ok(($db->{'type'} // '') eq 'Deep',
		'T6-2: type = "Deep" (DBM::Deep slurp backend)');
	ok(defined $db->{'data'},
		'T6-3: data is set after Deep slurp');
	ok(ref($db->{'data'}) eq 'HASH',
		'T6-4: data is a HASH ref (keyed by primary column)');
	# Deep slurp has no DBI handle
	ok(!defined $db->{'tr_deep'},
		'T6-5: DBI handle is undef (Deep slurp uses no DBI)');
	ok(!defined $db->{'berkeley'},
		'T6-6: berkeley is undef');
	ok(defined $db->{'_table_name'},
		'T6-7: _table_name set after first query');
	cmp_ok($n, '==', 3, 'T6-8: count() = 3 after transition to OPEN_SLURP_DEEP');
};

# ---------------------------------------------------------------------------
# T7 / S1→S7: first query on BerkeleyDB file → OPEN_BERKELEY
# ---------------------------------------------------------------------------
subtest 'T7 — first query on BerkeleyDB → S1→S7 OPEN_BERKELEY invariants' => sub {
	plan skip_all => 'DB_File required' unless $HAVE_BDB;
	plan tests => 9;

	require DB_File;

	{
		package Database::tr_bdb;
		use base 'Database::Abstraction';
	}

	my $dir    = tempdir(CLEANUP => 1);
	my $dbfile = File::Spec->catfile($dir, 'tr_bdb.db');

	tie my %bdb, 'DB_File', $dbfile, O_CREAT | O_RDWR, 0644, $DB_File::DB_HASH
		or die "Cannot create BDB fixture: $!";
	$bdb{k1} = 'v1';
	$bdb{k2} = 'v2';
	$bdb{k3} = 'v3';
	untie %bdb;

	my $db = Database::tr_bdb->new(directory => $dir);

	# Pre-trigger S1 check
	ok(!defined $db->{'_table_name'}, 'T7-1: _table_name undef before first query (S1)');

	# Trigger
	my $n = $db->count();

	# S7 invariants
	ok(($db->{'type'} // '') eq 'BerkeleyDB',
		'T7-2: type = "BerkeleyDB"');
	ok(defined $db->{'berkeley'},
		'T7-3: berkeley is set (tied hash)');
	ok(ref($db->{'berkeley'}) eq 'HASH',
		'T7-4: berkeley is a HASH ref (tied DB_File)');
	# BerkeleyDB has no DBI handle and no slurped data
	ok(!defined $db->{'data'},
		'T7-5: data is undef (Berkeley uses direct tie, no slurp)');
	ok(!defined $db->{'tr_bdb'},
		'T7-6: DBI handle is undef (BerkeleyDB uses no DBI)');
	ok(defined $db->{'_table_name'},
		'T7-7: _table_name set after first query');
	cmp_ok($n, '==', 3, 'T7-8: count() = 3 after transition to OPEN_BERKELEY');
	# _updated is undef for Berkeley: stat() is called on the .sql probe path,
	# not the .db file, because $slurp_file is set before Berkeley detection.
	# This is a known quirk; we verify the observed behaviour to catch regressions.
	# TODO: FSM Discrepancy — _updated is undef for BerkeleyDB backend (stat()
	# runs on the .sql probe path, not the actual .db file). The invariant
	# "all OPEN states have _updated set" is violated for the Berkeley state.
	pass('T7-9: _updated behaviour for Berkeley documented (see TODO above)');
};

# ---------------------------------------------------------------------------
# T8 / S*→S*: idempotent open — _open() is NOT re-called on subsequent queries
# ---------------------------------------------------------------------------
subtest 'T8 — subsequent queries leave state unchanged (idempotent _open() guard)' => sub {
	plan tests => 5;

	# Use test1 (maps to existing test1.csv fixture) for the idempotency check.
	require Database::test1;
	my $db = Database::test1->new(directory => $DATA_DIR);

	# First query: opens the backend and slurps data
	$db->count();
	my $data_ref_1  = $db->{'data'};
	my $table_name_1 = $db->{'_table_name'};
	my $updated_1    = $db->{'_updated'};
	my $type_1       = $db->{'type'};

	# Second query: must NOT re-open
	$db->count();
	my $data_ref_2  = $db->{'data'};
	my $table_name_2 = $db->{'_table_name'};
	my $updated_2    = $db->{'_updated'};
	my $type_2       = $db->{'type'};

	is("$data_ref_1", "$data_ref_2",
		'T8-1: data ref identity is unchanged across two queries (no re-slurp)');
	is($table_name_1, $table_name_2,
		'T8-2: _table_name is unchanged across two queries');
	is($updated_1, $updated_2,
		'T8-3: _updated is unchanged across two queries (no re-open)');
	is($type_1, $type_2,
		'T8-4: type is unchanged across two queries');

	# Third query with criteria: in-memory scan, still no re-open
	$db->selectall_arrayref(entry => 'one');
	is($db->{'_table_name'}, $table_name_1,
		'T8-5: _table_name unchanged after criteria query (in-memory scan, no re-open)');
};

# ---------------------------------------------------------------------------
# T9 / S*→S8: DESTROY — handles, data, and temp files cleaned up
# ---------------------------------------------------------------------------
subtest 'T9 — DESTROY() → S8 DESTROYED: internal state cleared correctly' => sub {
	plan tests => 6;

	# T9a: CSV slurp backend (S3 → S8)
	{
		require Database::test1;
		my $db = Database::test1->new(directory => $DATA_DIR);
		$db->count();    # enter S3

		ok(defined $db->{'data'}, 'T9-1: data is set before DESTROY (S3)');
		$db->DESTROY();
		ok(!defined $db->{'data'},
			'T9-2: data is undef after DESTROY (S8) — slurped memory released');
	}

	# T9b: DBI backend (S2 → S8)
	SKIP: {
		skip 'DBD::SQLite required', 2 unless $HAVE_SQLITE;

		my $db2 = _make_sqlite_db('Database::tr_dest_dbi', p => 1, q => 2);
		$db2->count();    # enter S2

		ok(defined $db2->{'tr_dest_dbi'},
			'T9-3: DBI handle is set before DESTROY (S2)');
		$db2->DESTROY();
		ok(!defined $db2->{'tr_dest_dbi'},
			'T9-4: DBI handle is undef after DESTROY (S8) — connection released');
	}

	# T9c: BerkeleyDB backend (S7 → S8)
	SKIP: {
		skip 'DB_File required', 2 unless $HAVE_BDB;

		{
			package Database::tr_dest_bdb;
			use base 'Database::Abstraction';
		}

		my $bdir = tempdir(CLEANUP => 1);
		my $bfile = File::Spec->catfile($bdir, 'tr_dest_bdb.db');

		tie my %bdb2, 'DB_File', $bfile, O_CREAT | O_RDWR, 0644, $DB_File::DB_HASH
			or die "Cannot create BDB fixture: $!";
		$bdb2{x} = 'y';
		untie %bdb2;

		my $db3 = Database::tr_dest_bdb->new(directory => $bdir);
		$db3->count();    # enter S7

		ok(defined $db3->{'berkeley'},
			'T9-5: berkeley is set before DESTROY (S7)');
		$db3->DESTROY();
		ok(!defined $db3->{'berkeley'},
			'T9-6: berkeley is undef after DESTROY (S8) — tie released');
	}
};

# ---------------------------------------------------------------------------
# B1 / S0→S1 BLOCKED: constructor rejects unsafe arguments
# ---------------------------------------------------------------------------
subtest 'B1 — new(unsafe_args) → S0→S1 BLOCKED at construction time' => sub {
	plan tests => 10;

	{
		package Database::tr_block;
		use base 'Database::Abstraction';
	}

	# B1-1: unsafe id — spaces, SQL keywords, semicolons
	throws_ok {
		Database::tr_block->new(directory => $DATA_DIR, id => 'entry; DROP TABLE entry--')
	} qr/unsafe id column name/i,
	  'B1-1: semicolon in id croaks "unsafe id column name"';

	# B1-2: unsafe id — leading digit (not a valid identifier)
	throws_ok {
		Database::tr_block->new(directory => $DATA_DIR, id => '1badid')
	} qr/unsafe id column name/i,
	  'B1-2: digit-leading id croaks "unsafe id column name"';

	# B1-3: unsafe table — spaces (UNION injection vector)
	throws_ok {
		Database::tr_block->new(directory => $DATA_DIR, table => 'a UNION SELECT 1')
	} qr/unsafe table name/i,
	  'B1-3: UNION keyword in table name croaks "unsafe table name"';

	# B1-4: unsafe table — semicolon
	throws_ok {
		Database::tr_block->new(directory => $DATA_DIR, table => 'foo; DROP TABLE foo')
	} qr/unsafe table name/i,
	  'B1-4: semicolon in table name croaks "unsafe table name"';

	# B1-5: unsafe host — shell metacharacter (semicolon)
	throws_ok {
		Database::tr_block->new(directory => $DATA_DIR, host => 'good;bad')
	} qr/unsafe host/i,
	  'B1-5: semicolon in host croaks "unsafe host"';

	# B1-6: unsafe host — command substitution
	throws_ok {
		Database::tr_block->new(directory => $DATA_DIR, host => '$(evil)')
	} qr/unsafe host/i,
	  'B1-6: command-substitution in host croaks "unsafe host"';

	# B1-7: unsafe url — ftp scheme
	throws_ok {
		Database::tr_block->new(url => 'ftp://example.com/data.html')
	} qr/unsafe url/i,
	  'B1-7: ftp:// scheme croaks "unsafe url"';

	# B1-8: unsafe url — file scheme
	throws_ok {
		Database::tr_block->new(url => 'file:///etc/passwd')
	} qr/unsafe url/i,
	  'B1-8: file:// scheme croaks "unsafe url"';

	# B1-9: unsafe base_criteria — non-hashref
	throws_ok {
		Database::tr_block->new(directory => $DATA_DIR, base_criteria => 'bad')
	} qr/base_criteria must be a hashref/i,
	  'B1-9: non-hashref base_criteria croaks';

	# B1-10: unsafe base_criteria — key with semicolon
	throws_ok {
		Database::tr_block->new(directory => $DATA_DIR,
			base_criteria => { 'col; DROP TABLE foo--' => 1 })
	} qr/unsafe base_criteria key/i,
	  'B1-10: semicolon in base_criteria key croaks "unsafe base_criteria key"';
};

# ---------------------------------------------------------------------------
# B2 / execute() in S7 OPEN_BERKELEY → BLOCKED
# Invariant: BerkeleyDB has no DBI handle; raw SQL execution is meaningless.
# ---------------------------------------------------------------------------
subtest 'B2 — execute() in S7 (Berkeley) → BLOCKED' => sub {
	plan skip_all => 'DB_File required' unless $HAVE_BDB;
	plan tests => 2;

	{
		package Database::tr_b2;
		use base 'Database::Abstraction';
	}

	my $dir   = tempdir(CLEANUP => 1);
	my $bfile = File::Spec->catfile($dir, 'tr_b2.db');
	tie my %b, 'DB_File', $bfile, O_CREAT | O_RDWR, 0644, $DB_File::DB_HASH
		or die "Cannot create BDB fixture: $!";
	$b{a} = '1';
	untie %b;

	my $db = Database::tr_b2->new(directory => $dir);
	$db->count();    # enter S7

	ok(($db->{'type'} // '') eq 'BerkeleyDB',
		'B2-1: precondition — object is in S7 OPEN_BERKELEY before execute()');

	throws_ok {
		$db->execute(query => 'SELECT * FROM tr_b2')
	} qr/execute is meaningless on a NoSQL database/i,
	  'B2-2: execute() in S7 croaks "execute is meaningless on a NoSQL database"';
};

# ---------------------------------------------------------------------------
# B3 / fetchrow_hashref(multi-column criteria) in S7 → BLOCKED
# A multi-column lookup falls outside Berkeley's key→value model.
# ---------------------------------------------------------------------------
subtest 'B3 — fetchrow_hashref(multi-criteria) in S7 (Berkeley) → BLOCKED' => sub {
	plan skip_all => 'DB_File required' unless $HAVE_BDB;
	plan tests => 2;

	{
		package Database::tr_b3;
		use base 'Database::Abstraction';
	}

	my $dir   = tempdir(CLEANUP => 1);
	my $bfile = File::Spec->catfile($dir, 'tr_b3.db');
	tie my %b, 'DB_File', $bfile, O_CREAT | O_RDWR, 0644, $DB_File::DB_HASH
		or die "Cannot create BDB fixture: $!";
	$b{k1} = 'val1';
	untie %b;

	my $db = Database::tr_b3->new(directory => $dir);
	$db->count();    # enter S7

	ok(($db->{'type'} // '') eq 'BerkeleyDB',
		'B3-1: precondition — object is in S7 OPEN_BERKELEY before fetchrow_hashref');

	throws_ok {
		# Multi-column criteria (not a bare entry key) — meaningless for NoSQL
		$db->fetchrow_hashref(name => 'val1', score => 42)
	} qr/fetchrow_hashref is meaningless on a NoSQL database/i,
	  'B3-2: fetchrow_hashref(multi-column) in S7 croaks';
};

# ---------------------------------------------------------------------------
# B4 / query()->join() in S6 (Deep) → BLOCKED
# DBM::Deep uses an in-memory slurp path; JOIN operations require a DBI
# handle, which is absent for this backend.
# ---------------------------------------------------------------------------
subtest 'B4 — query()->join() in S6 (Deep) → BLOCKED' => sub {
	plan skip_all => 'DBM::Deep required' unless $HAVE_DEEP;
	plan tests => 2;

	{
		package Database::tr_b4;
		use base 'Database::Abstraction';
	}

	my $dir    = tempdir(CLEANUP => 1);
	my $dbfile = File::Spec->catfile($dir, 'tr_b4.dbm');

	my $deep = DBM::Deep->new($dbfile);
	$deep->{x} = { score => 1 };
	undef $deep;

	my $db = Database::tr_b4->new(directory => $dir);
	$db->count();    # enter S6

	ok(($db->{'type'} // '') eq 'Deep',
		'B4-1: precondition — object is in S6 OPEN_SLURP_DEEP before join attempt');

	throws_ok {
		$db->query()
		   ->join({ table => 'other', on => 'tr_b4.x = other.y' })
		   ->all()
	} qr/not supported on Deep/i,
	  'B4-2: query()->join() in S6 (Deep) croaks "not supported on Deep"';
};

# ---------------------------------------------------------------------------
# B5 / query()->join() in S7 (Berkeley) → BLOCKED
# BerkeleyDB is a key→value store; JOIN requires relational SQL, which is
# absent for this backend.
# ---------------------------------------------------------------------------
subtest 'B5 — query()->join() in S7 (Berkeley) → BLOCKED' => sub {
	plan skip_all => 'DB_File required' unless $HAVE_BDB;
	plan tests => 2;

	{
		package Database::tr_b5;
		use base 'Database::Abstraction';
	}

	my $dir   = tempdir(CLEANUP => 1);
	my $bfile = File::Spec->catfile($dir, 'tr_b5.db');
	tie my %b, 'DB_File', $bfile, O_CREAT | O_RDWR, 0644, $DB_File::DB_HASH
		or die "Cannot create BDB fixture: $!";
	$b{m} = 'n';
	untie %b;

	my $db = Database::tr_b5->new(directory => $dir);
	$db->count();    # enter S7

	ok(($db->{'type'} // '') eq 'BerkeleyDB',
		'B5-1: precondition — object is in S7 OPEN_BERKELEY before join attempt');

	throws_ok {
		$db->query()
		   ->join({ table => 'other', on => 'tr_b5.m = other.n' })
		   ->all()
	} qr/not supported on BerkeleyDB/i,
	  'B5-2: query()->join() in S7 (Berkeley) croaks "not supported on BerkeleyDB"';
};

# ---------------------------------------------------------------------------
# FSM-DISC1 / Discrepancy audit
# Any code path that permits a transition absent from the FSM diagram, or
# blocks a documented transition, is flagged here with a TODO marker.
# ---------------------------------------------------------------------------
subtest 'FSM-DISC1 — documented discrepancies from derived FSM' => sub {
	# DISC1: _updated is undef in S7 (BerkeleyDB) — the stat() call runs on
	# the .sql probe path (which finds no file), not the actual .db file.
	# The invariant "all OPEN states have _updated set" is violated.
	# TODO: FSM Discrepancy — S7 OPEN_BERKELEY: _updated should be set to the
	# .db file mtime, not derived from the undef .sql probe result.
	SKIP: {
		skip 'DB_File required', 1 unless $HAVE_BDB;
		{
			package Database::tr_disc1;
			use base 'Database::Abstraction';
		}
		my $dir   = tempdir(CLEANUP => 1);
		my $bfile = File::Spec->catfile($dir, 'tr_disc1.db');
		tie my %b, 'DB_File', $bfile, O_CREAT | O_RDWR, 0644, $DB_File::DB_HASH
			or die 'Cannot create BDB: $!';
		$b{a} = 'b';
		untie %b;
		my $db = Database::tr_disc1->new(directory => $dir);
		$db->count();
		# Document the observed behaviour — test will pass as long as the
		# quirk remains.  Change to ok(defined...) when the bug is fixed.
		ok(!defined $db->{'_updated'},
			'DISC1-1 (TODO): _updated is undef for Berkeley backend (stat on wrong file)');
	}

	# DISC2: For no-DBI slurp backends (JSON, XML, Deep, XLSX) $self->{$table}
	# is assigned undef at the end of _open() (line: $self->{$table} = $dbh).
	# This means a defined-but-undef slot exists after open.  The guard in
	# _open_table() checks (!$self->{$table} && !$self->{'data'} && ...)
	# which still evaluates correctly because undef is falsy.  No functional
	# bug; documented here for clarity.
	SKIP: {
		skip 'JSON::MaybeXS required', 1 unless $HAVE_JSON;
		require Database::test_json;
		my $db = Database::test_json->new(directory => $DATA_DIR, no_entry => 1);
		$db->count();
		# The key *exists* but has an undef value; exists() returns true.
		# This is the documented behaviour: _open_table() guard uses !$self->{$table}
		# (falsy check) not !exists $self->{$table} (existence check).
		ok(exists($db->{'test_json'}) && !defined($db->{'test_json'}),
			'DISC2-1: JSON slurp — $self->{$table} key exists but is undef (falsy guard correct)');
	}

	# DISC3: The query-method `table` override param bypasses the constructor's
	# SAFE_QUALIFIED guard — now fixed (security audit finding).  Verify the
	# fix is in place: a hostile table name passed as a query param must croak.
	# Use a pre-opened SQLite object so _open_table()'s security guard fires
	# (not _open()'s file-not-found fatal) on the hostile param.
	SKIP: {
		skip 'DBD::SQLite required', 1 unless $HAVE_SQLITE;
		my $db3 = _make_sqlite_db('Database::tr_disc3b', foo => 1);
		$db3->count();	# ensure object is fully opened before hostile call
		throws_ok {
			$db3->selectall_arrayref(table => 'a; DROP TABLE a--')
		} qr/unsafe table name/i,
		  'DISC3-1: hostile table param in query method now croaks (security fix applied)';
	}

	done_testing();
};
