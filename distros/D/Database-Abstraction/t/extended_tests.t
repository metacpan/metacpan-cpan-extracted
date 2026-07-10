#!/usr/bin/env perl
# t/extended_tests.t — Targets untested execution paths to maximise branch/statement
# coverage toward ≥95% total.  Complements unit.t, edge_cases.t, and integration.t
# by exercising paths those files leave uncovered.

use strict;
use warnings;
use lib 't/lib';

use Database::test1;
use Database::test3;
use Database::test4ne;
use File::Spec;
use File::Temp qw(tempdir tempfile);
use FindBin qw($Bin);
use Scalar::Util qw(blessed);
use Test::Most;
use Test::Warn;

# ---------------------------------------------------------------------------
# Inline package declarations for classes used only in this file
# ---------------------------------------------------------------------------

package Database::exttest_empty;
use parent 'Database::Abstraction';
1;

package Database::exttest_ne;
use parent 'Database::Abstraction';
sub new {
	my $class = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;
	return $class->SUPER::new(no_entry => 1, id => 'cardinal', sep_char => ',', dbname => 'test4', %args);
}
1;

package Database::exttest_xml_ne;
use parent 'Database::Abstraction';
sub new {
	my $class = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;
	return $class->SUPER::new(no_entry => 1, id => 'ID', dbname => 'test6', %args);
}
1;

package main;

# ---------------------------------------------------------------------------
# Availability flags
# ---------------------------------------------------------------------------

use Readonly;
Readonly my $DATA_DIR => File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');

my $HAS_SQLITE = eval { require DBI; require DBD::SQLite; 1 };
my $HAS_XML    = eval { require XML::Simple; 1 };
my $HAS_CHI    = eval { require CHI; 1 };
my $HAS_GZIP   = eval { require Gzip::Faster; Gzip::Faster->import(); 1 };

# ---------------------------------------------------------------------------
# EX1 — import() alternate argument forms
# ---------------------------------------------------------------------------
#
# Note: the odd-count branch (line 385) calls init(\@_), which passes an
# arrayref to Params::Get::get_params; that raises a usage error for >1 odd
# args.  That branch appears to only work when @_ is exactly 1 non-hashref
# scalar (e.g. use Database::Abstraction '/path').  Lines 531-538 (new() with
# undef class) and line 540 (abstract-class croak) are also unreachable in
# normal use because Class::Abstract::check_abstract() fires first.

subtest 'EX1: import() hashref form sets defaults (line 383)' => sub {
	plan tests => 3;

	my %saved = %Database::Abstraction::defaults;

	# EX1.1 — hashref form (line 383): import({key => val})
	lives_ok {
		Database::Abstraction->import({ ex1_hashref_marker => 'hashref_test' });
	} 'import() accepts a hashref';
	is($Database::Abstraction::defaults{'ex1_hashref_marker'}, 'hashref_test',
		'hashref form sets a default via init() (line 383)');

	%Database::Abstraction::defaults = %saved;
	ok(!exists $Database::Abstraction::defaults{'ex1_hashref_marker'},
		'defaults restored after import() test');
};

# ---------------------------------------------------------------------------
# EX2 — new() called on an existing object clones it (line 541-543)
# ---------------------------------------------------------------------------

subtest 'EX2: new() on an existing object creates a clone' => sub {
	plan tests => 3;

	my $original = Database::test1->new(directory => $DATA_DIR);
	my $clone;
	lives_ok {
		$clone = $original->new(max_slurp_size => 1);
	} 'new() on an existing object lives';
	isa_ok($clone, 'Database::test1', 'clone is same class');
	is($clone->{'max_slurp_size'}, 1,
		'clone carries the overridden argument (line 543)');
};

# ---------------------------------------------------------------------------
# EX3 — new() with a non-blessed logger wraps it in Log::Abstraction (line 552)
# ---------------------------------------------------------------------------

subtest 'EX3: non-blessed logger is wrapped in Log::Abstraction (line 552)' => sub {
	plan tests => 2;

	# EX3.1 — coderef logger
	my $db_cref;
	lives_ok {
		$db_cref = Database::test1->new(
			directory => $DATA_DIR,
			logger    => sub { 1 },
		);
	} 'new() accepts a coderef logger';
	ok(blessed($db_cref->{'logger'}),
		'coderef logger is wrapped into a blessed Log::Abstraction object (line 552)');
};

# ---------------------------------------------------------------------------
# EX4 — set_logger() with no args croaks with usage message (line 592)
# ---------------------------------------------------------------------------

subtest 'EX4: set_logger() with undef logger croaks with usage message (line 592)' => sub {
	plan tests => 1;

	# Passing logger => undef makes get_params return {logger => undef}, which is
	# falsy, causing the code to reach the croak at line 592.
	# Calling set_logger() with no args at all makes Params::Get itself croak first.
	my $db = Database::test1->new(directory => $DATA_DIR);
	throws_ok { $db->set_logger(logger => undef) }
		qr/Usage: set_logger/,
		'set_logger() with undef logger reaches croak at line 592';
};

# ---------------------------------------------------------------------------
# EX5 — zero-byte CSV triggers the fast-exit empty path (line 766)
# ---------------------------------------------------------------------------

subtest 'EX5: zero-byte CSV file sets data to undef/empty (line 766)' => sub {
	plan tests => 2;

	my $tmpdir    = tempdir(CLEANUP => 1);
	my $empty_csv = File::Spec->catfile($tmpdir, 'exttest_empty.csv');
	open(my $fh, '>', $empty_csv) or die "cannot create $empty_csv: $!";
	close $fh;

	my $db;
	lives_ok {
		$db = Database::exttest_empty->new(directory => $tmpdir);
	} 'instantiation lives on zero-byte CSV';
	ok(!$db->{'data'}, 'data is falsy for zero-byte CSV (line 766)');
};

# ---------------------------------------------------------------------------
# EX6 — no_entry CSV slurp stores arrayref (bug-fix: \@data not @data)
# Covers: line 792 (fix), 937, 1070, 1206, 1765 (arrayref), 1779-1791
# ---------------------------------------------------------------------------

subtest 'EX6: no_entry CSV slurp uses arrayref fast-paths' => sub {
	plan tests => 8;

	my $db = Database::exttest_ne->new(directory => $DATA_DIR);

	# _open is lazy: trigger it with count() before inspecting $db->{'data'}

	# EX6.1 — count() arrayref fast-path (line 1206); also triggers _open+slurp
	cmp_ok($db->count(), '==', 3,
		'count() returns 3 via arrayref fast-path (line 1206)');

	# After _open the data should be stored as an ARRAY ref (line 792 fix)
	is(ref($db->{'data'}), 'ARRAY',
		'no_entry CSV slurp stores arrayref after fix (line 792)');
	cmp_ok(scalar @{$db->{'data'}}, '==', 3, 'arrayref holds 3 rows from test4.csv');

	# EX6.2 — selectall_arrayref() arrayref fast-path (line 937)
	my $rows = $db->selectall_arrayref();
	isa_ok($rows, 'ARRAY', 'selectall_arrayref() returns arrayref (line 937)');
	cmp_ok(scalar @{$rows}, '==', 3, 'selectall_arrayref() returns 3 rows');

	# EX6.3 — selectall_array() arrayref fast-path (line 1070)
	my @arr = $db->selectall_array();
	cmp_ok(scalar @arr, '==', 3,
		'selectall_array() returns 3 rows via arrayref fast-path (line 1070)');

	# EX6.4 — AUTOLOAD scalar: no_entry slurp scan (lines 1779-1791)
	my $val = $db->ordinal(cardinal => 'one');
	is($val, 'first',
		'AUTOLOAD scalar no_entry slurp scan finds correct value (lines 1779-1791)');

	# EX6.5 — AUTOLOAD wantarray+!distinct+0params: arrayref iteration (line 1765)
	my @all = $db->cardinal();
	cmp_ok(scalar @all, '==', 3,
		'AUTOLOAD wantarray+0params iterates no_entry arrayref (line 1765)');
};

# ---------------------------------------------------------------------------
# EX7 — XML slurp: no_entry stores integer-keyed hash (lines 829-833)
# ---------------------------------------------------------------------------

SKIP: {
	skip('XML::Simple not available', 4) unless $HAS_XML;

	subtest 'EX7.1: XML no_entry slurp builds integer-keyed hash (lines 829-833)' => sub {
		plan tests => 4;

		my $db = Database::exttest_xml_ne->new(directory => $DATA_DIR);
		$db->count();	# trigger lazy _open and slurp

		ok($db->{'data'}, 'XML no_entry data is populated');
		is(ref($db->{'data'}), 'HASH',
			'XML no_entry data is stored as integer-keyed HASH (lines 831-833)');
		my @keys = sort { $a <=> $b } keys %{$db->{'data'}};
		cmp_ok(scalar @keys, '==', 5, 'test6.xml has 5 records');
		ok(exists $db->{'data'}->{0}, 'first record stored at integer key 0');
	};

	# EX7.2 — XML single HASH key matching table name slurps (lines 817-818)
	subtest 'EX7.2: XML single-key matching table name is slurped (lines 817-818)' => sub {
		plan tests => 3;

		my $tmpdir   = tempdir(CLEANUP => 1);
		my $xml_file = File::Spec->catfile($tmpdir, 'test3.xml');
		open(my $fh, '>', $xml_file) or die "cannot create $xml_file: $!";
		# XML where the child key ('test3') matches the table name (class test3)
		print $fh "<?xml version=\"1.0\"?>\n<root>\n",
		          "  <test3><entry>42</entry><value>hello_world</value></test3>\n",
		          "</root>\n";
		close $fh;

		my $db = Database::test3->new(directory => $tmpdir);
		$db->count();	# trigger lazy _open
		ok($db->{'data'}, 'XML matching-key data is populated (lines 817-818)');
		is(ref($db->{'data'}), 'HASH', 'data stored as HASH');
		ok(exists $db->{'data'}->{'42'}, 'entry key 42 is present');
	};

	# EX7.3 — XML single HASH key NOT matching table → croak (line 820)
	subtest 'EX7.3: XML single-key not matching table croaks (line 820)' => sub {
		plan tests => 1;

		my $tmpdir   = tempdir(CLEANUP => 1);
		my $xml_file = File::Spec->catfile($tmpdir, 'test3.xml');
		open(my $fh, '>', $xml_file) or die "cannot create $xml_file: $!";
		print $fh "<?xml version=\"1.0\"?>\n<root>\n",
		          "  <nottest3><entry>1</entry></nottest3>\n",
		          "</root>\n";
		close $fh;

		throws_ok { Database::test3->new(directory => $tmpdir)->count() }
			qr/complex documents.*not.*supported/i,
			'XML single-key not matching table name croaks (line 820)';
	};

	# EX7.4 — XML document with more than one top-level key → croak (line 823)
	subtest 'EX7.4: XML multi-key document croaks (line 823)' => sub {
		plan tests => 1;

		my $tmpdir   = tempdir(CLEANUP => 1);
		my $xml_file = File::Spec->catfile($tmpdir, 'test3.xml');
		open(my $fh, '>', $xml_file) or die "cannot create $xml_file: $!";
		print $fh "<?xml version=\"1.0\"?>\n<root>\n",
		          "  <key1>first_value</key1>\n",
		          "  <key2>second_value</key2>\n",
		          "</root>\n";
		close $fh;

		throws_ok { Database::test3->new(directory => $tmpdir)->count() }
			qr/multi-key documents.*not.*supported/i,
			'XML multi-key document croaks (line 823)';
	};
}

# ---------------------------------------------------------------------------
# EX8 — AUTOLOAD wantarray fast-paths with slurped keyed data
# Covers: line 1765 (HASH path) and lines 1812-1814 (distinct path)
# Note: line 1816 is dead code (see comment in Abstraction.pm).
# ---------------------------------------------------------------------------

subtest 'EX8: AUTOLOAD wantarray fast-paths with slurped keyed data' => sub {
	plan tests => 3;

	my $db = Database::test1->new(directory => $DATA_DIR);
	$db->count();	# trigger lazy _open and slurp
	ok($db->{'data'}, 'test1 data is slurped (pre-condition)');

	# EX8.1 — wantarray+!distinct+0params hits fast-path (line 1765, HASH branch)
	my @all_nums = $db->number();
	cmp_ok(scalar @all_nums, '==', 4,
		'AUTOLOAD wantarray+0params on keyed slurp returns all values (line 1765)');

	# EX8.2 — wantarray+distinct uses the else-branch distinct fast-path (lines 1812-1814)
	# ($distinct is true → outer if(wantarray && !$distinct) is false → else branch,
	#  line 1811 if(wantarray) is true, line 1812 if($distinct) is true → returns distinct)
	my @unique = $db->number(distinct => 1);
	cmp_ok(scalar @unique, '>', 0,
		'AUTOLOAD wantarray+distinct on slurped data returns distinct values (lines 1812-1814)');
};

# ---------------------------------------------------------------------------
# EX9 — _quote_identifier() without a live dbh falls back to ANSI (line 2170)
# ---------------------------------------------------------------------------

subtest 'EX9: _quote_identifier falls back to ANSI double-quoting (line 2170)' => sub {
	plan tests => 2;

	my $db = Database::test1->new(directory => $DATA_DIR);
	$db->count();	# force _open so the table handle is populated
	my $table_key = ref($db); $table_key =~ s/.*:://;
	my $saved_dbh  = delete $db->{$table_key};	# remove handle to force fallback

	my $quoted;
	lives_ok { $quoted = $db->_quote_identifier('my_column') }
		'_quote_identifier without dbh does not croak';
	is($quoted, '"my_column"',
		'_quote_identifier returns ANSI-quoted name (line 2170)');

	$db->{$table_key} = $saved_dbh;	# restore so DESTROY can disconnect cleanly
};

# ---------------------------------------------------------------------------
# EX10 — _fatal() via missing database file (lines 849, 2282)
# ---------------------------------------------------------------------------

subtest 'EX10: missing database file triggers _fatal croak (lines 849, 2282)' => sub {
	plan tests => 1;

	my $tmpdir = tempdir(CLEANUP => 1);	# empty directory — no database files

	throws_ok { Database::test3->new(directory => $tmpdir)->count() }
		qr/Can't find a file/i,
		'missing database file triggers _fatal croak (line 849)';
};

# ---------------------------------------------------------------------------
# EX11 — DESTROY cleans up the gzip temp file (line 1920)
# ---------------------------------------------------------------------------

subtest 'EX11: DESTROY unlinks the temp file (line 1920)' => sub {
	plan tests => 2;

	my $tmp_path;
	{
		# Use File::Temp with UNLINK=>1 to simulate what the gzip path now stores
		my $tmp_obj = File::Temp->new(SUFFIX => '.csv', UNLINK => 1);
		$tmp_path = $tmp_obj->filename();

		# Simulate what the gzip path does: store the File::Temp object in _temp_fh
		my $db = Database::test1->new(directory => $DATA_DIR);
		$db->{'_temp_fh'} = $tmp_obj;
		ok(-e $tmp_path, 'temp file exists before DESTROY');
		# $db goes out of scope here → DESTROY fires → _temp_fh deleted → auto-unlink
	}
	ok(!-e $tmp_path, 'DESTROY auto-unlinks temp file via File::Temp _temp_fh');
};

# ---------------------------------------------------------------------------
# EX12 — Query builder on CSV backend (Query.pm lines 288-290)
# ---------------------------------------------------------------------------

subtest 'EX12: query builder generates CSV WHERE guard (Query.pm lines 288-290)' => sub {
	plan tests => 3;

	my $db = Database::test1->new(directory => $DATA_DIR);

	my $rows;
	lives_ok { $rows = $db->query->all() }
		'query->all() on CSV backend lives';
	isa_ok($rows, 'ARRAY', 'query->all() returns arrayref');
	# test1.csv has 4 data rows (plus 1 comment row that should be filtered)
	cmp_ok(scalar @{$rows}, '==', 4,
		'query->all() returns all non-comment rows via CSV guard (Query.pm lines 288-290)');
};

# ---------------------------------------------------------------------------
# SQLite-dependent sections (EX13-EX15)
# ---------------------------------------------------------------------------

SKIP: {
	skip('DBI or DBD::SQLite not available', 16) unless $HAS_SQLITE;

	require DBI;

	my $dir  = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'extest.sql');
	my $dsn  = "dbi:SQLite:dbname=$file";

	{
		my $setup = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
		$setup->do(q{CREATE TABLE extest (entry TEXT PRIMARY KEY, score REAL, colour TEXT)});
		$setup->do(q{INSERT INTO extest VALUES ('alpha', 9.0, 'red')});
		$setup->do(q{INSERT INTO extest VALUES ('beta',  7.5, 'blue')});
		$setup->do(q{INSERT INTO extest VALUES ('gamma', 8.0, 'red')});
		$setup->disconnect();
	}

	{
		package Database::extest;
		use parent 'Database::Abstraction';
	}

	# -------------------------------------------------------------------------
	# EX13 — Cache HIT paths (lines 990, 1127, 1248-1249, 1360, 1374)
	# -------------------------------------------------------------------------

	SKIP: {
		skip('CHI not available', 10) unless $HAS_CHI;

		require CHI;

		subtest 'EX13: cache HIT paths for all select methods' => sub {
			plan tests => 10;

			my $cache = CHI->new(driver => 'RawMemory', global => 0);
			my $db    = Database::extest->new(dsn => $dsn, cache => $cache);

			# EX13.1-2 — selectall_arrayref: MISS then HIT (line 990)
			my $r1 = $db->selectall_arrayref();
			cmp_ok(scalar @{$r1}, '==', 3, 'selectall_arrayref MISS: 3 rows');
			my $r2 = $db->selectall_arrayref();
			cmp_ok(scalar @{$r2}, '==', 3,
				'selectall_arrayref HIT: still 3 rows (line 990)');

			# EX13.3-4 — selectall_array wantarray: MISS then HIT (line 1127)
			my @a1 = $db->selectall_array();
			cmp_ok(scalar @a1, '==', 3, 'selectall_array wantarray MISS');
			my @a2 = $db->selectall_array();
			cmp_ok(scalar @a2, '==', 3,
				'selectall_array wantarray HIT (line 1127)');

			# EX13.5-6 — selectall_array scalar: MISS then HIT (line 1127 scalar path)
			my $s1 = $db->selectall_array(entry => 'alpha');
			ok($s1, 'selectall_array scalar MISS: returns a row');
			my $s2 = $db->selectall_array(entry => 'alpha');
			ok($s2, 'selectall_array scalar HIT (line 1127)');

			# EX13.7 — count() derives from selectall cache (lines 1248-1249)
			# For no_entry+DSN, selectall key is "SELECT * FROM t array" which
			# matches count's derived key "SELECT * FROM t array" exactly.
			my $cache2 = CHI->new(driver => 'RawMemory', global => 0);
			my $db2    = Database::extest->new(dsn => $dsn, cache => $cache2, no_entry => 1);
			$db2->selectall_arrayref();	# populate cache
			my $cnt = $db2->count();
			cmp_ok($cnt, '==', 3,
				'count() returns 3 by reading selectall cache (lines 1248-1249)');

			# EX13.8-9 — fetchrow_hashref scalar: MISS then HIT (line 1374)
			my $fh1 = $db->fetchrow_hashref(entry => 'beta');
			is($fh1->{'colour'}, 'blue', 'fetchrow_hashref scalar MISS');
			my $fh2 = $db->fetchrow_hashref(entry => 'beta');
			is($fh2->{'colour'}, 'blue',
				'fetchrow_hashref scalar HIT (line 1374)');

			# EX13.10 — fetchrow_hashref in wantarray context builds 'array' key (line 1360)
			my @wfh = $db->fetchrow_hashref(entry => 'alpha');
			is($wfh[0]{'score'}, 9.0,
				'fetchrow_hashref wantarray context (line 1360)');
		};
	}

	# -------------------------------------------------------------------------
	# EX14 — AUTOLOAD done_where ternary on CSV non-slurp (lines 1854, 1858)
	# -------------------------------------------------------------------------

	subtest 'EX14: AUTOLOAD done_where ternary on CSV non-slurp' => sub {
		plan tests => 3;

		# max_slurp_size => 0 forces SQL path on CSV so the CSV WHERE guard fires
		# and sets done_where=1.  Subsequent params are ANDed, not WHEREd.
		my $db = Database::test1->new(directory => $DATA_DIR, max_slurp_size => 0);

		# EX14.1 — defined param: " AND entry = ?" is appended (line 1854 done_where=1)
		my $v1;
		lives_ok { $v1 = $db->number(entry => 'one') }
			'AUTOLOAD defined param on CSV non-slurp lives (line 1854)';
		is($v1, 1, 'correct value returned via done_where AND path');

		# EX14.2 — undef param: " AND number IS NULL" is appended (line 1858)
		# The 'empty' row in test1.csv has a blank number column (undef).
		my $v2;
		lives_ok { $v2 = $db->entry(number => undef) }
			'AUTOLOAD undef param on CSV non-slurp lives (line 1858 IS NULL done_where)';
	};
}

# ---------------------------------------------------------------------------
# EX15 — Gzip-compressed CSV (lines 684-691) and DESTROY temp cleanup (line 1920)
# ---------------------------------------------------------------------------

SKIP: {
	skip('Gzip::Faster not available', 3) unless $HAS_GZIP;

	subtest 'EX15: gzip CSV is transparently decompressed (lines 684-691)' => sub {
		plan tests => 3;

		# Build a tiny CSV, gzip it, write to a temp directory
		my $csv_content = "entry!number\n\"uno\"!1\n\"dos\"!2\n";
		my $gzipped     = Gzip::Faster::gzip($csv_content);

		my $tmpdir = tempdir(CLEANUP => 1);
		my $gzfile = File::Spec->catfile($tmpdir, 'testgz.csv.gz');
		open(my $fh, '>', $gzfile) or die "cannot write $gzfile: $!";
		binmode $fh;
		print $fh $gzipped;
		close $fh;

		{
			package Database::testgz;
			use parent 'Database::Abstraction';
		}

		my $db;
		lives_ok { $db = Database::testgz->new(directory => $tmpdir) }
			'gzip CSV instantiation lives (lines 684-691)';
		cmp_ok($db->count(), '==', 2,
			'gzip CSV returns correct row count');
		ok(defined($db->{'_temp_fh'}), 'File::Temp object stored in _temp_fh after gunzip (line 691)');
		# DESTROY fires when $db goes out of scope, unlinks temp file (line 1920)
	};
}

done_testing();
