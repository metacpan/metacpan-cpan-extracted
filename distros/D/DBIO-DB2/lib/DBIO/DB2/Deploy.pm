package DBIO::DB2::Deploy;
# ABSTRACT: Deploy and upgrade DB2 schemas via test-deploy-and-compare

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Deploy::Base';

use DBIO::DB2::DDL qw(_db2_quote_ident _db2_quote_table _split_table_name);
use DBIO::DB2::Introspect ();
use DBIO::DB2::Diff ();
use DBIO::SQL::Util ();
use DBIO::DB2::Diff::Reorg ();
use Carp ();
use DBIO::Exception ();


# --- class-name hooks for DBIO::Deploy::Base -------------------------------

sub _ddl_class       { 'DBIO::DB2::DDL'        }
sub _introspect_class { 'DBIO::DB2::Introspect' }
sub _diff_class      { 'DBIO::DB2::Diff'       }


sub _new_introspect {
  my ($self, $dbh, $schema) = @_;
  return $self->_introspect_class->new(
    dbh => $dbh,
    (defined $schema ? (schema => $schema) : ()),
  );
}


sub _introspect_current {
  my ($self) = @_;
  my $dbh = $self->_dbh;
  $self->_refuse_cross_schema_keys($self->schema);
  my $model = $self->_new_introspect($dbh, $self->_current_schema($dbh))->model;

  # The schemas of the tables named schema.table (karr k57): read as well, the
  # declared tables of them only, under the name schema.table. A schema the
  # server does not have is an empty model; a table of a schema that the
  # declaration does not name is in no model, so no diff ever drops it.
  for my $schema_name ($self->_qualified_schemas) {
    my %declared = map { $_->[0] =~ /\A\Q$schema_name\E\.(.*)\z/s ? ($1 => 1) : () }
      DBIO::DB2::DDL->qualified_tables($self->schema);
    my $other = $self->_new_introspect($dbh, $schema_name)->model;
    $self->_merge_schema_model($model, $other, $schema_name, \%declared);
  }
  return $model;
}


sub _qualified_schemas {
  my ($self) = @_;
  my %seen;
  return sort grep { !$seen{$_}++ } map { $_->[1] } DBIO::DB2::DDL->qualified_tables($self->schema);
}


sub _merge_schema_model {
  my ($self, $model, $other, $schema_name, $declared) = @_;
  my %keep = map { $_ => 1 }
    grep { $declared->{$_} && (($other->{tables}{$_}{kind}) // 'table') eq 'table' }
    keys %{ $other->{tables} || {} };
  my $name = sub { "$schema_name.$_[0]" };

  for my $table (sort keys %keep) {
    my $q = $name->($table);
    $model->{tables}{$q} = { %{ $other->{tables}{$table} }, table_name => $q };
    $model->{columns}{$q} = $other->{columns}{$table} if $other->{columns}{$table};
    $model->{indexes}{$q} = $other->{indexes}{$table} if $other->{indexes}{$table};
    $model->{unique_constraints}{$q} = $other->{unique_constraints}{$table}
      if $other->{unique_constraints}{$table};
    $model->{foreign_keys}{$q} = [ map {
      my %fk = %$_;
      $fk{to_table} = $name->($fk{to_table}) if defined $fk{to_table} && $declared->{ $fk{to_table} };
      \%fk;
    } @{ $other->{foreign_keys}{$table} } ] if $other->{foreign_keys}{$table};
  }
  return $model;
}


sub _refuse_cross_schema_keys {
  my ($self, $schema) = @_;
  for my $moniker (sort $schema->sources) {
    my $source = $schema->source($moniker);
    next if $source->isa('DBIO::ResultSource::View');
    my $table = DBIO::DB2::DDL::_resolve_table_name($source->name);
    next unless defined $table;
    my ($from_schema) = _split_table_name($table);
    for my $fk (DBIO::DB2::DDL::_table_foreign_keys($schema, $source)) {
      my ($to_schema) = _split_table_name($fk->{to_table});
      next if ($from_schema // '') eq ($to_schema // '');
      DBIO::Exception->throw(sprintf
        'DBIO::DB2: the diff is refused: the foreign key %s from the table "%s" to the table "%s" '
        . 'crosses schemas, and the compare deploy holds the tables of one schema at a time; '
        . 'nothing has been executed',
        $fk->{constraint_name}, $table, $fk->{to_table});
    }
  }
  return;
}

# Read the connection's CURRENT SCHEMA. Shared by _introspect_current (which
# scopes the source introspection to it) and _build_target_model (which saves it
# to put back). CURRENT SCHEMA is CHAR(128), space-padded; right-trim before use
# -- SYSCAT stores schema names unpadded, and the padding would also travel into
# the string constant _set_current_schema builds.
sub _current_schema {
  my ($self, $dbh) = @_;
  return DBIO::DB2::DDL::current_schema($dbh);
}

# Point CURRENT SCHEMA at $schema. The value is passed as a STRING CONSTANT, not
# as a bare identifier: a bare name folds to uppercase, which would silently
# rewrite a saved lower/mixed-case schema on the way back.
sub _set_current_schema {
  my ($self, $dbh, $schema) = @_;
  (my $literal = $schema) =~ s/'/''/g;
  $dbh->do("SET CURRENT SCHEMA = '$literal'");
  return;
}


sub _install_ddl {
  my ($self) = @_;
  return $self->_ddl_class->install_ddl($self->schema, $self->_current_schema($self->_dbh));
}


sub _build_target_model_for {
  my ($self, $opt) = @_;
  my $dbh         = $self->_dbh;
  # Must start with a letter and be uppercase: DB2 rejects a leading-underscore
  # unquoted identifier (CREATE SCHEMA _dbio_test_<pid> => SQL20521N), and SYSCAT
  # stores schema names uppercased, so a lowercase name would never match the
  # introspect filter (WHERE tabschema = ?). $$ is digits, so DBIO_TEST_<pid> is a
  # valid bare uppercase identifier that round-trips through SYSCAT unchanged.
  my $test_schema = 'DBIO_TEST_' . $$;

  # Read CURRENT SCHEMA BEFORE the first side effect. The compare deploy runs
  # with the register pointed at the throwaway schema (see the head of this
  # method), and this is the value that has to go back onto the SHARED handle
  # afterwards -- so a value we cannot read is a run we must not start. Refusing
  # here costs nothing; refusing after CREATE SCHEMA would leak one.
  my $saved_schema = $self->_current_schema($dbh);
  die ref($self) . ": cannot read CURRENT SCHEMA -- refusing to run the compare "
    . "deploy, because the live connection's schema could not be restored "
    . "afterwards\n"
    unless defined $saved_schema && length $saved_schema;

  # Defensively clear a same-named schema leaked by a crashed prior run (or an
  # earlier same-pid call whose teardown was skipped) so CREATE SCHEMA cannot
  # collide (SQL0601N). _drop_test_schema is best-effort and copes with a
  # populated schema.
  my ($exists) = $dbh->selectrow_array(
    'SELECT 1 FROM syscat.schemata WHERE schemaname = ?', undef, $test_schema,
  );
  $self->_drop_test_schema($dbh, $test_schema) if $exists;

  $dbh->do("CREATE SCHEMA $test_schema");

  my $model = eval {
    $self->_set_current_schema($dbh, $test_schema);
    my $ddl = $self->_ddl_class->install_ddl($self->schema, $saved_schema, $opt);
    for my $stmt ($self->_split_qualify_ddl($ddl, $test_schema)) {
      $dbh->do($stmt);
    }
    return $self->_new_introspect($dbh, $test_schema)->model;
  };
  # Capture the build error NOW. Everything below runs evals of its own -- the
  # restore right here, and every statement in _drop_test_schema -- and each of
  # them blanks $@, so the old `die $@ if $@ and not $model` after the teardown
  # read a $@ that belonged to the last teardown eval, not to the build: a build
  # failure came back as a silent undef model (or was masked by a teardown
  # error). ADR 0001 already describes the intent this restores ("re-raises only
  # when the build itself failed").
  my $err = $@;

  # Put CURRENT SCHEMA back before the teardown, so the shared handle is correct
  # again at the earliest possible point. The teardown itself does not depend on
  # it -- every name it emits is explicitly qualified.
  my $restored = eval { $self->_set_current_schema($dbh, $saved_schema); 1 };
  my $restore_err = $@;

  $self->_drop_test_schema($dbh, $test_schema, $model);

  # A failed restore is fatal even when the model came back fine: the handle is
  # shared with the live storage and is now pointing at a schema this method
  # just dropped, so every later unqualified statement would resolve wrong.
  if (!$restored) {
    my $note = ref($self) . ": failed to restore CURRENT SCHEMA to "
      . "'$saved_schema' after the compare deploy -- the shared connection is "
      . "left pointing at the dropped compare schema: $restore_err";
    die $err ? "$err\n$note\n" : "$note\n";
  }
  die $err if $err and not $model;

  return $model;
}

sub _build_target_model {
  my ($self) = @_;
  # the tables of the current schema, and then those of each schema named by a
  # table schema.table (karr k57), each in a compare schema of its own
  my $model = $self->_build_target_model_for({ local_only => 1 });
  for my $schema_name ($self->_qualified_schemas) {
    my $other = $self->_build_target_model_for({ only_schema => $schema_name });
    my %declared = map { $_->[0] =~ /\A\Q$schema_name\E\.(.*)\z/s ? ($1 => 1) : () }
      DBIO::DB2::DDL->qualified_tables($self->schema);
    $self->_merge_schema_model($model, $other, $schema_name, \%declared);
  }
  return $model;
}

# Tear down the throwaway compare schema. DB2's DROP SCHEMA ... RESTRICT only
# succeeds on an EMPTY schema, but by this point the schema holds the deployed
# tables, so the schema must be emptied first. SYSPROC.ADMIN_DROP_SCHEMA can drop
# a populated schema, but it requires the SYSTOOLSPACE tablespace, which does not
# exist on a stock DB2 instance (SQL0443N "... SYSTOOLSPACE tablespace does not
# exist"); when it is missing the call fails, the schema is NOT dropped, and the
# next CREATE SCHEMA in the same process collides (SQL0601N). So we tear the
# schema down with plain DDL + catalog lookups, robust on any DB2: drop the FK
# constraints first (so inter-table FK dependencies don't block table drops),
# then the tables (indexes drop with their table) and any views, then the now
# empty schema. Best-effort throughout -- each statement is its own eval so one
# failure does not abort teardown; the caller re-raises only the model-build
# error (when no model was produced). Catalog names match $test_schema verbatim:
# it is the uppercase DBIO_TEST_<pid>, which is how SYSCAT stores it -- so the
# schema prefix stays bare, but the object and constraint names DO NOT: since
# karr k28 they are created quoted and SYSCAT hands them back lowercase, and a
# bare DROP TABLE dbio_test_1.author folds to AUTHOR, misses, and fails under
# the eval without a sound. Every catalog-read name is therefore requoted
# through _db2_quote_ident before it goes back into DDL (karr k29).
sub _drop_test_schema {
  my ($self, $dbh, $test_schema, $model) = @_;
  local $dbh->{FetchHashKeyName} = 'NAME_lc';   # DBD::DB2 upper-cases hashref keys

  # 1. Drop FK constraints owned by tables in the schema (type 'F'), so the
  #    referenced tables can then be dropped in any order.
  my $fks = $dbh->selectall_arrayref(
    q{SELECT tabname, constname FROM syscat.tabconst WHERE tabschema = ? AND type = 'F'},
    { Slice => {} }, $test_schema,
  );
  for my $fk (@{ $fks || [] }) {
    eval {
      local $dbh->{PrintError} = 0;
      my $tbl  = _db2_quote_ident($fk->{tabname});
      my $name = _db2_quote_ident($fk->{constname});
      $dbh->do("ALTER TABLE $test_schema.$tbl DROP FOREIGN KEY $name");
    };
  }

  # 2. Drop tables (indexes drop with them) and any views.
  my $tables = $dbh->selectall_arrayref(
    q{SELECT tabname FROM syscat.tables WHERE tabschema = ? AND type = 'T'},
    { Slice => {} }, $test_schema,
  );
  for my $t (@{ $tables || [] }) {
    eval { local $dbh->{PrintError} = 0;
      $dbh->do("DROP TABLE $test_schema." . _db2_quote_ident($t->{tabname})) };
  }
  my $views = $dbh->selectall_arrayref(
    q{SELECT tabname FROM syscat.tables WHERE tabschema = ? AND type = 'V'},
    { Slice => {} }, $test_schema,
  );
  for my $v (@{ $views || [] }) {
    eval { local $dbh->{PrintError} = 0;
      $dbh->do("DROP VIEW $test_schema." . _db2_quote_ident($v->{tabname})) };
  }

  # 3. Drop the now-empty schema.
  eval { local $dbh->{PrintError} = 0; $dbh->do("DROP SCHEMA $test_schema RESTRICT") };
  return;
}

# One object name as DBIO::DB2::DDL emits it: a double-quoted identifier
# (embedded `"` doubled), or -- for a hand-fed script that predates the
# always-quote change -- a bare word.
my $IDENT_RE = qr/"[^"]*(?:""[^"]*)*"|\w+/;

# Internal: rewrite the object positions of the statements DBIO::DB2::DDL
# emits (CREATE/DROP TABLE, CREATE/DROP INDEX, CREATE VIEW, and the inline
# REFERENCES target) so they name $schema instead of the live one. The
# regex pass is conservative -- DBIO::DB2::DDL emits a known shape --
# so we trade a small fragility for not duplicating DDL rendering.
#
# That shape ALWAYS quotes its identifiers since karr k28, so the object name
# matched here must be $IDENT_RE, not a bare \w+: `\w+` cannot match
# CREATE TABLE "author", so every substitution silently did nothing and the
# whole compare DDL ran unqualified against CURRENT SCHEMA -- i.e. into the
# LIVE database (karr k29). CREATE UNIQUE INDEX is matched too; it was never
# covered by the CREATE INDEX branch. The qualified form is
# DBIO_TEST_<pid>."<name>": $test_schema stays bare because it is the
# uppercase name CREATE SCHEMA created and SYSCAT stores, while the object
# keeps the exact quoted case _drop_test_schema and the introspector read
# back out of SYSCAT.
#
# CREATE VIEW is rewritten in its NAME position only. Its body is the user's
# view_definition -- arbitrary SQL this pass has no business parsing -- and is
# passed through verbatim; the compare deploy points CURRENT SCHEMA at
# $test_schema instead, so the body resolves against the compare tables. Both
# halves are needed: the rewrite alone would aim a live-resolving body at a
# compare-schema view (karr k35); the DESCRIPTION section "Views -- the compare
# deploy also moves CURRENT SCHEMA" has the whole argument. DROP VIEW is
# deliberately absent: neither install_ddl nor the diff path emits one, and this
# pass grows only with the shapes that exist.
#
# The inline FK clause from _fk_constraint_clause is
#   CONSTRAINT <name> FOREIGN KEY (<from>) REFERENCES <reftable>(<cols>)
# where <reftable> is UNQUALIFIED. Without rewriting it too, a child table
# deployed into the test schema would resolve its REFERENCES against CURRENT
# SCHEMA (the live schema) and cross-reference the live parent. So we also
# qualify the REFERENCES target to the test schema. The CONSTRAINT name itself
# is schema-scoped in DB2 (it lives in the test table's schema), so it cannot
# collide with the live constraint of the same name and is left untouched.
sub _split_qualify_ddl {
  my ($self, $ddl, $test_schema) = @_;
  # A table named "schema.table" lives in a schema of its own and is no part of the
  # model the diff compares (it reads one schema): its CREATE TABLE and the
  # CREATE INDEX on it stay out of the compare deploy (karr k57).
  my @stmts = grep {
    !/\A\s*CREATE\s+TABLE\s+$IDENT_RE\s*\.\s*$IDENT_RE/
      && !/\A\s*CREATE\s+(?:UNIQUE\s+)?INDEX\s+$IDENT_RE(?:\s*\.\s*$IDENT_RE)?\s+ON\s+$IDENT_RE\s*\.\s*$IDENT_RE/
  } DBIO::SQL::Util::_split_statements($ddl);
  for my $stmt (@stmts) {
    $stmt =~ s/\b(CREATE\s+TABLE)\s+($IDENT_RE)/$1 $test_schema.$2/g;
    $stmt =~ s/\b(DROP\s+TABLE)\s+($IDENT_RE)/$1 $test_schema.$2/g;
    $stmt =~ s/\b(CREATE\s+(?:UNIQUE\s+)?INDEX)\s+($IDENT_RE)\s+ON\s+($IDENT_RE)/$1 $test_schema.$2 ON $test_schema.$3/g;
    $stmt =~ s/\b(DROP\s+INDEX)\s+($IDENT_RE)/$1 $test_schema.$2/g;
    $stmt =~ s/\b(CREATE\s+VIEW)\s+($IDENT_RE)/$1 $test_schema.$2/g;
    $stmt =~ s/\bREFERENCES\s+($IDENT_RE)\s*\(/REFERENCES $test_schema.$1(/g;
  }
  return @stmts;
}


sub _check_before_apply {
  my ($self, $diff) = @_;
  $self->SUPER::_check_before_apply($diff);
  $self->_reorg_pending_before_apply($diff);
  $self->_refuse_identity_on_rows($diff);
  $self->_refuse_unfillable($diff);
  return;
}

# Croaks, naming table and column, for every identity column the diff adds to a
# table that holds a row. Asks once per table, in name order. Private.
sub _refuse_identity_on_rows {
  my ($self, $diff) = @_;

  my %columns = $self->_identity_add_columns($diff);
  my @tables  = keys %columns;

  my $dbh = @tables ? $self->_dbh : undef;
  my @refused;
  for my $table (sort @tables) {
    my ($row) = $dbh->selectrow_array(
      sprintf 'SELECT 1 FROM %s FETCH FIRST 1 ROW ONLY', _db2_quote_table($table));
    push @refused, $table if $row;
  }
  Carp::croak(join "\n", map {
    my $t = $_;
    sprintf 'Cannot add identity column%s %s to table "%s": the table holds rows and Db2 would '
      . 'give every one of them the value 0 (ADD COLUMN ... NOT NULL DEFAULT 0, then SET GENERATED; '
      . 'ADR 0012). Add the column while the table is empty, or add it plain and make it an identity '
      . 'after the rows have their values; nothing has been executed',
      (@{ $columns{$t} } > 1 ? 's' : ''), join(', ', map { qq{"$_"} } @{ $columns{$t} }), $t;
  } @refused) if @refused;

  return;
}

# Throws a DBIO::Exception (a refusal, naming table and column) for what the
# server would refuse in the middle of the apply and Db2 cannot be given a value
# for (karr k57). Nothing has been executed. Private.
sub _refuse_unfillable {
  my ($self, $diff) = @_;

  my $source = $diff->source->{tables} // {};
  my @ops = grep { $_->isa('DBIO::DB2::Diff::Column') && exists $source->{ $_->table_name } }
    @{ $diff->operations };

  for my $op (@ops) {
    DBIO::Exception->throw(sprintf
      'DBIO::DB2: the upgrade is refused: cannot add the column "%s" to table "%s": it is NOT NULL '
      . 'without a default, which Db2 refuses in ALTER TABLE ... ADD COLUMN (SQL0193N) and no value '
      . 'is made up for the rows; give the column a default, or add it nullable; nothing has been executed',
      $op->column_name, $op->table_name) if $op->adds_not_null_without_default;
  }

  for my $op (sort { $a->table_name cmp $b->table_name or $a->column_name cmp $b->column_name }
              grep { $_->sets_not_null } @ops) {
    my ($row) = $self->_dbh->selectrow_array(sprintf
      'SELECT 1 FROM %s WHERE %s IS NULL FETCH FIRST 1 ROW ONLY',
      _db2_quote_table($op->table_name), _db2_quote_ident($op->column_name));
    DBIO::Exception->throw(sprintf
      'DBIO::DB2: the upgrade is refused: cannot make the column "%s" NOT NULL: table "%s" holds rows '
      . 'where it is NULL (SQL0407N) and no value is made up for them; fill the column first; '
      . 'nothing has been executed',
      $op->column_name, $op->table_name) if $row;
  }

  return;
}

# table name => [ column names ] for every identity column the diff adds to a
# table that exists already (Diff::Column::adds_identity). Private.
sub _identity_add_columns {
  my ($self, $diff) = @_;
  my $source = $diff->source->{tables} // {};
  my %columns;
  for my $op (@{ $diff->operations }) {
    next unless $op->isa('DBIO::DB2::Diff::Column') && $op->adds_identity;
    next unless exists $source->{ $op->table_name };
    push @{ $columns{ $op->table_name } }, $op->column_name;
  }
  return %columns;
}

# Runs the REORG for every table of both models of $diff that the server holds
# reorg-pending (see "_check_before_apply"). Private: not an interface.
sub _reorg_pending_before_apply {
  my ($self, $diff) = @_;
  my ($source, $target) = ($diff->source->{tables} // {}, $diff->target->{tables} // {});
  my @common = grep {
    ($source->{$_}{kind} // 'table') eq 'table'
      && ($target->{$_}{kind} // 'table') eq 'table'
  } grep { exists $target->{$_} && !defined +(_split_table_name($_))[0] } keys %$source;
  return unless @common;

  my $dbh    = $self->_dbh;
  my $schema = $self->_current_schema($dbh);
  my $pending = $dbh->selectcol_arrayref(
    q{SELECT tabname FROM sysibmadm.admintabinfo WHERE tabschema = ? AND reorg_pending = 'Y'},
    undef, $schema,
  ) || [];

  my %pending = map { ($_ => 1) } @$pending;
  my @tables = sort grep { $pending{$_} } @common;
  return unless @tables;

  Carp::carp(ref($self) . ': reorg-pending table(s) found before the upgrade, REORG run first: '
    . join(', ', @tables));
  $self->_execute_ddl($dbh, join "\n", map {
    DBIO::DB2::Diff::Reorg->new(action => 'reorg', table_name => $_)->as_sql
  } @tables);
  return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::Deploy - Deploy and upgrade DB2 schemas via test-deploy-and-compare

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::DB2::Deploy> orchestrates schema deployment and upgrades for
DB2 using the test-deploy-and-compare strategy, parallel to
L<DBIO::SQLite::Deploy> and L<DBIO::PostgreSQL::Deploy>.

For upgrades it:

=over 4

=item 1. Introspects the live database via C<SYSCAT>

=item 2. Deploys the desired schema (from DBIO classes) into a temporary
         schema in the same DB (DB2 requires an existing database; only
         a schema can be throwaway)

=item 3. Introspects the database after deployment

=item 4. Computes the diff between the two models using L<DBIO::DB2::Diff>

=back

C<install>/C<diff>/C<apply>/C<upgrade> and the dbh/schema accessors come
from L<DBIO::Deploy::Base>, which also holds the C<allow_destructive> release
(ADR 0080); this class supplies the three class-name hooks
(L<DBIO::Deploy::Base/_ddl_class>, L<DBIO::Deploy::Base/_introspect_class>,
L<DBIO::Deploy::Base/_diff_class>), the
L</_new_introspect> factory that threads a target schema into the
introspector, and the genuinely DB2-specific L</_build_target_model> that
splices the desired schema into a throwaway C<CREATE SCHEMA> block, and
L</_check_before_apply>, the Db2 checks that run before the first statement of
an C<apply>.

    my $deploy = DBIO::DB2::Deploy->new(
        schema => MyApp::DB->connect("dbi:DB2:database=mydb"),
    );
    $deploy->install;                       # fresh
    my $diff = $deploy->diff;              # or step-by-step
    $deploy->apply($diff) if $diff->has_changes;
    $deploy->upgrade;                      # convenience

=head2 Transactional DDL -- the engine has it, this deploy does not use it

Db2 LUW runs DDL inside the unit of work and a C<ROLLBACK> takes it back; the
sentences that say so, with their versions, are quoted at the declaration in
L<DBIO::DB2::Storage>. This deploy still does not use it.
L<DBIO::DB2::Storage> declares C<< _use_transactional_ddl(0) >>, so
L<DBIO::Deploy::Base/_execute_ddl> runs the statements one at a time with
C<AutoCommit> on and core emits its one-time "non-transactional DDL" notice.
Among the drivers answering C<0> DB2 is, with SQLite, one of the two where the
engine is not the reason.

The reason is L</_build_target_model>. DB2 requires an existing database, so
only a I<schema> can be thrown away, and the compare deploy therefore runs on
C<< $self->_dbh >> -- the handle the storage itself owns. The other
transactional engines in this family build their target model through
L<DBIO::Deploy::Base::TempDatabase>, which opens a connection of its own that
core deliberately never brackets. Here there is no second connection to hide
behind, and L<DBIO::DeploymentHandler/upgrade> wraps its I<whole> body -- diff
I<and> apply -- in C<txn_do> once the capability is true. A C<1> would
therefore not just make the migration atomic: it would pull
C<CREATE SCHEMA DBIO_TEST_E<lt>pidE<gt>>, the entire install DDL re-emitted
into that schema, its C<SYSCAT> introspection and the teardown C<DROP>s into
the same live unit of work as the migration, holding catalog locks open for
throwaway work that gains nothing from being atomic.

The notice core prints is accurate about recovery: an C<apply> that fails half
way leaves the earlier statements applied. Re-running L<DBIO::Deploy::Base/upgrade>
is safe, because the diff is recomputed against live state and the second run
picks up only what is left -- which is also what makes the FK pass idempotent,
since a constraint that is already gone is simply not in the next diff.

Turning this into a C<1> is a live-server change, not a flag flip: the compare
deploy has to leave the migration's unit of work first, and the two shapes
nobody has run against a real server -- the drop-then-add FK pair on one
constraint name emitted by L<DBIO::DB2::Diff::ForeignKey>, and the compare
schema being created and dropped inside one unit of work -- have to be
measured. See the declaration comment in L<DBIO::DB2::Storage> for both.

=head2 Views -- the compare deploy also moves CURRENT SCHEMA

C<_split_qualify_ddl> re-points object positions at the compare schema by
rewriting the known statement shapes L<DBIO::DB2::DDL> emits. A C<CREATE VIEW>
breaks that model in half. Its I<name> is an ordinary object position and is
rewritten like any other; its I<body> is the user's own C<view_definition> --
arbitrary SQL, with arbitrary unqualified table references in it.

Qualifying only the name would be worse than doing nothing. A
C<CREATE VIEW DBIO_TEST_E<lt>pidE<gt>."v" AS SELECT ... FROM "author"> resolves
its C<FROM> against CURRENT SCHEMA, i.e. against the B<live> C<author> -- so the
compare view would mean something different from the live view of the same name
and the diff would be comparing two unlike things. Rewriting the body instead
would mean parsing arbitrary SQL in a regex pass whose whole justification is
that it only ever sees a shape this distribution emits itself.

So the body is not rewritten at all: the compare deploy runs with
C<CURRENT SCHEMA> set to the throwaway schema
(C<_set_current_schema>). Db2 qualifies unqualified object references in a
dynamically prepared statement with CURRENT SCHEMA, so the view body resolves
against the compare tables without a single character of it being touched. A
body that qualifies its references explicitly is left pointing where it says,
which is what the live view does too -- the two sides still agree.

Two properties this leans on:

=over 4

=item * B<The register is saved and restored on every path.> The compare deploy
        runs on the handle the live storage owns (see above), so leaving
        CURRENT SCHEMA moved would silently re-point every later unqualified
        statement. It is read before the first side effect, put back before the
        teardown, and a failed restore is fatal.

=item * B<Nothing else in the deploy path depends on the register.> The
        C<SYSCAT> reads in L<DBIO::DB2::Introspect> and C<_drop_test_schema>
        are explicitly qualified, the introspector scopes on C<tabschema> as a
        bind value, and the rewritten DDL names its schema outright. The
        register only reaches the one statement that has no other way of being
        told.

=back

The textual C<CREATE VIEW> rewrite is kept alongside it rather than dropped as
redundant: it is deterministic and testable without a server, and it is what
keeps a view out of the live schema even if the register leg ever fails.

=head1 METHODS

=head2 _new_introspect

    my $intro = $self->_new_introspect($dbh);
    my $intro = $self->_new_introspect($dbh, $schema);

Factory for the introspector. The optional C<$schema> selects the DB2
schema to introspect (defaults to the introspector's own default, used
when introspecting the live C<schema()>).

=head2 _introspect_current

    my $source_model = $self->_introspect_current;

The introspected model of the live (source) database. Overrides the
L<DBIO::Deploy::Base> default, which introspects with no schema arg and so
falls back to L<DBIO::DB2::Introspect>'s C<USER> default -- a schema DB2
connections do not actually use (e.g. C<db2inst1> has CURRENT SCHEMA
C<DB2INST1>), making the source model come back empty and diff/upgrade
phantom-create the whole schema.

Resolves the connection's CURRENT SCHEMA (the schema where C<install_ddl>'s
unqualified objects land) and threads it into the source introspector, so the
high-level diff/upgrade path compares against the live objects rather than an
empty model.

=head2 _qualified_schemas

    my @schemas = $self->_qualified_schemas;

The schemas, sorted and once each, of the tables named C<schema.table> of the
schema (L<DBIO::DB2::DDL/qualified_tables>).

=head2 _merge_schema_model

    $class->_merge_schema_model($model, $other, $schema_name, \%declared);

Merges the tables of C<$other> (the model of one schema, tables under their own
names) that are in C<%declared> and are tables, not views, into C<$model>, under
the name C<schema.table>: the tables, their columns, indexes, foreign
keys and unique constraints. A foreign key to a table of the same schema names
it C<schema.table> as well. Nothing else of C<$other> is taken.

=head2 _refuse_cross_schema_keys

    $self->_refuse_cross_schema_keys($schema);

A foreign key between a table of the current schema and one named
C<schema.table>, or between two schemas, cannot be compared: the compare deploy
holds the tables of one schema at a time. The diff and the upgrade refuse it with
a L<DBIO::Exception> naming both tables, before their first statement.
C<install> writes such a key as declared.

=head2 _install_ddl

The install DDL, with the connection's C<CURRENT SCHEMA> as the schema the views are
created in: a view that reads another through that qualifier is ordered by it, one that
reads through any other schema is not (L<DBIO::DB2::DDL/order_views>).

=head2 _build_target_model

    my $target_model = $self->_build_target_model;

DB2-specific target model construction:

=over 4

=item 1. C<CREATE SCHEMA DBIO_TEST_<pid>> in the same database

=item 2. Point C<CURRENT SCHEMA> at it for the duration of the compare deploy,
         and put the saved value back on every path out (see
         L</Views -- the compare deploy also moves CURRENT SCHEMA>)

=item 3. Re-emit the install DDL with every C<CREATE/DROP TABLE/INDEX>,
         C<CREATE VIEW> and C<REFERENCES> object position schema-qualified to
         the test schema (DBIO::DB2::DDL does not auto-qualify)

=item 4. Introspect the test schema

=item 5. Drop the (now populated) test schema on the way out, even on failure
         (via C<_drop_test_schema>, which copes with a non-empty schema)

=back

Returns the introspected model hashref for the test schema, suitable as
the C<target> of L<DBIO::DB2::Diff>.

=head2 _check_before_apply

The Db2 checks of a diff against the live tables, run by
L<DBIO::Deploy::Base/apply> (and so by L<DBIO::Deploy::Base/upgrade>) once the
diff is released and before its first statement. The order is the reorganisation
of the pending tables, the question for rows an identity column meets, the
refusal of what Db2 cannot be given a value for. C<diff>, C<as_sql> and
C<summary> stay reads and do not look. Nothing has been executed when a check
throws.

=over 4

=item * B<Reorg-pending tables are reorganised first> (ADR 0008
addendum). Reorg-pending is a state of the table and not part of the
introspected model, so after an upgrade that stopped between C<ALTER> and
C<REORG>, a C<REORG> that failed, or an C<ALTER TABLE> run by hand the diff
holds no column operation and therefore no L<DBIO::DB2::Diff::Reorg> -- and its
C<CREATE INDEX>, like every C<INSERT> and every read, dies with SQL0668N reason
code 7. The C<REORG> the diff itself carries covers only the tables its own
column operations put in that state. The tables looked at are those the diff can
touch: a I<table> (not a view) present in the source model B<and> the target
model, in the live schema. A table only in the source is dropped by the diff, a
table only in the target is created by it; a C<REORG> is wasted on the first and
impossible on the second. The server is asked once, through
C<SYSIBMADM.ADMINTABINFO> filtered on C<TABSCHEMA> (the connection's
C<CURRENT SCHEMA>, which is the schema the source model is read from), and not
at all when no table is in both models. Every pending table among them gets
C<CALL SYSPROC.ADMIN_CMD('REORG TABLE ...')>, rendered by
L<DBIO::DB2::Diff::Reorg/as_sql> and run through
L<DBIO::Deploy::Base/_execute_ddl>, tables in name order. A C<warn> (C<carp>)
names the tables, because the rewrite is work the caller did not see in
C<< $diff->as_sql >>. A diff without changes is not applied and reorganises
nothing. The C<REORG> changes neither schema nor rows.

=item * B<An identity column is added to an empty table only> (ADR
0012 addendum). The diff adds an identity column in three statements, C<ADD
COLUMN ... NOT NULL DEFAULT 0>, C<DROP DEFAULT>, C<SET GENERATED ALWAYS AS
IDENTITY>, so every row the table already holds keeps the value 0. For every
table that gets such a column (L<DBIO::DB2::Diff::Column/adds_identity>; the
table is in both models) the server is asked C<SELECT 1 FROM "table" FETCH FIRST
1 ROW ONLY>. A row, and the apply is refused with an exception naming table and
column. An empty table takes the column as built.

=item * B<What Db2 cannot be given a value for is refused>. A
C<NOT NULL> column without a default added to a table that exists (SQL0193N,
whatever rows it holds), and a column made C<NOT NULL> in a table that holds a
row where it is C<NULL> (SQL0407N): the exception names table and column.

=back

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::DB2> - schema component

=item * L<DBIO::DB2::DDL> - generates DDL

=item * L<DBIO::DB2::Introspect> - reads live database state

=item * L<DBIO::DB2::Diff> - compares two introspected models

=item * L<DBIO::Deploy::Base> - shared install/apply/upgrade orchestration

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
