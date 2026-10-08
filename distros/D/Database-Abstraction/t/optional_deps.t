#!/usr/bin/env perl
use strict;
use warnings;

# optional_deps.t — verifies graceful behaviour when optional modules are absent.
#
# Each section hides one optional module using Test::Without::Module, then
# confirms that:
#   (a) new() still returns an object (construction is always lazy), and
#   (b) the first query that would load the missing module either:
#       * croaks/dies with a clear "Can't locate" or module-specific message, OR
#       * falls back to an alternative code path that still returns correct data.
#
# (No Test::NoWarnings — hiding modules generates "Can't locate" die-strings
# that propagate as $@ strings through eval{}, not as Perl warnings; but for
# safety we avoid the NoWarnings END-hook interaction with any possible SKIP.)

use File::Spec;
use File::Temp qw(tempdir);
use Scalar::Util qw(blessed);
use Test::Mockingbird;
use Test::Most;
use Test::Returns;
use Test::Without::Module ();	# not applied globally yet

use HTTP::Response;
use lib 't/lib';
use Database::test1;	# test1.csv fixture
use Database::test3;	# test3.xml fixture

# ---------------------------------------------------------------------------
# Probe for optional modules once — results drive per-section SKIP decisions.
# Using eval {require} loads the module into %INC if present; we rely on
# Test::Without::Module->import() removing it from %INC before each section.
# ---------------------------------------------------------------------------
my $DATA_DIR   = File::Spec->catfile('t', 'data');
my $HAS_REDIS  = eval { require Redis::Fast; 1 } || eval { require Redis; 1 };
my $HAS_RFAST  = defined $INC{'Redis/Fast.pm'};
my $HAS_GZIP   = eval { require Gzip::Faster; Gzip::Faster->import(); 1 };
my $HAS_DEEP   = eval { require DBM::Deep; 1 };
my $HAS_XLSX_W = eval { require Excel::Writer::XLSX; 1 };	# writer, to create fixture
my $HAS_XLSX_R = eval { require Spreadsheet::ParseXLSX; 1 };
my $HAS_LWP    = eval { require LWP::UserAgent::Cached; 1 };
my $HAS_HTML   = eval { require HTML::TableExtract; 1 };

# Inline test packages — each derived from Database::Abstraction so
# the class name drives the table/filename lookup.
{ package Database::od_redis;   our @ISA = ('Database::Abstraction') }
{ package Database::od_remote;  our @ISA = ('Database::Abstraction') }
{ package Database::od_url;     our @ISA = ('Database::Abstraction') }
{ package Database::od_deep;    our @ISA = ('Database::Abstraction') }
{ package Database::od_xlsx;    our @ISA = ('Database::Abstraction') }
{ package Database::od_gztest;  our @ISA = ('Database::Abstraction') }

plan tests => 11;

# ===========================================================================
# Section A — Redis / Redis::Fast
# ===========================================================================

subtest 'A1: Redis and Redis::Fast both absent — database query fails gracefully' => sub {
	plan tests => 2;

	Test::Without::Module->import(qw(Redis::Fast Redis));

	my $db;
	lives_ok {
		$db = Database::od_redis->new(database => 'redis://localhost/0')
	} 'new() with redis:// URL lives even when Redis modules are absent';

	throws_ok { $db->count() }
		qr/Can't locate (?:Redis|Redis\/Fast)/,
		'count() dies with clear "Can\'t locate" when neither Redis module is available';

	Test::Without::Module->unimport(qw(Redis::Fast Redis));
};

subtest 'A2: Redis::Fast absent — falls back to Redis (pure-Perl)' => sub {
	SKIP: {
		# Both conditions must hold:
		#   1. Redis (pure-Perl) is installed — it is the fallback we're proving.
		#   2. Redis::Fast was successfully loaded during the probe at the top of
		#      this file — only then can we meaningfully hide it to exercise the
		#      fallback code path.
		skip 'Redis pure-Perl module not installed', 2
			unless eval { require Redis; 1 };
		skip 'Redis::Fast was not available during probe (no fallback to exercise)', 2
			unless $HAS_RFAST;

		plan tests => 2;

		Test::Without::Module->import('Redis::Fast');

		my $db;
		lives_ok {
			$db = Database::od_redis->new(database => 'redis://localhost/0')
		} 'new() lives when only Redis::Fast is hidden';

		# A live Redis server is not available in CI.  The important assertion is
		# that any error is a *connection* failure, not a "Can't locate Redis::Fast"
		# module-load failure — proving the fallback require Redis path was reached.
		my $err = '';
		eval { $db->count() };
		$err = "$@" if $@;
		unlike($err, qr/Can't locate Redis::Fast/,
			'error (if any) is a server-connection error, not a missing-module error');

		Test::Without::Module->unimport('Redis::Fast');
	}
};

# ===========================================================================
# Section B — Gzip::Faster
# ===========================================================================

subtest 'B1: Gzip::Faster absent — .csv.gz query fails with clear error' => sub {
	SKIP: {
		skip 'Gzip::Faster not installed (needed to create the fixture)', 2
			unless $HAS_GZIP;

		plan tests => 2;

		# Build a tiny gzip-compressed CSV fixture.
		my $tmpdir  = tempdir(CLEANUP => 1);
		my $csv_src = "entry,name\nfoo,bar\n";
		my $gz_data = Gzip::Faster::gzip($csv_src);
		my $gz_file = File::Spec->catfile($tmpdir, 'od_gztest.csv.gz');
		open(my $fh, '>', $gz_file) or die "Cannot write $gz_file: $!";
		print $fh $gz_data;
		close $fh;

		# Now hide Gzip::Faster so the module cannot load it when _open() runs.
		Test::Without::Module->import('Gzip::Faster');

		my $db;
		lives_ok {
			$db = Database::od_gztest->new(directory => $tmpdir)
		} 'new() lives even when Gzip::Faster is absent';

		throws_ok { $db->count() }
			qr/Can't locate Gzip\/Faster/,
			'count() on a .csv.gz file dies when Gzip::Faster is unavailable';

		Test::Without::Module->unimport('Gzip::Faster');
	}
};

# ===========================================================================
# Section C — Text::xSV::Slurp
# ===========================================================================

subtest 'C1: Text::xSV::Slurp absent — small CSV slurp path dies clearly' => sub {
	plan tests => 2;

	Test::Without::Module->import('Text::xSV::Slurp');

	# test1.csv is well below max_slurp_size, so the module hits the slurp path.
	my $db;
	lives_ok {
		$db = Database::test1->new(directory => $DATA_DIR)
	} 'new() lives when Text::xSV::Slurp is absent';

	throws_ok { $db->count() }
		qr/Can't locate Text\/xSV\/Slurp/,
		'count() on a small CSV dies when Text::xSV::Slurp is unavailable';

	Test::Without::Module->unimport('Text::xSV::Slurp');
};

subtest 'C2: Text::xSV::Slurp absent, max_slurp_size=>0 — CSV uses SQL path successfully' => sub {
	plan tests => 2;

	Test::Without::Module->import('Text::xSV::Slurp');

	# max_slurp_size => 0 forces every file through the DBI/SQL path,
	# bypassing the Text::xSV::Slurp require entirely.
	my $db;
	lives_ok {
		$db = Database::test1->new(directory => $DATA_DIR, max_slurp_size => 0)
	} 'new() lives with max_slurp_size => 0 and Text::xSV::Slurp absent';

	my $cnt;
	lives_ok { $cnt = $db->count() }
		'count() succeeds via DBI/SQL path when Text::xSV::Slurp is absent';

	Test::Without::Module->unimport('Text::xSV::Slurp');
};

# ===========================================================================
# Section D — XML::Simple
# ===========================================================================

subtest 'D1: XML::Simple absent — small XML query fails clearly' => sub {
	plan tests => 2;

	Test::Without::Module->import('XML::Simple');

	# test3.xml is a small XML fixture; the module tries to slurp it with XML::Simple.
	my $db;
	lives_ok {
		$db = Database::test3->new(directory => $DATA_DIR)
	} 'new() lives when XML::Simple is absent';

	throws_ok { $db->count() }
		qr/Can't locate XML\/Simple/,
		'count() on an XML file dies when XML::Simple is unavailable';

	Test::Without::Module->unimport('XML::Simple');
};

# ===========================================================================
# Section E — DBM::Deep
# ===========================================================================

subtest 'E1: DBM::Deep absent — .dbm file query fails clearly' => sub {
	SKIP: {
		skip 'DBM::Deep not installed (needed to create the .dbm fixture)', 2
			unless $HAS_DEEP;

		plan tests => 2;

		# Create a .dbm fixture using the loaded DBM::Deep.
		my $tmpdir  = tempdir(CLEANUP => 1);
		my $dbm_file = File::Spec->catfile($tmpdir, 'od_deep.dbm');
		{
			my $db = DBM::Deep->new({ file => $dbm_file });
			$db->{'row1'} = { name => 'Alice', score => 10 };
			$db->{'row2'} = { name => 'Bob',   score => 20 };
		}

		# Now hide DBM::Deep so _open() cannot load it.
		Test::Without::Module->import('DBM::Deep');

		my $db;
		lives_ok {
			$db = Database::od_deep->new(directory => $tmpdir)
		} 'new() lives when DBM::Deep is absent';

		throws_ok { $db->count() }
			qr/Can't locate DBM\/Deep/,
			'count() on a .dbm file dies when DBM::Deep is unavailable';

		Test::Without::Module->unimport('DBM::Deep');
	}
};

# ===========================================================================
# Section F — Spreadsheet::ParseXLSX
# ===========================================================================

subtest 'F1: Spreadsheet::ParseXLSX absent — .xlsx query fails clearly' => sub {
	SKIP: {
		skip 'Excel::Writer::XLSX not installed (needed to create the .xlsx fixture)', 2
			unless $HAS_XLSX_W;
		skip 'Spreadsheet::ParseXLSX not installed (needed to confirm the absence test)', 2
			unless $HAS_XLSX_R;

		plan tests => 2;

		# Build a minimal .xlsx fixture.
		my $tmpdir    = tempdir(CLEANUP => 1);
		my $xlsx_file = File::Spec->catfile($tmpdir, 'od_xlsx.xlsx');
		{
			my $wb = Excel::Writer::XLSX->new($xlsx_file)
				or die "Cannot create $xlsx_file: $!";
			my $ws = $wb->add_worksheet('od_xlsx');
			$ws->write(0, 0, 'entry');
			$ws->write(0, 1, 'name');
			$ws->write(1, 0, 'r1');
			$ws->write(1, 1, 'Alice');
			$wb->close();
		}

		# Hide the reader (not the writer — writer only ran above).
		Test::Without::Module->import('Spreadsheet::ParseXLSX');

		my $db;
		lives_ok {
			$db = Database::od_xlsx->new(directory => $tmpdir)
		} 'new() lives when Spreadsheet::ParseXLSX is absent';

		throws_ok { $db->count() }
			qr/Can't locate Spreadsheet\/ParseXLSX/,
			'count() on a .xlsx file dies when Spreadsheet::ParseXLSX is unavailable';

		Test::Without::Module->unimport('Spreadsheet::ParseXLSX');
	}
};

# ===========================================================================
# Section G — LWP::UserAgent::Cached
# ===========================================================================

subtest 'G1: LWP::UserAgent::Cached absent — url backend query fails clearly' => sub {
	plan tests => 2;

	Test::Without::Module->import('LWP::UserAgent::Cached');

	my $db;
	lives_ok {
		$db = Database::od_url->new(url => 'http://example.com/data.html')
	} 'new() with url => lives even when LWP::UserAgent::Cached is absent';

	throws_ok { $db->count() }
		qr/Can't locate LWP\/UserAgent\/Cached/,
		'count() on a URL-backed object dies when LWP::UserAgent::Cached is unavailable';

	Test::Without::Module->unimport('LWP::UserAgent::Cached');
};

# ===========================================================================
# Section H — HTML::TableExtract (LWP present, HTML parser absent)
# ===========================================================================

subtest 'H1: HTML::TableExtract absent — HTML url query fails clearly' => sub {
	SKIP: {
		skip 'LWP::UserAgent::Cached not installed (required for this path)', 2
			unless $HAS_LWP;
		skip 'HTML::TableExtract not installed (needed to confirm the absence test)', 2
			unless $HAS_HTML;

		plan tests => 2;

		# Build a canned HTML response the same way t/html.t does.
		my $html_body = '<html><body><table><tr><th>entry</th></tr>'
			. '<tr><td>r1</td></tr></table></body></html>';
		my $mock_response = HTTP::Response->new(200, 'OK');
		$mock_response->content_type('text/html; charset=UTF-8');
		$mock_response->content($html_body);

		# Mock LWP so the HTTP fetch succeeds, advancing the code to the
		# HTML::TableExtract require.  Use the LWP::UserAgent::get slot
		# (LWP::UserAgent::Cached inherits get from LWP::UserAgent).
		my $guard = mock_scoped 'LWP::UserAgent::get' => sub { $mock_response };

		Test::Without::Module->import('HTML::TableExtract');

		my $db;
		lives_ok {
			$db = Database::od_url->new(url => 'http://example.com/page.html')
		} 'new() lives when HTML::TableExtract is absent but LWP is present';

		throws_ok { $db->count() }
			qr/Can't locate HTML\/TableExtract/,
			'count() on an HTML url dies when HTML::TableExtract is unavailable';

		Test::Without::Module->unimport('HTML::TableExtract');
	}
};

# ===========================================================================
# Section I — File::Slurp::Remote
# ===========================================================================

subtest 'I1: File::Slurp::Remote absent — remote host query fails clearly' => sub {
	plan tests => 2;

	Test::Without::Module->import('File::Slurp::Remote');

	# Use an unambiguously non-local hostname so _is_local_host() returns false
	# and the code actually tries to require File::Slurp::Remote.
	my $db;
	lives_ok {
		$db = Database::od_remote->new(
			host      => 'remote.example.invalid',
			directory => '/opt/data',
		)
	} 'new() with host => lives even when File::Slurp::Remote is absent';

	throws_ok { $db->count() }
		qr/Can't locate File\/Slurp\/Remote/,
		'count() on a remote-host object dies when File::Slurp::Remote is unavailable';

	Test::Without::Module->unimport('File::Slurp::Remote');
};
