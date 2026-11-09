package DBIO::ClickHouse::Deploy;
# ABSTRACT: Deploy and upgrade ClickHouse schemas via test-deploy-and-compare

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Deploy::Base::TempDatabase';

use DBIO::ClickHouse::DDL        ();
use DBIO::ClickHouse::Introspect ();
use DBIO::ClickHouse::Diff       ();
use DBIO::ClickHouse::DDL::Emit qw(create_database drop_database);


sub _ddl_class        { 'DBIO::ClickHouse::DDL' }
sub _introspect_class { 'DBIO::ClickHouse::Introspect' }
sub _diff_class       { 'DBIO::ClickHouse::Diff' }


sub temp_db_prefix { $_[0]->{temp_db_prefix} // 'dbio_deploy_tmp_' }


sub _create_temp_db {
  my ($self, $dbh) = @_;
  my $name = $self->temp_db_prefix . $$ . '_' . time();
  $dbh->do(create_database(name => $name));
  return $name;
}


sub _drop_temp_db {
  my ($self, $dbh, $name) = @_;
  $dbh->do(drop_database(name => $name, if_exists => 1));
}


# The databases of the qualified tables, asked of the server before the first
# statement; the driver creates none.
sub _refuse_missing_databases {
  my ($self, $dbh) = @_;
  for my $pair ($self->_ddl_class->qualified_tables($self->schema)) {
    my ($table, $database) = @$pair;
    my ($found) = $dbh->selectrow_array(
      'SELECT count() FROM system.databases WHERE name = ?', undef, $database);
    next if $found;
    $self->schema->storage->throw_exception(sprintf
      'DBIO::ClickHouse refuses to create the table or view %s: the database %s does not '
      . 'exist, and the driver does not create databases', $table, $database);
  }
  return;
}

# What the install writes into the live database is the whole schema; the
# scratch database of a diff gets the tables of the current database only.
# The refusal of a missing database is raised here, where the install asks for
# its statements: the base install executes nothing before it has them.
sub _install_ddl {
  my ($self) = @_;
  $self->_refuse_missing_databases($self->_dbh) unless $self->{_local_only};
  return $self->_ddl_class->install_ddl($self->schema,
    $self->{_local_only} ? { local_only => 1 } : ());
}

sub _deploy_and_introspect_temp {
  my $self = shift;
  local $self->{_local_only} = 1;
  return $self->SUPER::_deploy_and_introspect_temp(@_);
}


sub diff {
  my ($self) = @_;
  my $source_model = $self->_introspect_current;
  my $target_model = $self->_build_target_model;
  return $self->_diff_class->new(
    source  => $source_model,
    target  => $target_model,
    storage => $self->schema->storage,
    declared_settings => $self->_ddl_class->declared_settings($self->schema),
    declared_views    => $self->_ddl_class->declared_views($self->schema, { local_only => 1 }),
  );
}


sub _check_before_apply {
  my ($self, $diff) = @_;
  $self->_refuse_nulls_in_narrowed_columns($diff);
  $self->_refuse_not_null_added_over_rows($diff);
  return $self->SUPER::_check_before_apply($diff);
}


# The dry-run paths never get here; this runs on the live handle, before the
# first statement of the plan, and throws before anything has been executed.
sub _refuse_nulls_in_narrowed_columns {
  my ($self, $diff) = @_;
  my $dbh = $self->_dbh;
  my @found;
  for my $op (@{ $diff->operations }) {
    next unless $op->can('needs_null_check') && $op->needs_null_check;
    my ($nulls) = $dbh->selectrow_array($op->null_check_sql);
    push @found, [ $op->table_name, $op->column_name, $nulls ] if $nulls;
  }
  return unless @found;

  my $msg = join "\n", map {
    my ($t, $c, $n) = @$_;
    "column $t.$c is Nullable and holds $n NULL row(s), but the schema makes it NOT NULL; "
  . "MODIFY COLUMN would leave it unreadable and block the table's mutations. "
  . "Fill them by hand: ALTER TABLE `$t` UPDATE `$c` = <value> WHERE `$c` IS NULL "
  . "SETTINGS mutations_sync = 1"
  } @found;
  $self->schema->storage->throw_exception(
    "upgrade refused, no statement was executed:\n$msg\nthen run the upgrade again"
  );
}


sub _refuse_not_null_added_over_rows {
  my ($self, $diff) = @_;
  my $dbh = $self->_dbh;
  my @found;
  for my $op (@{ $diff->operations }) {
    next unless $op->can('needs_row_check') && $op->needs_row_check;
    my ($has) = $dbh->selectrow_array($op->row_check_sql);
    push @found, [ $op->table_name, $op->column_name ] if $has;
  }
  return unless @found;

  my $msg = join "\n", map {
    my ($t, $c) = @$_;
    "column $t.$c would be added NOT NULL without a default to a table that holds rows; "
  . "ClickHouse fills existing rows with the type's zero value, which nobody wrote "
  . "(https://clickhouse.com/docs/sql-reference/statements/alter/column#add-column). "
  . "Give the column a default_value (or make it nullable) and run the upgrade again"
  } @found;
  $self->schema->storage->throw_exception(
    "upgrade refused, no statement was executed:\n$msg"
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::Deploy - Deploy and upgrade ClickHouse schemas via test-deploy-and-compare

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::ClickHouse::Deploy> orchestrates schema deployment and upgrades for
ClickHouse with the family's test-deploy-and-compare strategy:

=over 4

=item 1. introspect the live database via the C<system.*> catalog

=item 2. deploy the desired schema into a throwaway B<scratch database>

=item 3. introspect that the same way

=item 4. diff the two models with L<DBIO::ClickHouse::Diff>

=back

    my $deploy = DBIO::ClickHouse::Deploy->new(
        schema => MyApp::DB->connect($dsn, $user, $pass),
    );
    $deploy->install;                        # fresh install
    my $diff = $deploy->diff;                # or step by step
    $deploy->apply($diff) if $diff->has_changes;
    $deploy->upgrade;                        # convenience: diff + apply
    $deploy->upgrade(allow_destructive => 1); # a diff that drops or converts values

Read L<DBIO::ClickHouse::Diff/WHAT THIS DIFF WILL NOT DO> before wiring
C<upgrade> into anything automatic. A diff with a destructive operation runs
only with C<allow_destructive> (L</_check_before_apply>). A change to a table's engine or MergeTree
keys throws instead of rebuilding the table.

=head1 METHODS

=head2 temp_db_prefix

Prefix for the scratch database name; defaults to C<dbio_deploy_tmp_>. The
full name appends the PID and the current epoch second. Override per instance:

    DBIO::ClickHouse::Deploy->new(schema => $schema, temp_db_prefix => 'scratch_');

=head2 _create_temp_db

    my $name = $self->_create_temp_db($dbh);

Creates the scratch database and returns its name. The statement comes from
L<DBIO::ClickHouse::DDL::Emit/create_database>, which specifies no C<ENGINE>,
so it gets the server default (C<Atomic> on any supported version).

=head2 _drop_temp_db

    $self->_drop_temp_db($dbh, $name);

Drops the scratch database. C<IF EXISTS> because this runs unconditionally,
including on paths where the C<CREATE> is the statement that failed.

=head2 install

    $deploy->install;

Generates the install DDL via L<DBIO::ClickHouse::DDL/install_ddl> and executes
each statement against the connected database. For a fresh install on an empty
database. Otherwise L<DBIO::Deploy::Base/install>.

A source whose table or view is named C<database.table> / C<database.view> is
made in that database (L<DBIO::ClickHouse::DDL/qualified_tables>). The driver creates no
database: one the server does not have ends the install B<before its first
statement>, with a L<DBIO::Exception> naming the table and the database. The
diff reads the current database alone, so the scratch database of a diff gets
the tables and views of the current database only; a table or view of another
database is installed, never compared, replaced or dropped.

=head2 diff

    my $diff = $deploy->diff;

Introspects the live database, builds the desired model in a scratch database
(see L</THE SCRATCH DATABASE>), and returns a L<DBIO::ClickHouse::Diff>.
Throws if the schema asks for a change ClickHouse cannot make in place.

Overrides L<DBIO::Deploy::Base/diff> for one reason: the base builds the diff
from the two models alone, and the diff reads the IF [NOT] EXISTS capability
off the storage it is handed. Here that is C<< $self->schema->storage >>, so
the statements C<apply> and C<upgrade> run carry the guards, and applying the
same diff a second time after a partial failure is a no-op. It also hands the
diff the C<SETTINGS> the result classes declare
(L<DBIO::ClickHouse::DDL/declared_settings>), so a table the upgrade creates
carries them, and the views the schema declares in the current
database (L<DBIO::ClickHouse::DDL/declared_views>, C<local_only>), so a view the upgrade lacks is
created. Everything else
is the base's recipe (C<_introspect_current>, C<_build_target_model>).

=head2 _check_before_apply

    $self->_check_before_apply($diff);

The driver's checks of L<DBIO::Deploy::Base/apply>, run for a released diff
B<before its first statement>, against the live connection:
L</_refuse_nulls_in_narrowed_columns> and L</_refuse_not_null_added_over_rows>,
then the base's. They read the data; C<diff>, C<as_sql> and C<summary> stay
data-free, and a C<dry_run> checks nothing and asks the server nothing.

C<apply> and C<upgrade> are L<DBIO::Deploy::Base>'s as they are, with their
arguments: a diff holding a destructive operation -- a drop, or a
C<MODIFY COLUMN> that can alter stored values
(L<DBIO::ClickHouse::Diff::Column/lossy>) -- runs only with
C<< allow_destructive => 1 >>, given as argument or as attribute, and
C<< dry_run => 1 >> returns the diff without executing it.

    $deploy->apply($diff, allow_destructive => 1);
    $deploy->upgrade(dry_run => 1);

The C<ALTER TABLE ... MODIFY COLUMN> and C<ADD INDEX> statements it runs are
accepted synchronously but applied as background B<mutations>; watch
C<system.mutations> to see them finish.

=head2 _refuse_nulls_in_narrowed_columns

Every C<MODIFY COLUMN> that turns a C<Nullable(...)> column into a
non-nullable one (L<DBIO::ClickHouse::Diff::Column/needs_null_check>) is asked
C<SELECT count() FROM t WHERE c IS NULL>. A column that holds NULL rows ends the
run with a L<DBIO::Exception> naming table, column, row count and the way out,
before any statement has been executed: the server would accept the
C<MODIFY>, switch the metadata at once and fail in the background mutation,
leaving the column unreadable and the table's mutation queue stuck. The remedy
is by hand:

    ALTER TABLE t UPDATE c = <value> WHERE c IS NULL SETTINGS mutations_sync = 1

then run the upgrade again.

=head2 _refuse_not_null_added_over_rows

Likewise a non-nullable C<ADD COLUMN> B<without a default> to a table that holds
rows (L<DBIO::ClickHouse::Diff::Column/needs_row_check>) ends the run before the
first statement: the server would fill the existing rows with the type's zero
value.

=head2 upgrade

    my $diff = $deploy->upgrade;

Convenience: L</diff> then L<apply|DBIO::Deploy::Base/apply>. Returns the diff
object if changes were applied, or C<undef> if the database was already up to
date. Inherited from L<DBIO::Deploy::Base>, with its C<allow_destructive> and
C<dry_run> arguments.

A materialized view (or live or window view) that was created by hand and is not
declared by the schema blocks C<upgrade>: the diff refuses it loudly (see
L<DBIO::ClickHouse::Diff/View>, "Materialized views are refused") rather than
dropping data. Declare it or drop it yourself before the upgrade.

=head1 THE SCRATCH DATABASE

SQLite and DuckDB build the desired-state model in C<:memory:>.
B<ClickHouse has no in-memory and no embedded mode at all> -- not a
C<:memory:> DSN, not a file database, nothing that runs in-process. The only
place a ClickHouse schema can be deployed is a ClickHouse server.

So the throwaway target is a scratch B<database> on the very same server the
live schema lives on:

    CREATE DATABASE `dbio_deploy_tmp_<pid>_<epoch>`
      -> connect to it (DSN rewritten from the live connect_info)
      -> run install_ddl
      -> introspect
      -> disconnect
    DROP DATABASE IF EXISTS `dbio_deploy_tmp_<pid>_<epoch>`

which is the same shape L<DBIO::MySQL::Deploy> and L<DBIO::PostgreSQL::Deploy>
use, and is why this class subclasses L<DBIO::Deploy::Base::TempDatabase>
rather than overriding C<_build_target_model> itself. Only the two-statement
dialect seam (L</_create_temp_db> / L</_drop_temp_db>) is ClickHouse's own.

The name carries the PID and the current epoch second, so two processes -- and
the same process twice -- never collide.

=head2 What this costs you

The scratch database is real, on the real server. It is created empty, gets
the schema (no rows), and is dropped again, so it costs a metadata write and
whatever the DDL itself costs. But it does mean:

=over 4

=item * the connecting user needs C<CREATE DATABASE> and C<DROP DATABASE>. On
a locked-down cluster, run C<diff> from an account that has them, or generate
the DDL offline with L<DBIO::ClickHouse::DDL/install_ddl> and review it by
hand.

=item * on a replicated cluster, C<CREATE DATABASE> without C<ON CLUSTER>
creates the scratch database on the coordinating node only. That is what we
want -- it is throwaway -- but a C<Replicated*> engine in the schema will want
a ZooKeeper path, and those paths are not scoped to the scratch database.
Deploy such schemas against a single node, or review the diff before applying.

=back

=head2 Cleanup is guaranteed, and never eats the real error

The lifecycle is inherited verbatim from
L<DBIO::Deploy::Base::TempDatabase/_build_target_model>, which is already the
C<try>/C<finally> shape this needs:

    my $temp_db = $self->_create_temp_db($dbh);
    my $model   = eval { $self->_deploy_and_introspect_temp($temp_db) };
    my $err     = $@;
    eval { $self->_drop_temp_db($dbh, $temp_db) };   # always, in its own eval
    die $err if $err;                                # original error, unchanged

Three properties matter, and all three are already true there:

=over 4

=item * B<The drop always runs.> It is not conditional on the deploy having
succeeded, so a schema with one bad C<CREATE TABLE> does not leak a scratch
database.

=item * B<The drop cannot swallow the original error.> It is wrapped in its
own C<eval>, and C<$err> was captured B<before> it ran, so a cleanup that
itself fails (server gone, permission revoked mid-run) cannot overwrite the
exception that actually explains what went wrong.

=item * B<The drop uses the live connection>, not the scratch one. The scratch
connection is opened and closed inside C<_deploy_and_introspect_temp>; if it
dies mid-flight the drop still has a working handle to issue C<DROP DATABASE>
on.

=back

B<Why not a guard object.> A C<DESTROY>-based guard buys one thing this shape
lacks -- cleanup on C<exit> or an uncaught signal -- and costs several. It
fires during global destruction, where the C<$dbh> it needs may already be torn
down, so the drop it exists to guarantee is exactly the one that can fail
silently. And error handling inside C<DESTROY> is where original exceptions get
mangled -- this distribution has already had to replace core's scope-guard
C<DESTROY> for exactly that reason, see
L<DBIO::ClickHouse::Storage::TxnScopeGuard>. Adding a second guard with the same
hazard, to cover a case (C<kill -9>) that no in-process mechanism covers
anyway, would trade a guarantee we have for one we cannot keep. A scratch
database that survives a C<kill -9> is named C<dbio_deploy_tmp_*> and is safe
to drop by hand.

=head2 No transactions are involved

Nothing in this lifecycle depends on a transaction, and nothing may: this
storage's C<txn_rollback> always throws
(C<docs/adr/0003-no-transactions-policy.md>). The
C<CREATE DATABASE> / C<DROP DATABASE> pair is the unit of recovery, which is
why the drop is a plain statement in its own C<eval> rather than a rollback.

L<DBIO::Deploy::Base/_execute_ddl> would wrap its statement loop in
C<< $storage->txn_do >> if the storage reported the C<transactional_ddl>
capability. L<DBIO::ClickHouse::Storage> declares
C<< _use_transactional_ddl(0) >>, so the
loop runs statement at a time and core emits its one-time
"non-transactional DDL" notice. That notice is accurate: a multi-statement
C<apply> that fails half way through leaves the earlier statements applied.
Re-running C<upgrade> is safe -- the diff is recomputed against live state, so
the second run picks up only what is left.

=head1 SEE ALSO

=over 4

=item * L<DBIO::ClickHouse> - the schema component

=item * L<DBIO::ClickHouse::DDL> - generates the desired-state DDL

=item * L<DBIO::ClickHouse::DDL::Emit> - the C<CREATE> / C<DROP DATABASE> statements

=item * L<DBIO::ClickHouse::Introspect> - reads live database state

=item * L<DBIO::ClickHouse::Diff> - compares the two models

=item * L<DBIO::Deploy::Base::TempDatabase> - the scratch-database lifecycle

=item * L<DBIO::MySQL::Deploy> - the sibling that shares that lifecycle

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
