package DBIO::Deploy::Base;
# ABSTRACT: Base class for DBIO driver deploy orchestrators

use strict;
use warnings;

our $CONTRACT_VERSION = '1.1';

# Loaded without importing: importing _split_statements would leak it into
# this package's method-resolution namespace (t/55namespaces_cleaned.t).
# We deliberately do NOT use DBIO::Carp either -- its `import` installs
# carp/carp_once/carp_unique into our namespace and triggers the same
# namespace leak. The F02 informational warning is fired via a local
# one-time closure below.
use DBIO::SQL::Util ();


sub contract_version { $CONTRACT_VERSION }

sub new {
  my ($class, %args) = @_;
  return bless { %args }, $class;
}


sub schema { $_[0]->{schema} }

sub _dbh { $_[0]->schema->storage->dbh }

# --- abstract hooks: the driver's helper classes -----------------------------


sub _ddl_class { die ref(shift) . '::_ddl_class not implemented' }


sub _introspect_class { die ref(shift) . '::_introspect_class not implemented' }


sub _diff_class { die ref(shift) . '::_diff_class not implemented' }

# --- overridable factories / glue --------------------------------------------


sub _new_introspect {
  my ($self, $dbh) = @_;
  return $self->_introspect_class->new(dbh => $dbh);
}


sub _introspect_current {
  my ($self) = @_;
  return $self->_new_introspect($self->_dbh)->model;
}


sub _install_ddl {
  my ($self) = @_;
  return $self->_ddl_class->install_ddl($self->schema);
}


sub _execute_ddl {
  my ($self, $dbh, $sql) = @_;
  my @stmts = grep { !/^\s*--/ } DBIO::SQL::Util::_split_statements($sql);
  return 1 unless @stmts;

  my $storage = eval { $self->schema->storage } || undef;
  my $use_txn = $storage && $storage->can('_use_transactional_ddl')
    ? $storage->_use_transactional_ddl
    : 0;

  if ($use_txn) {
    $storage->txn_do(sub {
      $dbh->do($_) for @stmts;
    });
  }
  else {
    my $class = ref($self) || $self;
    DBIO::Deploy::Base::_warn_non_txn_ddl_once("$class -- DDL loop is not atomic; recovery depends on the driver's version-row gate");
    $dbh->do($_) for @stmts;
  }
  return 1;
}

# F02: one-time informational warning for non-transactional DDL runs.
# Implemented as a local one-time closure rather than `use DBIO::Carp`
# to avoid the namespace leak (t/55namespaces_cleaned.t). Keyed on the
# full message so a different engine class gets its own one-shot.
my %_WARNED_NON_TXN_DDL;
sub _warn_non_txn_ddl_once {
  my ($msg) = @_;
  return if $_WARNED_NON_TXN_DDL{$msg}++;
  warn "non-transactional DDL on $msg\n";
}


sub _build_target_model {
  die ref(shift) . '::_build_target_model not implemented';
}

# --- public orchestration ----------------------------------------------------


sub install {
  my ($self) = @_;
  $self->_execute_ddl($self->_dbh, $self->_install_ddl);
  return 1;
}


sub diff {
  my ($self) = @_;
  my $source_model = $self->_introspect_current;
  my $target_model = $self->_build_target_model;
  return $self->_diff_class->new(
    source => $source_model,
    target => $target_model,
  );
}


sub apply {
  my ($self, $diff) = @_;
  return unless $diff->has_changes;
  $self->_execute_ddl($self->_dbh, $diff->as_sql);
  return 1;
}


sub upgrade {
  my ($self) = @_;
  my $diff = $self->diff;
  return unless $diff->has_changes;
  $self->apply($diff);
  return $diff;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Deploy::Base - Base class for DBIO driver deploy orchestrators

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Base class for the per-driver C<Deploy> orchestrators
(L<DBIO::PostgreSQL::Deploy>, L<DBIO::MySQL::Deploy>, L<DBIO::DuckDB::Deploy>,
L<DBIO::SQLite::Deploy>). Those classes implement the same
test-deploy-and-compare strategy and their C<install>/C<apply>/C<upgrade>
methods were byte-near-identical; only the way C<diff> obtains the I<target>
model (deploy the desired schema into a throwaway database and introspect it)
is genuinely engine-specific.

This base hosts the shared orchestration:

=over 4

=item * L</install> -- generate install DDL and run it against the live db.

=item * L</apply> -- run a diff's SQL against the live db.

=item * L</upgrade> -- L</diff> then L</apply>.

=item * L</diff> -- introspect the live db (source), build the target model,
and hand both to the driver's diff class.

=back

against a handful of hooks. A subclass must provide the three class-name hooks
(L</_ddl_class>, L</_introspect_class>, L</_diff_class>) and L</_build_target_model>
-- the "make a throwaway, deploy the desired schema, introspect it" step that
is the real engine seam. Drivers that use a temporary I<database> (PostgreSQL,
MySQL) get a ready-made L</_build_target_model> by subclassing
L<DBIO::Deploy::Base::TempDatabase> instead; in-memory drivers (DuckDB, SQLite)
override L</_build_target_model> directly with a C<:memory:> connection.

=head1 ATTRIBUTES

=head2 schema

A connected L<DBIO::Schema> instance using the driver's component. Required.

=head1 METHODS

=head2 new

    my $deploy = $class->new(schema => $connected_schema, %extra);

Blesses the argument hash. C<schema> is required.

=head2 _ddl_class

Class name whose C<install_ddl($schema)> returns the install DDL. Abstract.

=head2 _introspect_class

Class name whose C<< new(dbh => $dbh)->model >> returns an introspected model.
Abstract.

=head2 _diff_class

Class name whose C<< new(source => $m, target => $m) >> returns a diff object
(responding to C<has_changes> and C<as_sql>). Abstract.

=head2 _new_introspect

    my $intro = $self->_new_introspect($dbh);

Factory for an introspector over C<$dbh>. Default: C<< _introspect_class->new(dbh => $dbh) >>.
Override to pass extra construction args (e.g. PostgreSQL's C<schema_filter>).

=head2 _introspect_current

The introspected model of the live (source) database. Default:
C<< $self->_new_introspect($self->_dbh)->model >>.

=head2 _install_ddl

The install DDL string for the connected schema. Default:
C<< _ddl_class->install_ddl($self->schema) >>.

=head2 _execute_ddl

    $self->_execute_ddl($dbh, $sql);

Splits C<$sql> into statements (L<DBIO::SQL::Util/_split_statements>) and runs
each via C<< $dbh->do >>, skipping comment-only statements.

When the storage reports C<< _use_transactional_ddl >> truthy, the loop is
wrapped in C<< $storage->txn_do >> so a failure on any statement rolls the
whole batch back. When the storage reports C<0> (the default for engines
whose DDL forces an implicit C<COMMIT> -- MySQL pre-8.0, Oracle, DB2, Sybase,
Informix -- or whose rebuild path depends on C<AutoCommit=on>, e.g. SQLite),
the loop runs statement-at-a-time as before and a C<carp> is emitted naming
this engine class so operators see that a partial-failure recovery depends on
per-driver bookkeeping (e.g. the C<__VERSION> row gate in
L<DBIO::DeploymentHandler>).

=head2 _build_target_model

The desired-state model: deploy the install DDL into a throwaway database and
introspect it. Abstract here -- provided by L<DBIO::Deploy::Base::TempDatabase>
for temp-database drivers, or overridden directly by in-memory drivers.

=head2 install

    $deploy->install;

Generates the install DDL and executes it against the connected database.
Suitable for a fresh install on an empty database. Returns true.

=head2 diff

    my $diff = $deploy->diff;

Introspects the live database (source), builds the target model via
L</_build_target_model>, and returns C<< _diff_class->new(source => ..., target => ...) >>.

=head2 apply

    $deploy->apply($diff);

Executes each statement of C<< $diff->as_sql >> against the connected
database. No-op (returns false) when C<< $diff->has_changes >> is false.

=head2 upgrade

    my $diff = $deploy->upgrade;

Convenience: L</diff> then L</apply>. Returns the diff object if changes were
applied, or C<undef> if the database was already up to date.

=head1 CONTRACT VERSION

This class exposes an independent compatibility version, distinct from
C<$VERSION> (the dist version injected by L<Dist::Zilla>'s
C<VersionFromMainModule>):

    my $v = $class->contract_version;

C<$CONTRACT_VERSION> bumps when the deploy orchestrator's public interface
(C<install>, C<apply>, C<upgrade>, C<diff>) or the hook contract
(C<_ddl_class>, C<_introspect_class>, C<_diff_class>,
C<_build_target_model>) changes. The dist C<$VERSION> bumps on every
release, but two core releases at the same contract version remain
wire-compatible. Out-of-tree drivers should record the contract version
they were last tested against and compare it against core's at load time,
warning (or strict-failing under C<DBIO_STRICT_CONTRACT>) when the shapes
have drifted. See F<docs/adr/> for the contract-version policy.

=head1 TRANSACTIONAL DDL

Whether the loop in L</_execute_ddl> is wrapped in C<< $storage->txn_do >>
is governed by the C<transactional_ddl> capability on the storage
(L<DBIO::Storage::DBI::Capabilities>):

=over 4

=item * Engines where DDL is transactional: PostgreSQL, Firebird, the
newer transactional DDL mode in MariaDB 10.6+ / MySQL 8.0+. The driver
sets C<< _use_transactional_ddl(1) >> and the whole multi-statement DDL
runs as one atomic unit -- a failure on statement 7 of 12 rolls back
the preceding six.

=item * Engines that force an implicit C<COMMIT> on DDL: MySQL (pre 8.0
unless explicit transactional DDL is on), Oracle, DB2, Sybase, Informix.
On these engines wrapping C<$dbh-E<gt>do()> in C<txn_do> is a no-op as
far as DDL is concerned, and the loop runs statement-at-a-time as
before. A C<carp> is emitted at the first L</_execute_ddl> call naming
this engine class so operators see that a partial-failure recovery
depends on the driver's own bookkeeping (e.g. version-row gates).

=item * Engines whose rebuild path depends on C<AutoCommit=on>: SQLite.
We deliberately do B<not> wrap in C<txn_do> for SQLite even when the
storage reports transactional DDL: a blanket C<txn_do> wrap would
regress SQLite's in-place rebuilds. Drivers that need transactional
DDL on a non-transactional engine (e.g. PostgreSQL on the wire) opt in
via L<DBIO::Storage::DBI::Capabilities>'s C<< _use_transactional_ddl(1) >>.

=back

Recovery on the non-transactional set is engine-specific. MySQL rolls
back DDL on most error paths (CREATE TABLE / DROP TABLE / RENAME are
atomic per-statement at the storage level) but multi-statement DDL
bundles can still leave the schema half-applied. L<DBIO::DeploymentHandler>
relies on the C<__VERSION> row as a forward-progress gate: a partially
applied upgrade can be re-run safely because the diff re-computes
against live state, and the next apply picks up the remainder.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
