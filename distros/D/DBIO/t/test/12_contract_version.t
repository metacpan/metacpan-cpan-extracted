use strict;
use warnings;
use Test::More;

# F14: per-base-class contract version, independent of the dist $VERSION.
# Each base class that out-of-tree drivers subclass must expose
# ->contract_version returning the same string as its $CONTRACT_VERSION
# package var. The dist $VERSION (build-injected by VersionFromMainModule)
# is separate and may legitimately differ from the contract version.
#
# Bumped to 1.1 by F02/F10/F12: added the transactional_ddl and
# supports_if_exists capabilities to L<DBIO::Storage::DBI::Capabilities>,
# the should_emit_if_exists helper to L<DBIO::Diff::Op>, and the
# _execute_ddl txn_do wrap probe to L<DBIO::Deploy::Base>. Any of these
# are contract-shape changes for drivers that adopt them.

use DBIO::Introspect::Base;
use DBIO::Diff::Base;
use DBIO::Deploy::Base;
use DBIO::SQLMaker;
use DBIO::Storage::DBI::Capabilities;

my @classes = (
  [ 'DBIO::Introspect::Base'         => 'DBIO::Introspect::Base' ],
  [ 'DBIO::Diff::Base'               => 'DBIO::Diff::Base' ],
  [ 'DBIO::Deploy::Base'             => 'DBIO::Deploy::Base' ],
  [ 'DBIO::SQLMaker'                 => 'DBIO::SQLMaker' ],
  [ 'DBIO::Storage::DBI::Capabilities' => 'DBIO::Storage::DBI::Capabilities' ],
);

for my $pair (@classes) {
  my ($label, $class) = @$pair;

  # contract_version must exist and be invocable as a class method.
  can_ok $class, 'contract_version';

  # Read the package var directly and via the method -- they must agree.
  my $var    = do { no strict 'refs'; ${"${class}::CONTRACT_VERSION"} };
  my $method = $class->contract_version;
  is $method, $var, "$label: contract_version() returns \$CONTRACT_VERSION";

  # The contract version is a string (so future bumps like '1.1' / '2.0'
  # do not get numeric-coerced and lose their shape).
  is $method, "$method", "$label: contract_version stringifies cleanly";

  # Independent of the dist $VERSION. The dist version is injected by
  # Dist::Zilla's VersionFromMainPlugin (from $VERSION in lib/DBIO.pm) and
  # is unrelated to the per-class contract.
  my $dist_version = do { no strict 'refs'; ${"${class}::VERSION"} };
  isnt $method, $dist_version,
    "$label: contract_version is distinct from dist \$VERSION"
    unless !defined $dist_version;  # $VERSION may be undef pre-build
}

# The contract versions must all be defined and non-empty. Bumped from
# 1.0 to 1.1 by F02/F10/F12 (transactional DDL wrap + IF [NOT] EXISTS
# capability + should_emit_if_exists helper). This assertion is the
# tripwire that forces a conscious decision when shapes change.
for my $pair (@classes) {
  my ($label, $class) = @$pair;
  my $v = $class->contract_version;
  ok defined $v && length $v, "$label: contract_version is defined and non-empty";
  is $v, '1.1', "$label: contract_version is the documented 1.1 (bump deliberately)";
}

done_testing;
