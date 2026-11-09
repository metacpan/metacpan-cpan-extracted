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
#
# Bumped to 1.2 by ADR 0036 (atomic upsert, flat): added the
# supports_upsert capability to L<DBIO::Storage::DBI::Capabilities> and
# the on_conflict option of sql_maker->insert to the L<DBIO::SQLMaker>
# surface (the base generator refuses it; a driver subclass consumes it).
# Both are shapes out-of-tree drivers extend.
#
# The on_conflict target for key => $constraint carries BOTH halves --
# { constraint => $name, columns => \@resolved }. That
# correction lands inside the same unreleased cycle as the 1.2 bump
# itself, so it is part of what 1.2 *is*, not drift away from it: no
# core release has ever published a 1.2 with the one-key shape. The
# precedent is the 1.1 bump above, which likewise covers three separate
# shape changes (F02/F10/F12) made in one cycle -- one bump per released
# contract generation, not one per commit.
#
# By that same rule, the conditional conflict branch is part
# of 1.2 rather than a 1.3: the supports_upsert_where capability and the
# optional 'where' key of the on_conflict structure land in the same
# unreleased cycle. A driver reading 1.2 gets the whole upsert surface
# in one generation -- and the capability's default of 0 is exactly what
# makes a driver that ignores the key safe, so nothing here depends on a
# version comparison.
#
# And once more for ADR 0037: the supports_exists_query
# capability on L<DBIO::Storage::DBI::Capabilities>, plus the two storage
# hooks it belongs to -- _exists_value_sql and _except_operator on
# L<DBIO::Storage::DBI>, the latter renamed inside this same generation
# (see below) -- are part of 1.2, NOT a 1.3. Same in-cycle rule:
# 1.2 has never been released (the last CPAN release is 0.900002; 1.2 came
# afterwards with the upsert work), and no driver in the family declares
# $TESTED_AGAINST_CONTRACT at all, so no consumer can ever have seen a 1.2
# without this addition. Bumping here would publish two generations that
# nobody could tell apart. The hooks live on DBIO::Storage::DBI, which
# carries no $CONTRACT_VERSION of its own -- ADR 0024 chose its five
# classes deliberately and treats the number as one family-wide signal, so
# they ride along with the capability (recorded, not fixed, in ADR 0037
# section 6).
#
# The per-statement DDL hook rides along in 1.2 by the same in-cycle rule: the
# _ddl_statement_is_transactional hook on
# L<DBIO::Storage::DBI::Capabilities> is the per-statement half of the
# transactional_ddl capability that 1.1 introduced (ADR 0026 addendum).
# 1.2 has still never been released, so no consumer can have seen a 1.2
# without it. Two further reasons it would be the wrong bump even later:
# the hook is purely additive, and its default -- true -- reproduces the
# previous behaviour statement for statement, so a driver that ignores it
# is not merely safe but unchanged. There is nothing here to compare
# against $TESTED_AGAINST_CONTRACT and act on.
#
# ADR 0038 does NOT bump either, and this one is a different kind of
# non-bump: it touches L<DBIO::Introspect::Base> itself, a pinned class.
# table_columns_info now folds is_pk into is_nullable. Its signature, its
# keys and its return type are unchanged -- one derived value is corrected,
# from an answer that contradicted table_pk_info about the same column to
# one that agrees with it. ADR 0024 decision 2 draws the line at the shape
# of the public surface, so there is nothing here a driver could compare
# against $TESTED_AGAINST_CONTRACT and act on: the drivers that cared
# already overrode the method to compute exactly this, and the fix removes
# their reason to, rather than asking them to change.
#
# The shared upsert-condition helpers ride along in 1.2 by the same in-cycle
# rule, and are the same case as the branch above rather than a new one:
# _upsert_attempted_sql and _upsert_condition_sql are the shared half of the
# conditional conflict branch 1.2 already carries (ADR 0036 section 1),
# lifted into core out of the two drivers that had each written it. 1.2 has
# still never been released, so no consumer can have seen a 1.2 without them.
# They are also purely additive, and in the one direction that cannot
# surprise anybody: a driver that keeps its own substitution never calls
# either, and _upsert_attempted_sql has no default to inherit wrongly -- it
# throws, naming itself. The methods live on
# L<DBIO::SQLMaker::ClassicExtensions>, which L<DBIO::SQLMaker> inherits,
# so they are part of the surface a driver subclasses and ride along with
# the pinned class exactly as ADR 0037's storage hooks do.
#
# ADR 0039 rides along in 1.2 as well, and it earns its own
# paragraph because it is NOT the additive case the four above are: it
# RENAMES a hook drivers extend. _except_operator becomes
# _set_operation_keyword($op) on L<DBIO::Storage::DBI> -- one seam for all
# six set operations, with the second job of refusing an operation the engine
# does not have. A driver that overrode the old name and is loaded against
# this core does not fail loudly; it silently stops being asked, which is the
# worst failure mode in this file's subject matter and exactly the kind of
# thing a version number exists to warn about.
#
# It is still not a 1.3, for the reason that decides every entry above: 1.2
# has never been released. The last CPAN release is 0.900002 and the whole 1.2
# generation was assembled after it, so no consumer can ever have seen a 1.2
# that contained _except_operator -- the hook was introduced by ADR 0037 in
# this same unreleased cycle and never left it. Bumping would publish two
# generations that differ only in a name nobody outside this workspace could
# have compiled against. The one repo that did override it, dbio-oracle, is
# equally unreleased (its override sits in its own {{$NEXT}}), so the rename
# is a workspace-wide edit, not a compatibility event. Were 1.2 released, this
# would be a 1.3 and the argument would run the other way.
# ADR 0041 rides along in 1.2 as well, and it is the
# in-cycle rule doing real work rather than a formality: it changes the
# *semantics* of an accessor on L<DBIO::Storage::DBI::Capabilities> that
# drivers already use. $storage->_use_X(undef) now removes the per-storage
# force instead of leaving an undef that shadowed the class-level declaration
# for the life of the storage, so a driver that declares with
# __PACKAGE__->_use_X(0|1) gets its answer back when a caller clears a force.
# 1.2 has still never been released (the last CPAN release is 0.900002), so
# no consumer can have seen a 1.2 with the old behaviour -- there is no
# generation to tell apart. Even outside the cycle it would not be a bump a
# driver could act on: nothing here changes a shape, only which of two
# already-documented declaration forms is correct, and the answer is now
# "both". The other half of ADR 0041 is documentation of an existing
# limitation (a driver-declared _use_ accessor does not exist before the
# rebless) and changes no shape at all.
#
# ADR 0052 rides along in 1.2 as well, by the same in-cycle rule, and is the
# purely-additive case: the canonical model's C<indexes> section gains an
# OPTIONAL index_type key on L<DBIO::Introspect::Base> (the engine's index
# access method / class -- BTREE/FULLTEXT/SPATIAL/HASH, PostgreSQL
# gin/gist/brin/...), and L<DBIO::Diff::Compare/changed_index_fields> gains a
# new 'mutual' comparison group that folds it into the canonical index compare.
# 1.2 has still never been released (the last CPAN release is 0.900002), so no
# consumer can have seen a 1.2 without it. Two further reasons it would be the
# wrong bump even after 1.2 ships: it is additive to the model shape (a new
# optional key, no signature or return-type change), and its default -- undef,
# "this driver has no opinion" -- reproduces the previous index diff for a
# driver that does not introspect the type, index for index. The comparison
# helper lives on DBIO::Diff::Compare, which carries no $CONTRACT_VERSION of its
# own, so it rides with the DBIO::Introspect::Base canonical-model surface
# exactly as ADR 0037's storage hooks ride with DBIO::Storage::DBI. There is
# nothing here a driver could compare against $TESTED_AGAINST_CONTRACT and act
# on: a typeless driver is not merely safe but unchanged, and a driver that
# adopts index_type does so because it now renders the type, not because a
# version number told it to.
#
# The _ddl_sql_dialect hook (karr k332) rides along in 1.2 too: one more
# method on L<DBIO::Storage::DBI::Capabilities>, beside
# _ddl_statement_is_transactional, naming the SQL dialect the DDL splitter
# reads under. 1.2 has still never been released, so no consumer can have seen
# a 1.2 without it, and it is purely additive: its default, undef, "not
# declared", leaves the splitter on both backslash readings exactly as before,
# so a driver that never defines it is unchanged, not merely safe.

# ADR 0066 (database extensions, karr k346) rides along in 1.2 as well, by the
# same in-cycle rule, and is the purely-additive case: L<DBIO::Deploy::Base>
# gains hooks with do-nothing defaults (_extension_list, _extension_driver_helpers,
# _extension_connection_schema, _extension_restricted, _apply_extension_claims,
# _apply_extension_annotations, _apply_extension_states, _extension_verdict), and
# its diff hands the diff class an optional `extensions` argument ONLY when the
# list is non-empty. The default list is empty, so a driver that never defines
# any of it is unchanged, not merely safe: diff builds the same two models and
# the same diff object it built before, and apply executes the same statements.
# 1.2 has still never been released, so no consumer can have seen a 1.2 without
# them. DBIO::Introspect::Base and DBIO::Diff::Base change nothing (the diff
# class receives the extra argument through its own `new`, which stores every
# argument). The extension interface has its own version, in DBIO::Extension
# (ADR 0066 section 5.3), and is not one of ADR 0024's five classes.

# DBIO::Diff::Base->classify (ADR 0060, karr k352) rides along in 1.2 as well,
# by the same in-cycle rule, and is the purely-additive case: one new method on
# the pinned class, reading the action and replaced accessors of the operations
# the diff already holds. 1.2 has still never been released, so no consumer can
# have seen a 1.2 without it. A driver that never calls it is unchanged, and
# there is nothing here a driver could compare against $TESTED_AGAINST_CONTRACT
# and act on (ADR 0024 decision 2): no existing signature or return type moves.

# DBIO::Diff::Base->diff_options (karr k359) rides along in 1.2 as well, by the
# same in-cycle rule, and is the purely-additive case: one new class method on
# the pinned class (default: the empty list) naming the options a diff class
# takes, which DBIO::Deploy::Base::diff checks a caller's options against. 1.2
# has still never been released, so no consumer can have seen a 1.2 without it.
# A diff class that does not declare it is unchanged: diff() without options
# behaves exactly as before.

# Bumped to 1.3 for DBIO::SQLMaker by ADR 0068: the operator_words class
# method, the list of word operators a driver extends, and the check of the
# operator name of a condition.

# Bumped to 1.3 for DBIO::Diff::Base and DBIO::Deploy::Base by ADR 0080 (karr
# k399): Diff::Base gains destructive_operations and the optional operation
# method lossy; Deploy::Base apply and upgrade take allow_destructive and
# dry_run, the allow_destructive attribute is new, and a diff with a
# destructive operation no longer runs without the release.

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
# capability + should_emit_if_exists helper), and from 1.1 to 1.2 by
# ADR 0036 (supports_upsert and supports_upsert_where capabilities + the
# on_conflict insert option). ADR 0037 (supports_exists_query +
# _exists_value_sql / _except_operator) lands inside 1.2 and does NOT bump,
# and neither does ADR 0039 renaming that second hook to
# _set_operation_keyword -- a rename inside an unreleased generation, see the
# header block. ADR 0052 (optional index_type key on the canonical indexes
# section + the 'mutual' compare group) rides along in 1.2 too, additive and
# undef-defaulted; see the header block.
# DBIO::Storage::DBI::Capabilities alone is at 1.3 (karr k373): the storage
# seam _adjust_bind_values is new driver-visible surface, so ADR 0024 bumps
# that base class; DBIO::Diff::Base and DBIO::Deploy::Base are at 1.3 as well
# (karr k399); DBIO::Introspect::Base stays at 1.2.
# This assertion is the tripwire that forces a conscious decision when
# shapes change.
for my $pair (@classes) {
  my ($label, $class) = @$pair;
  my $v = $class->contract_version;
  ok defined $v && length $v, "$label: contract_version is defined and non-empty";
  my $documented = ($class eq 'DBIO::Introspect::Base') ? '1.2' : '1.3';
  is $v, $documented, "$label: contract_version is the documented $documented (bump deliberately)";
}

done_testing;
