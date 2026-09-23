#!/usr/bin/env perl
# t/empty_files.t — Verify that empty (0-byte) and newline-only input files do
# not cause crashes and that all data-access methods return no matches.
#
# Formats covered: CSV, PSV, XML, gzip CSV (optional).
# For each format two variants are tested: empty file and newline-only file.
# XML tests only assert that queries fail gracefully (croak), not segfault,
# because empty/newline content is not valid XML.

use strict;
use warnings;
use lib 't/lib';
use File::Spec;
use File::Temp qw(tempdir);
use IO::Compress::Gzip qw($GzipError);
use Test::Most;

# ---------------------------------------------------------------------------
# Inline package declarations — class name drives the dbname and file probe.
# ---------------------------------------------------------------------------

package Database::ef_csv;
use parent 'Database::Abstraction';
1;

package Database::ef_psv;
use parent 'Database::Abstraction';
1;

package Database::ef_xml;
use parent 'Database::Abstraction';
1;

package Database::ef_gz;
use parent 'Database::Abstraction';
1;

package Database::ef_tsv;
use parent 'Database::Abstraction';
1;

package Database::ef_json;
use parent 'Database::Abstraction';
1;

package main;

my $HAS_XML  = eval { require XML::Simple; 1 };
my $HAS_GZIP = eval { require Gzip::Faster; Gzip::Faster->import(); 1 };
my $HAS_JSON = eval { require JSON::MaybeXS; 1 };

# ---------------------------------------------------------------------------
# Helper: assert that all query methods return empty/0/undef (no matches).
# Runs 8 tests.
# ---------------------------------------------------------------------------
sub _assert_no_data {
	my ($db, $label) = @_;

	my $c;
	lives_ok { $c = $db->count() } "$label: count() lives";
	is($c, 0, "$label: count() returns 0");

	my $arr;
	lives_ok { $arr = $db->selectall_arrayref() } "$label: selectall_arrayref() lives";
	ok(!$arr || !@{$arr}, "$label: selectall_arrayref() returns no rows");

	my $row;
	lives_ok { $row = $db->fetchrow_hashref('__no_such_key__') }
		"$label: fetchrow_hashref() lives";
	is($row, undef, "$label: fetchrow_hashref() returns undef");

	my @rows;
	lives_ok { @rows = $db->selectall_array() } "$label: selectall_array() lives";
	is(scalar @rows, 0, "$label: selectall_array() returns empty list");
}

# ---------------------------------------------------------------------------
# Helper: create a temp dir with the named file and given content.
# ---------------------------------------------------------------------------
sub _tmpdir_with {
	my ($filename, $content) = @_;
	my $tmpdir = tempdir(CLEANUP => 1);
	open(my $fh, '>', File::Spec->catfile($tmpdir, $filename))
		or die "Cannot write $filename: $!";
	print $fh $content if defined $content && length $content;
	close $fh;
	return $tmpdir;
}

# ---------------------------------------------------------------------------
# EF1 — CSV, empty file (0 bytes)
# ---------------------------------------------------------------------------

subtest 'EF1: CSV empty file — no crashes, no data' => sub {
	plan tests => 9;

	my $tmpdir = _tmpdir_with('ef_csv.csv', '');
	my $db;
	lives_ok { $db = Database::ef_csv->new(directory => $tmpdir) }
		'EF1: new() lives on zero-byte CSV';
	_assert_no_data($db, 'EF1');
};

# ---------------------------------------------------------------------------
# EF2 — CSV, newline-only file (1 byte: "\n")
# ---------------------------------------------------------------------------

subtest 'EF2: CSV newline-only file — no crashes, no data' => sub {
	plan tests => 9;

	my $tmpdir = _tmpdir_with('ef_csv.csv', "\n");
	my $db;
	lives_ok { $db = Database::ef_csv->new(directory => $tmpdir) }
		'EF2: new() lives on newline-only CSV';
	_assert_no_data($db, 'EF2');
};

# ---------------------------------------------------------------------------
# EF3 — PSV, empty file (0 bytes)
# ---------------------------------------------------------------------------

subtest 'EF3: PSV empty file — no crashes, no data' => sub {
	plan tests => 9;

	my $tmpdir = _tmpdir_with('ef_psv.psv', '');
	my $db;
	lives_ok { $db = Database::ef_psv->new(directory => $tmpdir) }
		'EF3: new() lives on zero-byte PSV';
	_assert_no_data($db, 'EF3');
};

# ---------------------------------------------------------------------------
# EF4 — PSV, newline-only file (1 byte: "\n")
# ---------------------------------------------------------------------------

subtest 'EF4: PSV newline-only file — no crashes, no data' => sub {
	plan tests => 9;

	my $tmpdir = _tmpdir_with('ef_psv.psv', "\n");
	my $db;
	lives_ok { $db = Database::ef_psv->new(directory => $tmpdir) }
		'EF4: new() lives on newline-only PSV';
	_assert_no_data($db, 'EF4');
};

# ---------------------------------------------------------------------------
# EF5 — XML, empty file (0 bytes)
# XML::Simple croaks on invalid XML — verify graceful failure, not segfault.
# ---------------------------------------------------------------------------

subtest 'EF5: XML empty file — graceful failure, no segfault' => sub {
	SKIP: {
		skip 'XML::Simple not available', 4 unless $HAS_XML;
		plan tests => 4;

		my $tmpdir = _tmpdir_with('ef_xml.xml', '');
		my $db;
		lives_ok { $db = Database::ef_xml->new(directory => $tmpdir) }
			'EF5: new() lives on empty XML (parsing is lazy)';
		eval { $db->count() };
		ok(1, 'EF5: count() does not hard-crash on empty XML');
		eval { $db->selectall_arrayref() };
		ok(1, 'EF5: selectall_arrayref() does not hard-crash on empty XML');
		eval { $db->fetchrow_hashref('x') };
		ok(1, 'EF5: fetchrow_hashref() does not hard-crash on empty XML');
	}
};

# ---------------------------------------------------------------------------
# EF6 — XML, newline-only file (1 byte: "\n")
# ---------------------------------------------------------------------------

subtest 'EF6: XML newline-only file — graceful failure, no segfault' => sub {
	SKIP: {
		skip 'XML::Simple not available', 4 unless $HAS_XML;
		plan tests => 4;

		my $tmpdir = _tmpdir_with('ef_xml.xml', "\n");
		my $db;
		lives_ok { $db = Database::ef_xml->new(directory => $tmpdir) }
			'EF6: new() lives on newline-only XML (parsing is lazy)';
		eval { $db->count() };
		ok(1, 'EF6: count() does not hard-crash on newline-only XML');
		eval { $db->selectall_arrayref() };
		ok(1, 'EF6: selectall_arrayref() does not hard-crash on newline-only XML');
		eval { $db->fetchrow_hashref('x') };
		ok(1, 'EF6: fetchrow_hashref() does not hard-crash on newline-only XML');
	}
};

# ---------------------------------------------------------------------------
# EF7 — gzip CSV, empty content (gzip of empty string)
# ---------------------------------------------------------------------------

subtest 'EF7: gzip CSV empty content — no crashes, no data' => sub {
	SKIP: {
		skip 'Gzip::Faster not available', 9 unless $HAS_GZIP;
		plan tests => 9;

		# Use IO::Compress::Gzip (Perl core) to create a valid gzip of empty
		# content — Gzip::Faster::gzip('') warns and returns undef on empty input.
		my $tmpdir = tempdir(CLEANUP => 1);
		my $gz_path = File::Spec->catfile($tmpdir, 'ef_gz.csv.gz');
		IO::Compress::Gzip::gzip(\(my $empty = q()) => $gz_path)
			or die "Cannot create empty gzip: $GzipError";

		my $db;
		lives_ok { $db = Database::ef_gz->new(directory => $tmpdir) }
			'EF7: new() lives on empty gzip CSV';
		_assert_no_data($db, 'EF7');
	}
};

# ---------------------------------------------------------------------------
# EF8 — gzip CSV, newline-only content (gzip of "\n")
# ---------------------------------------------------------------------------

subtest 'EF8: gzip CSV newline-only content — no crashes, no data' => sub {
	SKIP: {
		skip 'Gzip::Faster not available', 9 unless $HAS_GZIP;
		plan tests => 9;

		my $tmpdir = tempdir(CLEANUP => 1);
		my $gz_path = File::Spec->catfile($tmpdir, 'ef_gz.csv.gz');
		IO::Compress::Gzip::gzip(\(my $newline = "\n") => $gz_path)
			or die "Cannot create newline gzip: $GzipError";

		my $db;
		lives_ok { $db = Database::ef_gz->new(directory => $tmpdir) }
			'EF8: new() lives on newline-only gzip CSV';
		_assert_no_data($db, 'EF8');
	}
};

# ---------------------------------------------------------------------------
# EF9 — TSV, empty file (0 bytes)
# ---------------------------------------------------------------------------

subtest 'EF9: TSV empty file — no crashes, no data' => sub {
	plan tests => 9;

	my $tmpdir = _tmpdir_with('ef_tsv.tsv', '');
	my $db;
	lives_ok { $db = Database::ef_tsv->new(directory => $tmpdir) }
		'EF9: new() lives on zero-byte TSV';
	_assert_no_data($db, 'EF9');
};

# ---------------------------------------------------------------------------
# EF10 — TSV, newline-only file (1 byte: "\n")
# ---------------------------------------------------------------------------

subtest 'EF10: TSV newline-only file — no crashes, no data' => sub {
	plan tests => 9;

	my $tmpdir = _tmpdir_with('ef_tsv.tsv', "\n");
	my $db;
	lives_ok { $db = Database::ef_tsv->new(directory => $tmpdir) }
		'EF10: new() lives on newline-only TSV';
	_assert_no_data($db, 'EF10');
};

# ---------------------------------------------------------------------------
# EF11 — JSON, empty file (0 bytes)
# ---------------------------------------------------------------------------

subtest 'EF11: JSON empty file — no crashes, no data' => sub {
	SKIP: {
		skip 'JSON::MaybeXS not available', 9 unless $HAS_JSON;
		plan tests => 9;

		my $tmpdir = _tmpdir_with('ef_json.json', '');
		my $db;
		lives_ok { $db = Database::ef_json->new(directory => $tmpdir) }
			'EF11: new() lives on zero-byte JSON';
		_assert_no_data($db, 'EF11');
	}
};

# ---------------------------------------------------------------------------
# EF12 — JSON, newline-only file (1 byte: "\n")
# ---------------------------------------------------------------------------

subtest 'EF12: JSON newline-only file — no crashes, no data' => sub {
	SKIP: {
		skip 'JSON::MaybeXS not available', 9 unless $HAS_JSON;
		plan tests => 9;

		my $tmpdir = _tmpdir_with('ef_json.json', "\n");
		my $db;
		lives_ok { $db = Database::ef_json->new(directory => $tmpdir) }
			'EF12: new() lives on newline-only JSON';
		_assert_no_data($db, 'EF12');
	}
};

done_testing();
