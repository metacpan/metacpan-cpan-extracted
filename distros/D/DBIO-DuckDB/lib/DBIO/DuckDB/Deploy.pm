package DBIO::DuckDB::Deploy;
# ABSTRACT: Deploy and upgrade DuckDB schemas via test-deploy-and-compare

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Deploy::Base';

use DBI;
use DBIO::DuckDB::DDL;
use DBIO::DuckDB::Introspect;
use DBIO::DuckDB::Diff;
use DBIO::DuckDB::Extension;
use DBIO::DuckDB::DDL::Emit ();
use DBIO::Exception;


sub catalog { $_[0]->{catalog} }

sub _ddl_class        { 'DBIO::DuckDB::DDL' }
sub _introspect_class { 'DBIO::DuckDB::Introspect' }
sub _diff_class       { 'DBIO::DuckDB::Diff' }




sub _check_before_apply {
  my ($self, $diff) = @_;
  $self->_refuse_rebuilds($diff);
  $self->_refuse_duplicates_for_unique($diff);
  $self->_refuse_unfillable($diff);
  return $self->SUPER::_check_before_apply($diff);
}


sub _execute_diff {
  my ($self, $diff) = @_;
  my @ops  = @{ $diff->operations };
  my @late = grep { length } map { $_->can('late_sql') ? $_->late_sql : '' } @ops;
  return $self->SUPER::_execute_diff($diff) unless @late;

  $self->{_extension_protocol}->assert_no_refusals if $self->{_extension_protocol};
  my $early = join "\n",
    map { $_->can('early_sql') ? $_->early_sql : $_->as_sql } @ops;
  $self->_execute_ddl($self->_dbh, $early);
  $self->_execute_ddl($self->_dbh, join "\n", @late);
  return 1;
}


sub diff {
  my $self = shift;
  my $diff = $self->SUPER::diff(@_);
  $self->_refuse_rebuilds($diff);
  return $diff;
}

# DuckDB drops no table another one has a foreign key to ("Could not drop the
# table because this table is main key table of the table ...", measured
# libduckdb 1.5.3, also inside a transaction), and a table that points to
# itself keeps the temporary name in its key after the rename (the insert then
# fails with "Table with name ..__dbio_rebuild does not exist"). A rebuild in
# either case is refused before the first statement, naming the tables
# (karr k50, docs/adr/0010).
sub _refuse_rebuilds {
  my ($self, $diff) = @_;
  my $src = $diff->source || {};
  my $tgt = $diff->target || {};
  my %gone = map { $_ => 1 } grep { !exists $tgt->{tables}{$_} } keys %{ $src->{tables} || {} };
  my @refused;

  for my $op (@{ $diff->operations }) {
    next unless $op->isa('DBIO::DuckDB::Diff::Rebuild');
    my $table = $op->table_name;
    my $why   = join '; ', @{ $op->reasons };

    for my $fk (@{ $op->foreign_keys }) {
      push @refused, sprintf "table '%s' points to itself with (%s), which a rebuild would leave pointing to the temporary table (%s)",
        $table, join(', ', @{ $fk->{from_columns} }), $why
        if $fk->{to_table} eq $table;
    }
    for my $from (sort keys %{ $src->{foreign_keys} || {} }) {
      next if $from eq $table || $gone{$from};
      for my $fk (@{ $src->{foreign_keys}{$from} }) {
        push @refused, sprintf "table '%s' has to be rebuilt (%s) but table '%s' has a foreign key (%s) to it, and DuckDB does not drop a table another one points to",
          $table, $why, $from, join(', ', @{ $fk->{from_columns} })
          if $fk->{to_table} eq $table;
      }
    }
  }
  return unless @refused;

  DBIO::Exception->throw(
    "The diff is refused: " . join('; ', @refused) . ". Nothing was changed.");
}

# A unique index over values that are not unique fails half way through the
# diff ("Data contains duplicates on indexed column(s)"); look first. NULLs are
# no duplicates.
sub _refuse_duplicates_for_unique {
  my ($self, $diff) = @_;
  my $dbh = $self->_dbh;
  my $src = $diff->source || {};
  my @refused;

  # the unique indexes the diff creates, and the UNIQUE constraints a rebuilt
  # table gets that it has not had (its copy would fail on a duplicate)
  my @checks;
  for my $op (@{ $diff->operations }) {
    if ($op->isa('DBIO::DuckDB::Diff::Index') && $op->action eq 'create') {
      my $info = $op->index_info || {};
      push @checks, [ $op->table_name, $info->{columns} ] if $info->{is_unique} && !$info->{partial};
    }
    elsif ($op->isa('DBIO::DuckDB::Diff::Rebuild')) {
      my $table = $op->table_name;
      my %had = map { join("\0", @{ $_->{columns} }) => 1 }
        values %{ ($src->{unique_constraints} || {})->{$table} || {} };
      push @checks, map { [ $table, $_->{columns} ] }
        grep { !$had{ join "\0", @{ $_->{columns} } } }
        map { $op->unique_constraints->{$_} } sort keys %{ $op->unique_constraints };
    }
  }
  my %seen_check;
  for my $check (@checks) {
    my ($table, $columns) = @$check;
    next if $seen_check{ join "\0", $table, @{ $columns || [] } }++;
    next unless exists $src->{tables}{$table};
    my @cols = @{ $columns || [] };
    next unless @cols && !grep { /^\(/ } @cols;
    my %have = map { $_->{column_name} => 1 } @{ $src->{columns}{$table} || [] };
    next if grep { !$have{$_} } @cols;   # a column the diff still adds

    my $list = join ', ', map { DBIO::DuckDB::DDL::Emit::quote_ident($_) } @cols;
    my $found = $dbh->selectrow_array(sprintf
      'SELECT 1 FROM %s WHERE %s GROUP BY %s HAVING count(*) > 1 LIMIT 1',
      DBIO::DuckDB::DDL::Emit::quote_table($table),
      join(' AND ', map { DBIO::DuckDB::DDL::Emit::quote_ident($_) . ' IS NOT NULL' } @cols),
      $list);
    push @refused, sprintf "UNIQUE (%s) of table '%s'", join(', ', @cols), $table if $found;
  }
  return unless @refused;

  DBIO::Exception->throw(
    "The diff is refused: " . join('; ', @refused)
    . " cannot be created, the table holds duplicate values in it. Nothing was changed.");
}

sub _refuse_unfillable {
  my ($self, $diff) = @_;
  my $dbh = $self->_dbh;

  my $any = sub {
    my ($table, $where) = @_;
    return scalar $dbh->selectrow_array(sprintf 'SELECT 1 FROM %s%s LIMIT 1',
      DBIO::DuckDB::DDL::Emit::quote_table($table), $where // '');
  };

  # a rebuilt table copies its rows into the target's definition: the column
  # operations it replaces still say what the rows would lack
  my @ops = map { $_->isa('DBIO::DuckDB::Diff::Rebuild') ? @{ $_->column_ops } : $_ }
    @{ $diff->operations };
  for my $op (@ops) {
    next unless $op->isa('DBIO::DuckDB::Diff::Column');
    my ($table, $column) = ($op->table_name, $op->column_name);

    if ($op->action eq 'add') {
      my $info = $op->new_info;
      next unless $info->{not_null} && !defined $info->{default_value};
      next unless $any->($table);
      DBIO::Exception->throw(sprintf
        'DuckDB refuses to add the column %s.%s: it is NOT NULL without a '
        . 'default, and table %s holds rows that would have no value for it',
        $table, $column, $table);
    }
    elsif ($op->action eq 'alter') {
      next unless $op->new_info->{not_null} && !$op->old_info->{not_null};
      next unless $any->($table, ' WHERE '
        . DBIO::DuckDB::DDL::Emit::quote_ident($column) . ' IS NULL');
      DBIO::Exception->throw(sprintf
        'DuckDB refuses to make the column %s.%s NOT NULL: table %s holds '
        . 'rows where it is NULL',
        $table, $column, $table);
    }
  }

  return;
}


sub _new_introspect {
  my ($self, $dbh) = @_;
  my %opts = (dbh => $dbh);
  $opts{catalog} = $self->catalog if defined $self->catalog;
  my @schemas = DBIO::DuckDB::DDL->source_schemas($self->schema);
  $opts{schemas} = \@schemas if @schemas;
  return $self->_introspect_class->new(%opts);
}

sub install {
  my ($self) = @_;
  $self->_resolve_extension_list;
  return $self->SUPER::install;
}


sub _resolve_extension_list {
  my ($self) = @_;
  return DBIO::DuckDB::Extension->resolve_list($self->schema);
}


sub _extension_list {
  my ($self) = @_;
  my $list = $self->_resolve_extension_list or return [];

  my $rows = $self->_dbh->selectall_arrayref(
    'SELECT extension_name, installed, extension_version FROM duckdb_extensions()',
    { Slice => {} },
  );
  my %known = map { $_->{extension_name} => $_ } @$rows;

  my %state;
  for my $name ($list->names) {
    my $row = $known{$name};
    $state{$name} = $row && $row->{installed}
      ? { installed => 1, version => $row->{extension_version} }
      : { installed => 0 };
  }
  $list->set_installed(\%state);

  return [ $list->entries ];
}


sub _build_target_model {
  my ($self) = @_;

  my $temp_dbh = DBI->connect('dbi:DuckDB:dbname=:memory:', '', '', {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
  });

  # the declared extensions are active here as on a connection of the
  # schema, or a type an extension adds fails in the target model
  my $storage = $self->schema->storage;
  $temp_dbh->do($_) for $storage->_extension_activation_sql($storage->_extension_activation(undef));

  $self->_execute_ddl($temp_dbh, $self->_install_ddl);

  my $target_model = $self->_new_introspect($temp_dbh)->model;
  $temp_dbh->disconnect;

  return $target_model;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::Deploy - Deploy and upgrade DuckDB schemas via test-deploy-and-compare

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::DuckDB::Deploy> orchestrates schema deployment and upgrades for
DuckDB using the test-deploy-and-compare strategy, parallel to
L<DBIO::SQLite::Deploy> and L<DBIO::PostgreSQL::Deploy>.

For upgrades it:

=over 4

=item 1. Introspects the live database via C<information_schema> / C<duckdb_*>

=item 2. Connects to a fresh in-memory DuckDB database

=item 3. Deploys the desired schema (from DBIO classes) into that in-memory DB

=item 4. Introspects the in-memory database the same way

=item 5. Computes the diff between the two models using L<DBIO::DuckDB::Diff>

=back

DuckDB supports C<:memory:> so the throwaway DB is as cheap as with
SQLite -- no CREATE DATABASE dance like PostgreSQL.

    my $deploy = DBIO::DuckDB::Deploy->new(
        schema => MyApp::DB->connect("dbi:DuckDB:dbname=app.duckdb"),
    );
    $deploy->install;                       # fresh
    my $diff = $deploy->diff;               # or step-by-step
    $deploy->apply($diff) if $diff->has_changes;
    $deploy->upgrade;                       # convenience

=head2 Transactional DDL -- the engine has it, the rollback override ends the orphan

L<DBIO::DuckDB::Storage> declares C<< _use_transactional_ddl(1) >>, so
L<DBIO::Deploy::Base/_execute_ddl> brackets the deploy loop in a transaction
and a failed apply rolls back whole. Among the drivers answering C<1>,
DuckDB is the only one where the engine is not the whole story: the DBI
driver's C<rollback> reopens a transaction, and this storage's
C<_exec_txn_rollback> override (ADR 0005) ends the orphan itself.

The engine is not the reason the declaration needed an override. Measured on
libduckdb v1.5.3 through L<DBD::DuckDB> 0.16, C<CREATE TABLE>, C<DROP TABLE>,
C<ALTER TABLE> in its add / drop / alter-column forms, C<CREATE INDEX>,
C<DROP INDEX>, C<CREATE SEQUENCE> and C<CREATE VIEW> are all taken back by a
C<ROLLBACK>,
and C<INSTALL>, C<LOAD>, C<ATTACH> and C<DETACH> are accepted inside a
transaction block rather than refused the way PostgreSQL refuses
C<ALTER TYPE ... ADD VALUE>. DuckDB says so itself for the C<ALTER TABLE>
half -- "All the changes made by C<ALTER TABLE> fully respect the
transactional semantics, i.e., they will not be visible to other transactions
until committed, and can be fully reverted through a rollback"
(L<https://duckdb.org/docs/stable/sql/statements/alter_table>) -- and
documents no statement this driver emits as one that may not run inside a
transaction. Nothing here needs core's C<_ddl_statement_is_transactional>
escape.

There is one engine-side caveat, and it is forward-looking rather than a
breakage today. DuckDB refuses to alter a column an index depends on, and the
same page documents the remedy: "if you have an index on a column you will
first need to drop the index, alter the table, and then recreate the index".
That remedy only works B<unbracketed>. C<DROP INDEX> followed by
C<< ALTER TABLE ... ALTER COLUMN ... TYPE >> inside one transaction still dies
with C<Cannot change the type of this column: an index depends on it!>,
because the type-change check does not see the uncommitted C<DROP INDEX>; the
identical pair outside a transaction succeeds. It is specific to the type
change -- C<DROP COLUMN> and C<SET NOT NULL> after a C<DROP INDEX> both commit
normally. L<DBIO::DuckDB::Diff> cannot emit that pair today, because indexes
are diffed after columns, so a type change on an indexed column already fails
either way. A wrap would, however, foreclose the documented fix for it.

The deploy path is not the reason either. L<DBIO::DuckDB::Diff> emits plain
statements in tables-then-columns-then-indexes order; a table rebuild
(L<DBIO::DuckDB::Diff::Rebuild>) is create, copy, drop and rename -- plain
statements too, which the one transaction of the apply takes back whole if the
copy fails. There is no pragma bracket a wrap could swallow and no statement
issued outside the loop. With the capability declared true the real path works
end to end -- C<install>, C<diff>, C<apply>, then an empty second C<diff> --
and a batch whose last statement fails leaves nothing behind instead of the
earlier statements applied.

The reason for the override is C<rollback> in L<DBD::DuckDB>, which issues
C<ROLLBACK> and then immediately C<BEGIN TRANSACTION> again. That is correct
for C<AutoCommit=0>, and DBI restores C<AutoCommit=1> straight afterwards --
but the C<AutoCommit> C<STORE> handler that would commit the reopened
transaction sits behind an unreachable C<elsif>, so the C<0> to C<1>
transition does nothing at all. Every C<txn_do> that rolls back therefore
returns with DuckDB still inside a transaction that DBI believes is closed,
and the next C<txn_begin> dies with C<cannot start a transaction within a
transaction> -- or, when the rollback followed a failed statement,
C<Current transaction is aborted (please ROLLBACK)>. This is not caused by
the capability and is reached today by any C<txn_do> that rolls back; what
the capability decides is whether an C<apply> is dragged into it.

So the C<1> buys the recovery. A failed C<apply> rolls back whole -- the
earlier statements are gone, not left half-applied -- and the connection
survives, because this storage's C<_exec_txn_rollback> override (ADR 0005)
closes the stray transaction the driver reopened. Re-running C<upgrade> is
safe: the diff is recomputed against live state and the second run picks up
only what is left. Without the override, bracketed, that re-run is what
breaks: on a file DSN it dies on the poisoned connection and only an
explicit disconnect clears it, and on the C<:memory:> DSN it does not even
raise, because L<DBIO::Storage::DBI>'s C<_exec_txn_begin> retries C<begin_work>
on reconnect and a reconnect to C<:memory:> is a new, empty database with the
deployed schema gone.

The override is the whole of the fix: it ends the stray transaction itself
(ADR 0005), so the C<1> stands on its own feet and needs nothing from
L<DBD::DuckDB>. It is worth revisiting whenever L<DBD::DuckDB> is upgraded --
the upstream C<STORE> branch fix (giterlizzi/perl-DBD-DuckDB#54) makes the
override a no-op.

Only the live connection is affected either way. L</_build_target_model> does
call C<_execute_ddl>, but with a handle it opened itself, and core never
brackets a handle the storage does not own.

=head1 ATTRIBUTES

=head2 schema

A connected L<DBIO::Schema> instance using the L<DBIO::DuckDB> component.
Required.

=head2 catalog

Optional catalog name (e.g. a locally-attached file database). When set,
the source introspection is scoped to this catalog. Useful for multi-catalog
deployments and DuckLake.

B<Not applicable for Quack RPC remotes.> The remote catalog is opaque to
C<information_schema> -- deploy the schema on the B<server> process instead,
not against the client-side quack attach. Use C<PRAGMA table_info('remote.t')>
on the client to verify remote columns.

=head1 METHODS

=head2 install

    $deploy->install;

Generates DDL via L<DBIO::DuckDB::DDL/install_ddl> and executes each
statement against the connected database. Suitable for fresh installs.
The declared extensions are resolved first (L</_resolve_extension_list>), so
a class that is missing or of another driver refuses before anything is
written. The rest is inherited from L<DBIO::Deploy::Base>.

=head2 diff

    my $diff = $deploy->diff;

Computes the difference between the live database and the desired state.
Spins up a throwaway in-memory DuckDB, deploys the desired schema there,
introspects both, and returns a L<DBIO::DuckDB::Diff> object. The
orchestration is inherited from L<DBIO::Deploy::Base>; only the
in-memory target build (L</_build_target_model>) and the catalog-aware
source introspection (L</_new_introspect>) are DuckDB-specific.

=head2 apply

    $deploy->apply($diff);

Applies a L<DBIO::DuckDB::Diff> object. No-op if the diff has no changes.
Inherited from L<DBIO::Deploy::Base/apply>, with its guard for destructive and
lossy operations (C<allow_destructive>) and its C<dry_run>; the driver takes
part through L</_check_before_apply> and L</_execute_diff>.

=head2 upgrade

    my $diff = $deploy->upgrade;

Convenience: calls L</diff> then L</apply>. Returns the diff object if
changes were applied, or C<undef> if the database was already up to date.
Inherited from L<DBIO::Deploy::Base>.

=head2 _check_before_apply

The driver's half of L</apply> (ADR 0080): once the diff is released,
and before the first statement runs, it looks at the rows of the live tables
and refuses with a L<DBIO::Exception> naming table and column what DuckDB would
refuse for them half way through the diff, after earlier statements are
applied:

=over 4

=item * a table that has to be rebuilt (L<DBIO::DuckDB::Diff::Rebuild>) while
another table has a foreign key to it -- DuckDB does not drop such a table --
or while it points to itself -- the key would keep the temporary name through
the rename: the message names both tables and why the table is rebuilt;

=item * a C<UNIQUE> constraint a rebuilt table gets over duplicate values;

=item * a C<NOT NULL> column without a default that the diff adds to a table
that holds rows -- there is no value for the rows already there;

=item * a column that becomes C<NOT NULL> in a table that has a C<NULL> in it.

=back

An empty table, and a table with no C<NULL> in the column, pass.

=head2 _execute_diff

DuckDB cannot run the C<SET NOT NULL> of a column whose rows an C<UPDATE> just
filled in the same transaction. A diff that has such a step
(L<DBIO::DuckDB::Diff::Column/late_sql>) runs in two transactions: everything
else, then those steps. A failure in the second leaves the column added,
filled and nullable, and the next C<upgrade> finds exactly that to finish. A
diff without such a step is run as L<DBIO::Deploy::Base/_execute_diff> runs it.

=head2 diff

    my $diff = $deploy->diff;

As L<DBIO::Deploy::Base/diff>, and refuses a rebuild that cannot run (see
L</_check_before_apply>), so a caller who only looks at the diff hears of it too.

=head2 _new_introspect

Factory for the source-side introspector. Overrides
L<DBIO::Deploy::Base/_new_introspect> to forward the C<catalog> attribute
(for locally-attached file / DuckLake catalogs) when it is set.

=head2 _resolve_extension_list

    my $list = $self->_resolve_extension_list;   # DBIO::Extension::List, or undef

The declared list of extensions resolved to classes, without the installed
state: classes loaded, interface version and driver checked
(L<DBIO::DuckDB::Extension/resolve_list>). C<undef> when the schema declares
none.

=head2 _extension_list

    my $entries = $self->_extension_list;

The hook of L<DBIO::Deploy::Base/_extension_list>: the entries of
L</_resolve_extension_list> with the installed state attached, read from
C<duckdb_extensions()> over the live connection (C<installed>, C<version>;
C<installed> is 0 for a declared extension DuckDB does not know). C<[]> when
the schema declares none, and then nothing is read.

=head2 _build_target_model

Builds the desired-state model: connects a throwaway in-memory DuckDB,
activates the declared extensions there (L<DBIO::DuckDB/duckdb_extensions>:
C<INSTALL> and C<LOAD>, as on a connection of the schema), deploys the install
DDL there, and introspects it. DuckDB supports
C<:memory:>, so this is as cheap as with SQLite -- no temporary-database
dance like PostgreSQL. The temp DB is never scoped to C<catalog>.

=head1 SEE ALSO

=over 4

=item * L<DBIO::DuckDB> - schema component

=item * L<DBIO::DuckDB::DDL> - generates DDL

=item * L<DBIO::DuckDB::Introspect> - reads live database state

=item * L<DBIO::DuckDB::Diff> - compares two introspected models

=item * L<DBIO::SQLite::Deploy> - sibling implementation

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
