package DBIO::SQLite::Deploy;
# ABSTRACT: Deploy and upgrade SQLite schemas via test-deploy-and-compare

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Deploy::Base';

use DBI;
use DBIO::SQLite::DDL;
use DBIO::SQLite::Introspect;
use DBIO::SQLite::Diff;
use DBIO::SQLite::Extension ();
use DBIO::Exception;
use DBIO::SQLite::Util qw(quote_identifier);


# --- hooks for Deploy::Base -------------------------------------------------

sub _ddl_class        { 'DBIO::SQLite::DDL' }
sub _introspect_class { 'DBIO::SQLite::Introspect' }
sub _diff_class       { 'DBIO::SQLite::Diff' }


sub _build_target_model {
  my ($self) = @_;

  my $temp_dbh = DBI->connect('dbi:SQLite::memory:', '', '', {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
  });
  $temp_dbh->do('PRAGMA foreign_keys = ON');

  $self->_execute_ddl($temp_dbh, $self->_install_ddl);

  my $model = $self->_new_introspect($temp_dbh)->model;
  $temp_dbh->disconnect;
  return $model;
}

# --- database extensions (ADR 0066) -------------------------------------------


sub install {
  my ($self) = @_;
  $self->_resolve_extension_list;
  return $self->SUPER::install;
}


sub _resolve_extension_list {
  my ($self) = @_;
  return DBIO::SQLite::Extension->resolve_list($self->schema);
}


sub _extension_list {
  my ($self) = @_;
  my $list = $self->_resolve_extension_list or return [];
  return [ $list->entries ];
}


sub _extension_driver_helpers { DBIO::SQLite::Extension->driver_helpers }


my %_CLAIM_SECTION = map { $_ => 1 } qw( tables columns indexes foreign_keys triggers );

sub _apply_extension_claims {
  my ($self, $model, $addresses) = @_;
  for my $address (@$addresses) {
    my ($kind, @args) = @$address;

    if (($kind // '') eq 'table') {
      delete $model->{$_}{ $args[0] } for grep { $model->{$_} } keys %_CLAIM_SECTION;
    }
    elsif (($kind // '') eq 'column') {
      my ($table, $column) = @args;
      my $columns = ($model->{columns} || {})->{$table} or next;
      @$columns = grep { $_->{column_name} ne $column } @$columns;
    }
    else {
      DBIO::Exception->throw(sprintf
        "extension claim: the address [%s] is of a kind this deploy does not know (table, column)",
        join(', ', map { defined $_ ? $_ : 'undef' } @$address));
    }
  }
  return;
}



sub _refuse_unfillable {
  my ($self, $diff, $dbh) = @_;

  my $has_rows = sub {
    my ($table, $where) = @_;
    return scalar $dbh->selectrow_array(sprintf 'SELECT 1 FROM %s%s LIMIT 1',
      quote_identifier($table), $where // '');
  };

  my @asks;
  for my $op (@{ $diff->operations }) {
    if ($op->isa('DBIO::SQLite::Diff::Column')) {
      next unless $op->action eq 'add'
        && DBIO::SQLite::Diff::_added_not_null_without_default($op->new_info);
      push @asks, [ $op->table_name, $op->column_name, 'added' ];
    }
    elsif ($op->isa('DBIO::SQLite::Diff::Rebuild')) {
      push @asks, [ $op->table_name, $_->{column}, $_->{kind} ]
        for @{ $op->data_checks // [] };
    }
  }

  for my $ask (@asks) {
    my ($table, $column, $kind) = @$ask;
    if ($kind eq 'added') {
      next unless $has_rows->($table);
      DBIO::Exception->throw(sprintf
        'SQLite refuses to add the column %s.%s: it is NOT NULL without a '
        . 'default, and table %s holds rows that would have no value for it',
        $table, $column, $table);
    }
    next unless $has_rows->($table, ' WHERE ' . quote_identifier($column) . ' IS NULL');
    DBIO::Exception->throw(sprintf
      'SQLite refuses to make the column %s.%s NOT NULL: table %s holds rows '
      . 'where it is NULL',
      $table, $column, $table);
  }

  return;
}


sub _check_before_apply {
  my ($self, $diff) = @_;

  # Rendered in full before anything runs: an op that refuses (karr k73)
  # throws here.
  $diff->statements;

  $self->_refuse_unfillable($diff, $self->_dbh);
  return;
}

sub _execute_diff {
  my ($self, $diff) = @_;

  my @statements = $diff->statements;
  my $dbh        = $self->_dbh;

  $self->{_extension_protocol}->assert_no_refusals if $self->{_extension_protocol};

  unless (grep { $_->isa('DBIO::SQLite::Diff::Rebuild') } @{ $diff->operations }) {
    $self->_execute_ddl($dbh, join "\n", @statements);
    return 1;
  }

  my @pragmas = qw(foreign_keys legacy_alter_table);
  my %before  = map { $_ => scalar $dbh->selectrow_array("PRAGMA $_") } @pragmas;

  my $restore = sub {
    $dbh->do(sprintf 'PRAGMA %s=%s', $_, $before{$_} ? 'ON' : 'OFF') for @pragmas;
  };

  my $ok    = eval { $self->_execute_ddl($dbh, join "\n", @statements); 1 };
  my $error = $@;

  # The error to throw is the one that stopped the diff, as it came; what
  # goes wrong while tidying up after it is only reported.
  unless ($ok) {
    # What a failed rebuild left open. Not every failure leaves a savepoint
    # -- the statement that failed may belong to another op -- and without
    # one there is nothing to roll back.
    for my $cleanup ('ROLLBACK TO dbio_rebuild', 'RELEASE dbio_rebuild') {
      eval { $dbh->do($cleanup); 1 }
        or $@ =~ /no such savepoint/
        or warn "$cleanup after a failed rebuild: $@";
    }

    # After the savepoint is gone: foreign_keys cannot be switched inside one.
    eval { $restore->(); 1 }
      or warn "restoring the connection after a failed rebuild: $@";

    die $error;
  }

  $restore->();

  return 1 unless $before{foreign_keys};

  my $bad = $dbh->selectall_arrayref('PRAGMA foreign_key_check');
  if (@$bad) {
    my %tables = map { ($_->[0] // '?') => 1 } @$bad;
    $self->schema->storage->throw_exception(
      'Foreign key violations after table rebuild: ' . join(', ', sort keys %tables)
    );
  }

  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Deploy - Deploy and upgrade SQLite schemas via test-deploy-and-compare

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::SQLite::Deploy> orchestrates the deployment and upgrade of
SQLite schemas using a test-deploy-and-compare strategy.

For upgrades, instead of computing diffs from abstract class
representations, it:

=over 4

=item 1. Introspects the live database via C<sqlite_master> and PRAGMAs

=item 2. Connects to a fresh in-memory SQLite database

=item 3. Deploys the desired schema (from DBIO classes) into the in-memory DB

=item 4. Introspects the in-memory database the same way

=item 5. Computes the diff between the two models using L<DBIO::SQLite::Diff>

=back

The temp DB is in-memory and goes away when the connection drops -- much
simpler than the temp-database approach used for PostgreSQL.

The orchestration (C<install>, C<upgrade>) and the C<diff> shell come from
L<DBIO::Deploy::Base>; the engine-specific target-model build is overridden
here, and the two hooks of L<DBIO::Deploy::Base/apply>, which have a table
rebuild to look after: L</_check_before_apply> and L</_execute_diff>. The
class has no C<apply> and no C<upgrade> of its own; both are inherited.

    my $deploy = DBIO::SQLite::Deploy->new(
        schema => MyApp::DB->connect("dbi:SQLite:dbname=app.db"),
    );

    # Fresh install
    $deploy->install;

    # Upgrade
    $deploy->upgrade;

    # Or in steps:
    my $diff = $deploy->diff;
    print $diff->summary;
    $deploy->apply($diff) if $diff->has_changes;

=head2 Transactional DDL -- deliberately not used

SQLite I<has> transactional DDL, and this deploy still does not use it.
L<DBIO::SQLite::Storage> declares C<< _use_transactional_ddl(0) >>, so
L<DBIO::Deploy::Base/_execute_ddl> runs the statements one at a time with
C<AutoCommit> on and core emits its one-time "non-transactional DDL" notice.
Among the drivers answering C<0> this is the only one where the engine is not
the reason.

The reason is the rebuild. L<DBIO::SQLite::Diff::Rebuild> brackets its
create / copy / drop / rename dance with C<PRAGMA foreign_keys=OFF> and
C<PRAGMA foreign_keys=ON>, and that pragma is a no-op inside a transaction:
SQLite only lets foreign key enforcement be switched while no C<BEGIN> or
C<SAVEPOINT> is pending, and it says so by ignoring the statement rather than
by raising an error. Under a C<< $storage->txn_do >> bracket the C<BEGIN>
comes first, both pragmas evaporate silently, and the C<DROP TABLE> in the
middle of the rebuild -- which performs an implicit C<DELETE FROM> while
enforcement is on -- fails with C<FOREIGN KEY constraint failed> for any table
another table references. SQLite's own rebuild recipe puts the C<OFF> before
the transaction and the restore after the commit, which is the ordering this
declaration buys for free.

The notice core prints is accurate for the diff as a whole: an C<apply> that
fails half way leaves the statements B<before> the failing op applied -- a
table created, a column added, an earlier table rebuilt. Re-running
C<upgrade> is safe, because the diff is recomputed against live state and the
second run picks up only what is left.

A single rebuild is not left half way. It runs between C<SAVEPOINT
dbio_rebuild> and C<RELEASE dbio_rebuild>, and when one of its statements
fails L</_execute_diff> rolls back to the savepoint: the table is there as it was,
with its rows, indexes and triggers, and nothing is left under the
C<__dbio_rebuild> name. The two pragmas of the bracket, which no rollback
undoes, are put back by L</_execute_diff> as well, to what the connection had before
-- after a failure and after a success. So the rebuild is all or nothing, and
the diff around it is not.

L</_execute_diff> also supplies the last step of SQLite's recipe -- C<PRAGMA
foreign_key_check> once the rebuilt table is back in place, on a connection
that enforces foreign keys.

Only the live connection is affected either way: L</_build_target_model>
deploys into a handle it opened itself, which C<_execute_ddl> never brackets
regardless of the capability.

=head1 METHODS

=head2 _build_target_model

Connect to a throwaway in-memory SQLite database, deploy the desired
schema into it, and return its introspected model. The in-memory
connection goes out of scope at the end of this method (and is
disconnected explicitly for predictability), so the target DB is gone
before the diff object is built.

=head2 install

    $deploy->install;

Resolves the declared extensions first (L</_resolve_extension_list>), so that a
declaration that cannot be resolved dies before anything is written, then runs
the inherited install.

=head2 _resolve_extension_list

    my $list = $self->_resolve_extension_list;   # DBIO::Extension::List, or undef

The declared list of extensions resolved to classes, without the database: the
classes are loaded, their interface version and driver checked. C<undef> when
the schema declares none. A class that does not load, a wrong interface version
and a class of another driver throw here (L<DBIO::Extension::List>).

=head2 _extension_list

The hook of L<DBIO::Deploy::Base/_extension_list>: the entries of
L</_resolve_extension_list>, C<[]> when the schema declares none. No installed
state is attached (L</Installed state>).

=head2 _extension_driver_helpers

The helpers every extension gets as C<< $ctx->{driver} >> (L</Addresses>).

=head2 _apply_extension_claims

    $self->_apply_extension_claims($model, \@addresses);

Removes the claimed objects from the model with their cascade (L</Claims and their cascade>).

=head2 _execute_diff

    $self->_execute_diff($diff);

The driver's way to run a diff that L<DBIO::Deploy::Base/apply> has released
and L</_check_before_apply> has passed. It runs the statements of the diff
(L<DBIO::SQLite::Diff/statements>) against the connected database and returns
true. C<apply> and C<upgrade>, with C<allow_destructive> and C<dry_run>, are
inherited from L<DBIO::Deploy::Base>.

All statements are rendered before the first one runs, and
L</_check_before_apply> renders them already, so a diff with a change that is
refused (L<DBIO::SQLite::Diff::Column/Changes that are refused>) throws with
the database untouched.

They go through L<DBIO::Deploy::Base/_execute_ddl> as one batch -- with one
exception. That method takes text and cuts it into statements, and the cut is
not right for every statement that holds a semicolon: a C<CREATE TRIGGER>
does, between the statements of its body, and a bare C<end> or C<begin> as a
column name in it is read as the body's own. Such a statement is
handed to C<< $dbh->do >> whole, between the batch before it and the batch
after it. A diff without one is a single C<_execute_ddl> call.

For a diff that B<rebuilds a table> (L<DBIO::SQLite::Diff::Rebuild>) this
method adds what the SQL text cannot know, the state of the connection:

=over 4

=item * C<PRAGMA foreign_keys> and C<PRAGMA legacy_alter_table> are read
before the first statement and put back to those values afterwards, whether
the diff applied or failed. The rebuild switches both, and its text ends in
a fixed C<legacy_alter_table=OFF> and C<foreign_keys=ON>, which is not
necessarily what the connection had.

=item * If a statement fails, the rebuild that was open is rolled back to its
savepoint, so the table is there as before -- with its rows, indexes and
triggers, and with no C<__dbio_rebuild> table beside it. The error is thrown
on as it came.

=item * If foreign keys were enforced before, C<PRAGMA foreign_key_check> runs
once the diff is applied, and its findings are thrown as C<Foreign key
violations after table rebuild: ...>, naming the tables. The rebuild ran with
enforcement off; this is the check SQLite's own recipe ends with. On a
connection that does not enforce foreign keys a dangling row is the caller's
declared state and no finding of this upgrade, so nothing is checked.

=back

A diff without a rebuild gets none of this: no pragma is read or written.

=head2 _refuse_unfillable

    $self->_refuse_unfillable($diff, $dbh);

Looks at the rows of the live tables before the first statement runs, and
refuses -- a L<DBIO::Exception> naming table and column -- what SQLite would
refuse for them half way through the diff:

=over 4

=item * a C<NOT NULL> column without a default (or with C<DEFAULT NULL>) that
        the diff adds to a table that holds rows, by C<ADD COLUMN> or by a
        rebuild: SQLite has no value for the rows already there (C<Cannot add a
        NOT NULL column with default value NULL>, or C<NOT NULL constraint
        failed> in the copy of the rebuild);

=item * a column that becomes C<NOT NULL> in a table that has a C<NULL> in it:
        the rebuild copies it into the new table and the constraint fails.

=back

An empty table, and a table with no C<NULL> in the column, pass: nothing is
refused that SQLite would accept. The rebuild rolls itself back, but the ops
before it in the diff are applied by then and the refusal leaves them alone.

=head2 _check_before_apply

    $self->_check_before_apply($diff);

The check of L<DBIO::Deploy::Base/apply> against the live tables, run once the
diff is released and before the first statement. It renders the statements of
the diff, so that a refused change throws here with the database untouched,
and then runs L</_refuse_unfillable>.

=over 4

=item * L<DBIO::SQLite> - schema component

=item * L<DBIO::SQLite::DDL> - generates DDL used by C<install> and C<diff>

=item * L<DBIO::SQLite::Introspect> - reads live database state

=item * L<DBIO::SQLite::Diff> - compares two introspected models

=item * L<DBIO::Deploy::Base> - shared install/apply/upgrade orchestration

=item * L<DBIO::PostgreSQL::Deploy> - the PostgreSQL counterpart (temp-database variant)

=back

=head1 EXTENSIONS

The database extensions a schema has are a declared list the deploy runs (ADR
0066 of DBIO core). This class is the driver's side of it; the protocol itself
-- the phases, the merges and their refusals -- is core's
(L<DBIO::Deploy::Base/diff>, L<DBIO::Extension::Protocol>), and the classes of
the extensions are the family's (L<DBIO::Extension>, L<DBIO::SQLite::Extension>).

=head2 The form of the declaration

The list is L<DBIO::SQLite/sqlite_extensions> and nothing else; an extension is
not pulled in by loading a component.

  __PACKAGE__->sqlite_extensions('fts5', 'rtree');
  __PACKAGE__->sqlite_extensions(vec0 => { library => '/opt/sqlite/vec0.so' });

A name the family has a class for gets it from the fixed table of
L<DBIO::SQLite::Extension> (C<fts5>, C<rtree>); the option C<class> names the
class of an extension outside the family and wins; any other name gets the
plain class, which has no rules for the model. The class is loaded and its
interface version and driver checked when the list is resolved
(L</_resolve_extension_list>): at L</install>, and at C<diff>.

=head2 Installed state

SQLite has no catalog of loaded extensions: a library is loaded into a
connection, nothing of it is in the file. The entries of the list therefore
carry no installed state (C<installed> is false, C<version> and C<schema>
absent). What the database says about an extension is the B<probe> of the
extension's own C<inspect> (L<DBIO::SQLite::Extension::VirtualTable/inspect>),
which reads the module list and C<sqlite_master> over the live connection; it
is in C<< $ctx->{self}{state} >> and C<< $ctx->{peers}{$name}{state} >>, and in
the model as C<< $model->{extensions}{$name} >>, read-only. The deploy never
creates, updates or drops an extension: a library is the connection's, and
L<DBIO::SQLite::Storage/_activate_extensions> loads it. The target model is
built in a throw-away in-memory database that loads no library.

=head2 Addresses

An address names an object of the model. The deploy knows two kinds; an
address of another kind is refused, naming it.

  [ table  => $name ]                 a table or view, by its name in the model
  [ column => $table, $column ]       one column of a table

The helpers in C<< $ctx->{driver} >> build them: C<table($name)>,
C<column($table, $column)>, and C<quote_ident>.

=head2 Claims and their cascade

An extension claims an address when the object is its own and not the
application's (FTS5, R*Tree: the shadow tables of a virtual table). Claiming
removes the object from the model, on both sides of a diff, so the diff neither
creates nor drops it. An address the model does not hold is passed over:
claiming is idempotent.

=over 4

=item * A claimed B<table> takes the table and its columns, indexes, foreign
keys and triggers.

=item * A claimed B<column> takes the column.

=back

What is not followed: a foreign key of another table that points at a claimed
table. It stays as the database has it.

What a claim brings that the introspection does not already do: libsqlite
3.37+ lists the shadow tables of every virtual table as C<shadow> in C<PRAGMA
table_list> and L<DBIO::SQLite::Introspect::Tables> leaves them out of the
model, so for FTS5 and R*Tree the claims find nothing left to take.
They are the declared statement of the same fact -- by the name of the module,
and without the pragma -- and what makes a third party's extension with shadow
tables (C<spellfix1>, a table-valued library) work the same way. On libsqlite
before 3.37 the introspection refuses a database with a virtual table before
any claim can run.

=head2 Annotations

This deploy has no attribute to add to an object of its model: an extension
that answers C<annotate> with a triple is refused (the default of
L<DBIO::Deploy::Base/_apply_extension_annotations>).

=head2 Verdicts

The diff of this driver asks no extension for a verdict.

=head2 Not here

Loading the libraries into a connection (C<library>) and the storage layers
an extension class names (L<DBIO::SQLite/connection>) are the connect path's, not
the deploy's.

B<SpatiaLite> is not supported by a class of the family: C<mod_spatialite> could
not be loaded on the host this was written on, so no rule for its metadata
tables (C<geometry_columns>, C<spatial_ref_sys>, ...) was measured. Declared as
C<< spatialite => { library => 'mod_spatialite' } >> it is loaded into every
connection, and its tables are model tables to this deploy.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
