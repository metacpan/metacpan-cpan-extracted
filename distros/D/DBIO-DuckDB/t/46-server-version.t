#!/usr/bin/env perl
# t/46-server-version.t — karr #17: the version string this driver hands core
# must be one core can normalise.
#
# Offline: in-memory DuckDB only, no DSN, no server, no DBIO_TEST_* anything.
#
# DuckDB spells its own version with a leading lowercase v. libduckdb's
# duckdb_library_version() answers "v1.5.3", DBD::DuckDB returns that string
# unchanged for SQL_DBMS_VER (DBD::DuckDB::GetInfo::sql_dbms_ver is a FETCH of
# duckdb_version), and core's normaliser in DBIO::Storage::DBI::_server_info
# anchors its number at the start of the string:
#
#     my ($numeric_version) = $server_version =~ /^([\d\.]+)/;
#     my @verparts = split (/\./, $numeric_version);
#
# The v sits in front of the anchor, so the match fails. TWO things went wrong
# from that, and this file asserts BOTH, because a test that only checks the
# version number lets the other one back in silently:
#
#   1. $numeric_version is undef and goes straight into split — every single
#      call printed "Use of uninitialized value $numeric_version in split".
#   2. normalized_dbms_version was never set. That is the quiet half: code
#      gating a feature on the engine version reads undef and decides wrong,
#      with nothing to show for it.
#
# WHAT THE FIX IS ALLOWED TO CHANGE. _get_server_version is a storage hook and
# its return value IS what core stores in dbms_version — there is no second,
# rawer slot in _server_info. The family uses the hook exactly that way
# (DBIO::MySQL::Storage returns "11.8.8-MariaDB-ubu2404" from SELECT VERSION(),
# DBIO::MSSQL::Storage::Sybase returns xp_msver's ProductVersion), so this
# driver hands core "1.5.3" and DuckDB's own spelling stays reachable, verbatim
# and unnormalised, through $storage->duckdb_version. Part C pins that split.
#
# WHY EXACTLY ONE LEADING v AND NOTHING ELSE: duckdb.h documents
# duckdb_library_version() as returning "the version of the linked DuckDB, with
# a version postfix for dev versions". No dev build was available here to
# measure — only v1.5.3 — so the override stays as narrow as the documented
# shape allows: strip the v, touch nothing behind it, and let core's own regex
# decide where the number ends. Part D holds that line against a dev string.
#
# Measured on libduckdb v1.5.3 through DBD::DuckDB 0.16, and re-measured on
# each run against whatever libduckdb is loaded.

use strict;
use warnings;
use Test::More;

use DBIO::DuckDB::Test;
use DBIO::DuckDB::Storage;
use DBIO::Storage::DBI;

my $schema  = DBIO::DuckDB::Test->init_schema;
my $storage = $schema->storage;

# ===========================================================================
# A. What the engine actually says — the input every claim below is built from
# ===========================================================================

my $raw = $storage->_get_dbh->get_info(18);   # SQL_DBMS_VER
ok defined $raw && length $raw, 'SQL_DBMS_VER answers a version string'
  or BAIL_OUT('no version string from DBD::DuckDB — nothing to assert on');

note "SQL_DBMS_VER          = $raw";
note 'duckdb_version        = ' . $storage->duckdb_version;

# The expected normalisation, derived from THIS engine rather than from the
# literal 1.5.3, so the file keeps measuring when libduckdb moves.
my ($digits) = $raw =~ /^v?([0-9.]+)/
  or BAIL_OUT("cannot read a version number out of '$raw'");
my @parts = split /\./, $digits;
push @parts, 0 while @parts < 3;
my $expect_normalized = sprintf '%d.%03d%03d', @parts[0..2];

# ===========================================================================
# B. The two halves of the defect, on one real call
# ===========================================================================

my @warnings;
my $info;
{
  # Make this a real computation and not a cache read: whoever ran before us
  # must not be able to turn the assertion below into a no-op.
  delete $storage->_dbh_details->{info};

  local $SIG{__WARN__} = sub { push @warnings, @_ };
  $info = $storage->_server_info;
}

is scalar(@warnings), 0, '_server_info runs without a warning';
diag "  unexpected warning: $_" for @warnings;

ok defined $info->{normalized_dbms_version},
  'normalized_dbms_version is set';

is $info->{normalized_dbms_version}, $expect_normalized,
  "... and is the engine's own version normalised ($expect_normalized)";

# ===========================================================================
# C. The raw spelling is not lost — it moved, it did not vanish
# ===========================================================================

(my $expect_dbms_version = $raw) =~ s/^v//;

is $info->{dbms_version}, $expect_dbms_version,
  'dbms_version is the engine string with the leading v removed';

like $info->{dbms_version}, qr/^[0-9]/,
  '... i.e. it starts with a digit, which is what core parses';

is $storage->duckdb_version, $raw,
  'duckdb_version still answers DuckDB\'s own spelling, untouched';

# ===========================================================================
# D. A dev build must survive its postfix
# ===========================================================================
#
# duckdb.h promises a postfix on dev versions and there is no dev libduckdb
# here to try, so the shape is fed in at the seam core reads from. This is the
# whole reason the override is an s/^v// and not a "pull the three numbers
# out": everything behind the v is core's business, and a dev postfix must
# reach it intact.

{
  no warnings 'redefine';
  local *DBIO::Storage::DBI::_get_server_version = sub { 'v1.6.0-dev1234' };

  is $storage->_get_server_version, '1.6.0-dev1234',
    'only the leading v is stripped — a dev postfix passes through';

  my @dev_warnings;
  my $dev_info;
  {
    delete $storage->_dbh_details->{info};
    local $SIG{__WARN__} = sub { push @dev_warnings, @_ };
    $dev_info = $storage->_server_info;
  }

  is scalar(@dev_warnings), 0, '... and a dev version warns just as little';
  diag "  unexpected warning: $_" for @dev_warnings;

  is $dev_info->{normalized_dbms_version}, '1.006000',
    '... and still normalises to its three numbers';
}

delete $storage->_dbh_details->{info};

done_testing;
