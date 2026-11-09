package DBIO::SQLite::Storage;
# ABSTRACT: SQLite storage driver for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

use base qw/DBIO::Storage::DBI/;
use mro 'c3';

__PACKAGE__->register_driver('SQLite' => __PACKAGE__);

use Context::Preserve 'preserve_context';
use DBIO::Util qw(file_path iv_size mkpath modver_gt_or_eq os_name sigwarn_silencer);
use DBIO::SQLite::Util qw(column_is_nullable pk_is_rowid_alias);
use DBIO::SQLite::Extension ();
use DBIO::Carp;
use Try::Tiny;
use File::Basename ();
use File::Copy ();
use POSIX ();
use namespace::clean;

__PACKAGE__->sql_maker_class('DBIO::SQLite::SQLMaker');
__PACKAGE__->sql_quote_char ('"');
__PACKAGE__->datetime_parser_type ('DateTime::Format::SQLite');

# F02 / F10 -- transactional DDL. Of every driver in this family that answers
# 0, SQLite is the one whose engine HAS it: CREATE / DROP / ALTER TABLE run
# inside an ordinary transaction and a ROLLBACK really does take them back,
# which elsewhere (PostgreSQL, Firebird, SQL Server) is what a 1 is for. The 0
# below is therefore not an engine limitation like it is for MySQL, Oracle or
# ClickHouse, and that is exactly why it has to be written down here rather
# than left to core's conservative default (which is also 0): judged by the
# engine alone this driver looks like an oversight, and "tidying" the omission
# into a 1 is a one-character change that breaks the upgrade path.
#
# What the 0 protects is the in-place table rebuild. SQLite cannot ALTER a
# column's type, nullability or default, so DBIO::SQLite::Diff escalates any
# such change to a DBIO::SQLite::Diff::Rebuild -- the documented create-new /
# copy / drop-old / rename dance -- and that op's statement list opens with
# PRAGMA foreign_keys=OFF and closes with PRAGMA foreign_keys=ON. Both
# brackets are no-ops inside a transaction, by SQLite's own rule: "This pragma
# is a no-op within a transaction; foreign key constraint enforcement may only
# be enabled or disabled when there is no pending BEGIN or SAVEPOINT"
# (sqlite.org/pragma.html#pragma_foreign_keys). Nothing throws and nothing
# warns -- the statement is accepted and simply does not take.
#
# So had this capability been true, DBIO::Deploy::Base::_execute_ddl would
# bracket its loop in $storage->txn_do, the BEGIN would come first, and
# enforcement would still be ON at the DROP TABLE in the middle of the
# rebuild. A DROP TABLE under enforced foreign keys performs an implicit
# DELETE FROM, so dropping the old table while another table still references
# its rows raises "FOREIGN KEY constraint failed"; the rebuild dies half way
# and the ALTER TABLE ... RENAME TO behind it then collides with the table
# that never got dropped. Measured on libsqlite 3.51.1 / DBD::SQLite 1.78.
# t/37-rebuild.t part C is that exact scenario -- a connection with
# PRAGMA foreign_keys = ON rebuilding a table another table references -- and
# it passes today only because the statement-at-a-time path leaves AutoCommit
# on, where the pragma does take.
#
# SQLite's own recipe orders it the same way: PRAGMA foreign_keys=OFF is step
# 1, BEFORE the transaction opened in step 2, and the restore is step 12,
# after the commit (sqlite.org/lang_altertable.html, "Making Other Kinds Of
# Table Schema Changes"). Turning this into a 1 is therefore not a flag flip:
# the pragmas would first have to move out of the diff op's statement list to
# around core's bracket (or _ddl_statement_is_transactional would have to
# answer false for them), and DBIO::SQLite::Deploy::apply's PRAGMA
# foreign_key_check, which today runs after the batch, would have to move
# inside the bracket to be able to roll one back.
#
# Core special-cases nothing: DBIO::Deploy::Base's TRANSACTIONAL DDL section
# lists SQLite as "capable, but deliberately answering no" and points back at
# this declaration as the only thing carrying the decision. The price is core's
# one-time "non-transactional DDL" notice, and it is accurate -- an apply that
# fails part way leaves the earlier statements applied; recovery is re-running
# the upgrade, whose diff is recomputed against live state. Value and
# declaredness are pinned by t/42-deploy-transactional-ddl.t.
__PACKAGE__->_use_transactional_ddl(0);

# Must be defined AFTER `use namespace::clean` — a sub declared before it
# is wiped from the symbol table at end of compile, which would make
# DBIO::Schema/deploy fall back to the (unsupported) SQL::Translator path.
sub dbio_deploy_class { 'DBIO::SQLite::Deploy' }

# The dialect the DDL splitter reads this engine's text in (core karr k332,
# DBIO::Storage::DBI::Capabilities "DDL SPLITTING"); karr k78.
sub _ddl_sql_dialect { 'sqlite' }

# --- extensions (ADR 0066): the activation of a new connection ---------------


sub _extension_activation {
  my ($self) = @_;

  my $list = DBIO::SQLite::Extension->resolve_list($self->schema)
    or return undef;

  require DBIO::Extension::Protocol;
  my $activation = DBIO::Extension::Protocol->new(
    entries           => [ $list->entries ],
    driver            => DBIO::SQLite::Extension->driver_helpers,
    connection_schema => undef,
    restricted        => 0,
  )->activation;

  return @{ $activation->{load} } ? $activation : undef;
}


sub _activate_extensions {
  my ($self, $activation) = @_;

  $self->throw_exception(
    'A SQLite extension library is loaded into the connection handle, which '
  . 'a statement runner of an async pool does not give: the libraries of '
  . 'sqlite_extensions ('
  . join(', ', @{ $activation->{load} }) . ') cannot be activated there'
  ) if $self->{_pool_connect_runner};

  my $dbh = $self->_dbh;
  for my $library (@{ $activation->{load} }) {
    my $ok = eval {
      local $dbh->{RaiseError} = 1;
      $dbh->sqlite_enable_load_extension(1);
      $dbh->sqlite_load_extension($library);
      $dbh->sqlite_enable_load_extension(0);
      1;
    };
    next if $ok;

    my $error = $@;
    $error =~ s/\s+\z//;
    eval { $dbh->sqlite_enable_load_extension(0) };

    # A handle without its extensions is not one to leave in the storage
    # (the rule of DBIO::Storage::DBI/_do_connection_actions): the next use
    # would get a connection that silently lacks the library.
    $self->_dbh(undef);
    $self->throw_exception("Cannot load the SQLite extension library '$library': $error");
  }

  return $self;
}

sub sql_maker {
  my $self = shift;
  my $sm = $self->next::method(@_);
  # SQLite always uses double-quote identifier quoting — ensure it is
  # active even when the caller did not pass quote_names in connect_info.
  $sm->{quote_char} //= $self->sql_quote_char;
  $sm->{name_sep}   //= $self->sql_name_sep;
  $sm;
}

sub _dbh_columns_info_for {
  my ($self, $dbh, $table) = @_;

  my $result = $self->SUPER::_dbh_columns_info_for($dbh, $table) // {};

  # DBD::SQLite's column_info (and its prepared-statement NULLABLE fallback)
  # do not report is_nullable reliably -- PK columns come back as nullable,
  # and columns in unique constraints may also be wrong. PRAGMA table_info
  # is the authoritative source: notnull=1 means NOT NULL. Layer its truth
  # over the parent's result so that PK columns are correctly NOT NULL.
  # Strip any "schema." prefix the caller may have supplied.
  my $bare = $table;
  $bare =~ s/^.*\.//;

  my $sth = eval { $dbh->prepare(sprintf 'PRAGMA table_info(%s)', $dbh->quote($bare)) };
  return $result unless $sth;
  $sth->execute;
  my @rows;
  while (my $row = $sth->fetchrow_hashref) { push @rows, $row }
  $sth->finish;

  # A PRIMARY KEY column carries no NOT NULL attribute of its own, so PRAGMA
  # table_info reports notnull=0 for it -- but on SQLite that is not merely a
  # reporting quirk: every key except the INTEGER PRIMARY KEY rowid alias
  # really does store NULL on a rowid table (karr k29). One probe per table
  # settles which kind of key this is, and only when there is a key at all.
  # column_is_nullable is the single source of truth for the rule itself,
  # shared with DBIO::SQLite::Introspect so both paths answer the same.
  my $alias = (grep { $_->{pk} } @rows) ? pk_is_rowid_alias($dbh, $bare) : 1;

  for my $row (@rows) {
    my $col = $row->{name};
    next unless $col && exists $result->{$col};
    $result->{$col}{is_nullable} =
      column_is_nullable($row->{notnull}, $row->{pk}, $alias);
  }

  return $result;
}



sub _determine_supports_multicolumn_in {
  ( shift->_server_info->{normalized_dbms_version} < '3.014' )
    ? 0
    : 1
}

# INSERT ... RETURNING exists since libsqlite 3.35 (2021-03-12). Without it
# every insert of an autoinc / retrieve_on_insert column costs an extra
# round-trip (last_insert_id + follow-up SELECT in DBIO::Storage::DBI::insert).
# Deliberately NOT declaring insert_returning_bound: like PostgreSQL, and
# unlike Oracle's "RETURNING ... INTO :bind", SQLite hands the values back as
# an ordinary result set on the statement handle, which is exactly what core
# fetches when no returning_container is requested.
sub _determine_supports_insert_returning {
  ( shift->_server_info->{normalized_dbms_version} < '3.035' )
    ? 0
    : 1
}

# ADR 0036 -- atomic upsert. SQLite has had the INSERT ... ON CONFLICT grammar
# since libsqlite 3.24 (2018-06-04), but grammar is not the gate here.
#
# The ADR makes it a hard driver obligation: declare supports_upsert only if the
# identity handed back is provably the row that was written. Core retrieves it
# with last_insert_id() plus a follow-up SELECT on the PRIMARY KEY -- it never
# re-finds by conflict target. An upsert that takes the DO UPDATE branch
# performs no insert, so last_insert_rowid() still reports the PREVIOUS insert
# and core would hand back a confidently wrong, unrelated row. Silent bad data,
# worse than undef.
#
# RETURNING is therefore the precondition, not the round-trip saving it looks
# like -- so gate on the effective insert_returning capability rather than on
# the libsqlite version a second time. Same 3.35 threshold in practice, but it
# also stays correct when RETURNING is deliberately switched off with
# __PACKAGE__->_use_insert_returning(0): a plain version test would keep
# claiming upsert there and go straight back to returning the wrong row.
# Losing upsert on 3.24 - 3.34 is the honest trade.
sub _determine_supports_supports_upsert {
  shift->_use_insert_returning ? 1 : 0
}

# ADR 0036 / core k105 -- the conditional conflict branch, DO UPDATE ... WHERE.
#
# Deliberately NOT gated the way supports_upsert above is. That gate is about
# naming the written row (RETURNING), a requirement the condition does not add
# to: an upsert whose condition does not hold writes nothing and core hands
# back undef, which is why it refuses result => 'row_or_die' with update_where
# up front. The clause itself is coeval with the ON CONFLICT grammar -- both
# arrived in libsqlite 3.24 -- so there is no version left to test either, and
# no configuration in which this driver renders ON CONFLICT but not its WHERE.
#
# What is left is a plain fact about the SQL generator, which is exactly what
# the capability means (see DBIO::Storage::DBI::Capabilities: "implies nothing
# on its own -- it is only ever consulted together with supports_upsert").
# Restating the RETURNING coupling here would make the flag answer a question
# it was not asked; core checks both, in that order, and reports whichever is
# missing.
#
# Declared through _determine_supports_* rather than as __PACKAGE__->_use_ class
# data, matching the driver's other capability declarations. The originally
# recorded reason -- "so that the tier-1 force slot stays the caller's" -- was
# refuted by core k137 / ADR 0041: the per-storage force and the class-level
# declaration are two different slots (instance hash vs the
# $Class::__cag_<field> package variable), so neither declaration form takes
# the caller's force away, and the undef-clearing fix made both forms measure
# 1 / 0 / 1. What the tier-3 form still changes is _supports_X, which answers
# the declaration here but would answer core's default 0 alongside a tier-2
# declaration; no core consumer reads _supports_X for a decision, so this is
# consistency, not correctness.
sub _determine_supports_supports_upsert_where { 1 }

# ADR 0037 -- the boolean-valued EXISTS query behind DBIO::ResultSet::results_exist
# and its two siblings. This driver overrides nothing: core's base rendering,
# SELECT CASE WHEN EXISTS (<inner>) THEN 1 ELSE 0 END, is already the spelling
# SQLite wants. Only the engines that refuse a FROM-less SELECT have to override
# _exists_value_sql and append their dummy table (Oracle DUAL, DB2
# SYSIBM.SYSDUMMY1, Firebird RDB$DATABASE); SQLite has no such rule.
#
# The flag is still not vacuous here -- it asserts that somebody checked, which
# is why the default is 0 and why declaring it is a separate act from inheriting
# the hook.
#
# Ungated on purpose, unlike the two capabilities above. CASE arrived in
# libsqlite 2.4.4 (2002-03-30) and the EXISTS operator in 3.1.0 (2005-01-21),
# while DBD::SQLite refuses to build against an external libsqlite below 3.6.0
# at all -- so there is no reachable build where a version test could answer
# anything but yes, and a gate that cannot fail only hides what it was for.
# 3.014 and 3.035 above are real thresholds; this one would be decoration.
#
# DECLARED IN THE _determine_ SLOT, NOT AS __PACKAGE__->_use_supports_exists_query(1)
# (karr k27). ADR 0037 section 2 names the _use_ form and the other drivers took
# it, so the deviation is recorded here rather than left to be re-discovered.
# Core's own contract POD blesses both -- "register their engine value via
# __PACKAGE__->_use_X(0|1) OR by defining _determine_supports_X"
# (DBIO::Storage::DBI::Capabilities) -- and since core k137 / ADR 0041 they are
# interchangeable in every way this driver's suite exercises.
#
# The reason for the deviation originally recorded here is refuted there. It
# claimed a class-level _use_ declaration shares the tier-1 FORCE slot with a
# caller's instance-level force, so $storage->_use_X(0) followed by
# $storage->_use_X(undef) leaves the capability off for the life of the storage,
# the undef falling through to core's default 0. Neither half holds.
# Class::Accessor::Grouped::set_inherited writes two physically different places
# depending on the invocant -- the instance hash for a storage, the
# $Class::__cag_<field> package variable for a class -- so the class-level
# declaration was never overwritten by any force; measured directly, the package
# variable held 1 throughout. The 0 the old measurement saw was a get_inherited
# defect one level down: it reads an instance with exists(), not defined(), so
# the force's own undef left a tombstone in the instance slot that shadowed the
# declaration. undef was not a clear. Core fixed that in set_use_dbms_capability,
# which deletes the slot on undef (commit 3a440360f); both declaration forms now
# measure 1 / 0 / 1, and t/23-results-exist.t's force-and-clear round-trip works
# in either form. ADR 0037 section 2 stands as written.
#
# What still differs is get_dbms_capability('_supports_supports_exists_query')
# versus _use_supports_exists_query. With the declaration in tier 3 both answer
# the same 1; the class-level _use_ form leaves the former answering core's
# default 0 on a storage that does support the query. Core verified that no
# consumer reads _supports_X for a decision -- they all read _use_X, which the
# POD documents as the read accessor -- so this is consistency, not correctness.
#
# What the class-level _use_ form buys instead is a class-method answer
# (DBIO::SQLite::Storage->_use_supports_exists_query), which the determine form
# cannot give -- get_dbms_capability throws on a class invocant by design (core
# k119). Nothing in core asks the class; ResultSet::results_exist probes
# the instance.
#
# This is the same choice as supports_upsert_where above. The general question
# the deviation once raised -- which tier is THE declaration form -- is settled:
# ADR 0041 made the two equivalent, so keeping this declaration where it is
# costs nothing and aligning it to ADR 0037's named form would buy nothing. The
# deviation stands as a record, not a disagreement.
sub _determine_supports_supports_exists_query { 1 }

# ADR 0039 -- the one seam for all six set operations, which replaced the
# single-operation _except_operator of ADR 0037 section 3. Two of the six have
# no spelling on this engine at all, so this hook's other job applies: refuse.
#
# SQLite's compound operators are UNION, UNION ALL, INTERSECT and EXCEPT --
# ALL attaches to UNION alone (sqlite.org/lang_select.html, "Compound Select
# Statements", and the compound-operator syntax diagram). Unconditionally so:
# the four arrived together on 2000-06-06, before version 1.0, and the set has
# never grown -- the changelog through 3.53.4 has no INTERSECT ALL and no
# EXCEPT ALL entry. So unlike Oracle (MINUS ALL in 21c) or MySQL (EXCEPT in
# 8.0.31), there is no version boundary here that ADR 0039 section 7's
# "refuse unconditionally and pay for it on the versions that do have it"
# trade would be paying for. Nothing is withheld from anybody.
#
# The four operations SQLite does have are NOT re-spelled: they go to
# next::method and come back with core's base ANSI keyword, which is what this
# engine speaks.
sub _set_operation_keyword {
  my ($self, $op) = @_;

  if (defined $op and ($op eq 'intersect_all' or $op eq 'except_all')) {
    (my $keyword = uc $op) =~ s/_/ /;
    my $nearest = $op eq 'except_all' ? 'except' : 'intersect';

    $self->throw_exception(
      "SQLite has no $keyword operator, so \$rs->$op cannot be rendered on "
    . 'this engine. Its compound operators are UNION, UNION ALL, INTERSECT '
    . 'and EXCEPT -- ALL attaches to UNION alone. That has been true of every '
    . 'SQLite there is: the four arrived together in 2000, before version '
    . '1.0, and none has been added since, so this refusal is unconditional '
    . 'rather than version-gated and withholds nothing from a newer '
    . "libsqlite. \$rs->$nearest is the nearest operation this engine does "
    . 'have, but it is not a drop-in -- it removes duplicate rows, which is '
    . "exactly what $keyword is asked for, so that substitution is yours to "
    . 'make deliberately and not this driver\'s to make silently.'
    );
  }

  return $self->next::method($op);
}

# ADR 0040 / karr k23 -- the WHOLE operation of obtaining a query plan, the hook
# that replaced the string-valued _explain_sql. This driver has to override it,
# and of the whole family it was the most urgent to: SQLite is the one engine
# here on which core's inherited default does not fail loudly.
#
# A bare EXPLAIN is ACCEPTED by SQLite. It answers with the VDBE bytecode of the
# compiled statement -- addr/opcode/p1..p5/comment, one row per virtual machine
# instruction -- which is a perfectly well-formed arrayref of row arrayrefs and
# therefore indistinguishable, to the caller of DBIO::ResultSet::explain, from
# the plan that was asked for. No exception, no empty result, no clue: the wrong
# question, confidently answered. Every other engine that needed this rollout
# either speaks EXPLAIN or refuses it where somebody notices.
#
# The plan lives behind EXPLAIN QUERY PLAN (sqlite.org/eqp.html), whose rows are
# id/parent/notused/detail and whose detail column carries the SCAN / SEARCH ...
# USING INDEX text that is the entire reason to call explain -- "most
# significantly, EXPLAIN QUERY PLAN reports on the way in which the query uses
# database indices". The bytecode dump does not contain that answer in any form
# a caller can read: it does not name the index at all. t/25-explain-query-plan.t
# pins both halves against the engine.
#
# All four assumptions ADR 0040 found baked into the old string shape do hold
# here -- one statement, executed, returning rows, and those rows are the plan --
# so unlike Oracle, DB2, SQL Server and Firebird this override is core's base
# implementation with three words changed, and it stays that shape on purpose
# rather than composing anything of its own.
#
# The statement still goes through _execute_rendered. That is the contract's hard
# rule and it has no engine-named exceptions: it keeps _query_start / _query_end
# tracing and therefore redact_bind_value (ADR 0025) over what are the user's own
# WHERE-clause values, dbh_do retry over a dropped connection, NoBindVars
# interpolation, and -- on a DBIO::Replicated::Storage -- the read handler rather
# than the master's handle. Those four are exactly what core k112 restored by
# routing explain through the storage in the first place, and reaching for
# $self->dbh here would hand every one of them back.
sub _explain_query {
  my ($self, $sql, $bind) = @_;

  my (undef, $sth) = $self->_execute_rendered("EXPLAIN QUERY PLAN $sql", $bind);

  return $sth->fetchall_arrayref;
}

sub backup {
  my ($self, $dir) = @_;
  $dir //= './';

  ## Where is the db file?
  my $dsn = $self->_dbi_connect_info()->[0];

  my $dbname = $1 if($dsn =~ /dbname=([^;]+)/);
  if(!$dbname)
  {
    $dbname = $1 if($dsn =~ /^dbi:SQLite:(.+)$/i);
  }
  $self->throw_exception("Cannot determine name of SQLite db file")
    if(!$dbname || !-f $dbname);

  my $file = File::Basename::basename($dbname);
  $file = POSIX::strftime("%Y-%m-%d-%H_%M_%S", localtime()) . $file;
  $file = "B$file" while(-f $file);

  mkpath($dir) unless -d $dir;
  my $backupfile = file_path($dir, $file);

  my $res = File::Copy::copy($dbname, $backupfile);
  $self->throw_exception("Backup failed! ($!)") if(!$res);

  return $backupfile;
}


sub vacuum {
  my ($self, $into) = @_;

  return $self->_do_query('VACUUM')
    unless defined $into;

  # The target filename MUST go as a bind parameter, so the emitted SQL is
  # "VACUUM INTO ?" -- never interpolated into the statement text.
  return $self->_do_query([ 'VACUUM INTO ?', undef, $into ]);
}


sub _exec_svp_begin {
  my ($self, $name) = @_;

  $self->_dbh->do("SAVEPOINT $name");
}

sub _exec_svp_release {
  my ($self, $name) = @_;

  $self->_dbh->do("RELEASE SAVEPOINT $name");
}

sub _exec_svp_rollback {
  my ($self, $name) = @_;

  $self->_dbh->do("ROLLBACK TO SAVEPOINT $name");

  # resync state for older DBD::SQLite (RT#67843)
  # https://github.com/DBD-SQLite/DBD-SQLite/commit/9b3cdbf
  if (
    ! modver_gt_or_eq('DBD::SQLite', '1.33')
      and
    $self->_dbh->FETCH('AutoCommit')
  ) {
    $self->_dbh->STORE('AutoCommit', 0);
    $self->_dbh->STORE('BegunWork', 1);
  }
}

sub _ping {
  my $self = shift;

  # Be extremely careful what we do here. SQLite is notoriously bad at
  # synchronizing its internal transaction state with {AutoCommit}
  # https://metacpan.org/source/ADAMK/DBD-SQLite-1.37/lib/DBD/SQLite.pm#L921
  # There is a function http://www.sqlite.org/c3ref/get_autocommit.html
  # but DBD::SQLite does not expose it (nor does it seem to properly use it)

  # Therefore only execute a "ping" when we have no other choice *AND*
  # scrutinize the thrown exceptions to make sure we are where we think we are
  my $dbh = $self->_dbh or return undef;
  return undef unless $dbh->FETCH('Active');
  return undef unless $dbh->ping;

  my $ping_fail;

  # older DBD::SQLite does not properly synchronize commit state between
  # the libsqlite and the $dbh
  unless (defined $DBD::SQLite::__DBIO_TXN_SYNC_SANE__) {
    $DBD::SQLite::__DBIO_TXN_SYNC_SANE__ = modver_gt_or_eq('DBD::SQLite', '1.38_02');
  }

  # fallback to travesty
  unless ($DBD::SQLite::__DBIO_TXN_SYNC_SANE__) {
    # since we do not have access to sqlite3_get_autocommit(), do a trick
    # to attempt to *safely* determine what state are we *actually* in.
    # FIXME
    # also using T::T here leads to bizarre leaks - will figure it out later
    my $really_not_in_txn = do {
      local $@;

      # older versions of DBD::SQLite do not properly detect multiline BEGIN/COMMIT
      # statements to adjust their {AutoCommit} state. Hence use such a statement
      # pair here as well, in order to escape from poking {AutoCommit} needlessly
      # https://rt.cpan.org/Public/Bug/Display.html?id=80087
      eval {
        # will fail instantly if already in a txn
        $dbh->do("-- multiline\nBEGIN");
        $dbh->do("-- multiline\nCOMMIT");
        1;
      } or do {
        ($@ =~ /transaction within a transaction/)
          ? 0
          : undef
        ;
      };
    };

    # if we were unable to determine this - we may very well be dead
    if (not defined $really_not_in_txn) {
      $ping_fail = 1;
    }
    # check the AC sync-state
    elsif ($really_not_in_txn xor $dbh->{AutoCommit}) {
      carp_unique (sprintf
        'Internal transaction state of handle %s (apparently %s a transaction) does not seem to '
      . 'match its AutoCommit attribute setting of %s - this is an indication of a '
      . 'potentially serious bug in your transaction handling logic',
        $dbh,
        $really_not_in_txn ? 'NOT in' : 'in',
        $dbh->{AutoCommit} ? 'TRUE' : 'FALSE',
      );

      # it is too dangerous to execute anything else in this state
      # assume everything works (safer - worst case scenario next statement throws)
      return 1;
    }
  }

  # do the actual test and return on no failure
  ( $ping_fail ||= ! try { $dbh->do('SELECT * FROM sqlite_master LIMIT 1'); 1 } )
    or return 1; # the actual RV of _ping()

  # ping failed (or so it seems) - need to do some cleanup
  # it is possible to have a proper "connection", and have "ping" return
  # false anyway (e.g. corrupted file). In such cases DBD::SQLite still
  # keeps the actual file handle open. We don't really want this to happen,
  # so force-close the handle via DBI itself
  #
  local $@; # so that we do not clobber the real error as set above
  eval { $dbh->disconnect }; # if it fails - it fails
  undef; # the actual RV of _ping()
}

sub bind_attribute_by_data_type {

  # According to http://www.sqlite.org/datatype3.html#storageclasses
  # all numeric types are dynamically allocated up to 8 bytes per
  # individual value
  # Thus it should be safe and non-wasteful to bind everything as
  # SQL_BIGINT and have SQLite deal with storage/comparisons however
  # it deems correct
  $_[1] =~ /^ (?: int(?:[1248]|eger)? | (?:tiny|small|medium|big)int ) $/ix
    ? DBI::SQL_BIGINT()
    : undef
  ;
}


# The bind attributes of a statement as one string: empty when none of the
# placeholders is typed. See _prepare_sth.
my $bind_types_key = sub {
  my $attrs = $_[0] or return '';

  return '' unless grep { defined } @$attrs;

  return join ',', map {
    my $attr = $_;
    ! defined $attr ? ''
    : ref $attr eq 'HASH' ? join(';', map { "$_=" . ($attr->{$_} // '') } sort keys %$attr)
    : "$attr"
  } @$attrs;
};

# FIXME - what the flying fuck... work around RT#76395
# DBD::SQLite warns on binding >32 bit values with 32 bit IVs
sub _dbh_execute {
  my $self = $_[0];

  # see _prepare_sth: the statement this execute prepares is the one for
  # these bind types
  local $self->{_sth_bind_types} = $bind_types_key->($_[4]);

  if (
    (
      iv_size < 8
        or
      os_name eq 'MSWin32'
    )
      and
    ! defined $DBD::SQLite::__DBIO_CHECK_dbd_mishandles_bound_BIGINT
  ) {
    $DBD::SQLite::__DBIO_CHECK_dbd_mishandles_bound_BIGINT = (
      modver_gt_or_eq('DBD::SQLite', '1.37')
    ) ? 1 : 0;
  }

  local $SIG{__WARN__} = sigwarn_silencer( qr/
    \Qdatatype mismatch: bind\E \s (?:
      param \s+ \( \d+ \) \s+ [-+]? \d+ (?: \. 0*)? \Q as integer\E
        |
      \d+ \s type \s @{[ DBI::SQL_BIGINT() ]} \s as \s [-+]? \d+ (?: \. 0*)?
    )
  /x ) if (
    (
      iv_size < 8
        or
      os_name eq 'MSWin32'
    )
      and
    $DBD::SQLite::__DBIO_CHECK_dbd_mishandles_bound_BIGINT
  );

  $self->next::method(@_[1 .. $#_]);
}

sub _dbh_prepare {
  my $self = $_[0];

  local $self->{_sth_bind_types} = $bind_types_key->($_[4]);

  $self->next::method(@_[1 .. $#_]);
}

# Statements are cached by their SQL text alone (DBI's prepare_cached), and
# DBD::SQLite keeps the type a placeholder was last bound with until another
# one is given -- sqlite_bind_ph stores a type only when there is one, and no
# type code puts a placeholder back to "untyped". So a bind without an
# attribute does not get the DBD default (TEXT, or a guess under
# sqlite_see_if_its_a_number), it gets what the previous call that shared the
# SQL text bound there: '01234' goes out as INTEGER 1234 after a literal 99999
# ran through the same statement (karr k61).
#
# A cached handle is therefore shared only between calls that bind the same
# types: the types go into the cache key, as a private attribute of
# prepare_cached, which DBI folds into the key and DBD::SQLite ignores. A
# call without any bind attribute keeps the plain key, so that handle is one
# that no placeholder was ever typed on.
sub _prepare_sth {
  my ($self, $dbh, $sql) = @_;

  my $types = $self->{_sth_bind_types};

  if (defined $types and length $types and ! $self->disable_sth_caching) {
    # 3 is the if_active parameter which avoids active sth re-use
    my $sth = $dbh->prepare_cached($sql, { private_dbio_bind_types => $types }, 3);
    return $sth if $sth;
    # failed: the base class prepares again and reports it
  }

  return $self->next::method($dbh, $sql);
}

# populate: the base class prepares the statement before it knows the bind
# attributes (they come with the proto-bind, handed to this method), then
# binds the proto-bind once and lets execute_for_fetch inherit the types from
# the handle. Swap in the handle for these types before that happens.
#
# The swap is assigned to $_[2] on purpose: that is the caller's own $sth, so
# _insert_bulk hands back the handle that ran, not the one it prepared.
sub _dbh_execute_for_fetch {
  my ($self, $source, $sth, $proto_bind) = @_[0..3];

  my $types = $bind_types_key->($self->_dbi_attrs_for_bind($source, $proto_bind));

  if (length $types and ! $self->disable_sth_caching) {
    local $self->{_sth_bind_types} = $types;
    $_[2] = $self->_prepare_sth($sth->{Database}, $sth->{Statement});
  }

  $self->next::method(@_[1 .. $#_]);
}

# True for a plain scalar holding an integer in canonical decimal spelling
# that fits SQLite's 64 bit INTEGER: no leading zero, no plus sign, no
# whitespace, no '-0', no fraction or exponent. Only such a value survives
# being bound as an integer unchanged -- SQLite renders it back to exactly
# the string it was given.
my $is_canonical_integer = sub {
  return 0 if ref $_[0];

  my ($sign, $digits) = $_[0] =~ /\A (-?) ( 0 | [1-9][0-9]{0,18} ) \z/x
    or return 0;

  return 0 if $sign and $digits eq '0';

  return 1 if length $digits < 19;

  return $digits le ( $sign ? '9223372036854775808' : '9223372036854775807' )
    ? 1
    : 0;
};

# DBD::SQLite before 1.37 can not bind an integer occupying more than 32
# bits. True when this DBD::SQLite is such a one and the value of the bind is
# such an integer: the caller then binds it as a string, and the warning
# raised here says so. Hand it a value that is known to be an integer.
my $warn_integer_too_wide_for_dbd = sub {
  my ($bind, $i) = @_;

  return 0 if $DBD::SQLite::__DBIO_CHECK_dbd_can_bind_bigint_values;

  return 0 unless $bind->[1] > 0x7fff_ffff or $bind->[1] < -0x8000_0000;

  carp_unique( sprintf (
    "An integer value occupying more than 32 bits was supplied for column '%s' "
  . 'which your version of DBD::SQLite (%s) can not bind properly so DBIO '
  . 'will treat it as a string instead, consider upgrading to at least '
  . 'DBD::SQLite version 1.37',
    $bind->[0]{dbic_colname} || "# $i",
    DBD::SQLite->VERSION,
  ) );

  return 1;
};

# DBD::SQLite (at least up to version 1.31 has a bug where it will
# non-fatally numify a string value bound as an integer, resulting
# in insertions of '0' into supposed-to-be-numeric fields
# Since this can result in severe data inconsistency, remove the
# bind attr if such a situation is detected
#
# FIXME - when a DBD::SQLite version is released that eventually fixes
# this situation (somehow) - no-op this override once a proper DBD
# version is detected
sub _dbi_attrs_for_bind {
  my ($self, $ident, $bind) = @_;

  my $bindattrs = $self->next::method($ident, $bind);

  if (! defined $DBD::SQLite::__DBIO_CHECK_dbd_can_bind_bigint_values) {
    $DBD::SQLite::__DBIO_CHECK_dbd_can_bind_bigint_values
      = modver_gt_or_eq('DBD::SQLite', '1.37') ? 1 : 0;
  }

  for my $i (0.. $#$bindattrs) {

    if (defined $bindattrs->[$i]) {
      # Validate existing integer bind attributes
      if (
        defined $bind->[$i][1]
          and
        grep { $bindattrs->[$i] eq $_ } (
          DBI::SQL_INTEGER(), DBI::SQL_TINYINT(), DBI::SQL_SMALLINT(), DBI::SQL_BIGINT()
        )
      ) {
        if ( $bind->[$i][1] !~ /^ [\+\-]? [0-9]+ (?: \. 0* )? $/x ) {
          carp_unique( sprintf (
            "Non-integer value supplied for column '%s' despite the integer datatype",
            $bind->[$i][0]{dbic_colname} || "# $i"
          ) );
          undef $bindattrs->[$i];
        }
        elsif (
          ! $DBD::SQLite::__DBIO_CHECK_dbd_can_bind_bigint_values
        ) {
          if ( $warn_integer_too_wide_for_dbd->($bind->[$i], $i) ) {
            undef $bindattrs->[$i];
          }
          else {
            $bindattrs->[$i] = DBI::SQL_INTEGER()
          }
        }
      }
    }
    elsif (
      # SQLite binds all parameters as TEXT by default (sqlite3_bind_text).
      # This causes cross-type comparison failures: INTEGER < TEXT is always
      # true in SQLite's type sort order, so e.g. COUNT(x) > ? with a text
      # bind always returns FALSE. Fix by hinting integer values as SQL_INTEGER
      # when no type info is available.
      #
      # Apply to:
      # - Anonymous binds (no dbic_colname) from literal SQL
      # - Expression binds (colname contains parens, e.g. 'COUNT(x)')
      # Do NOT apply to plain column aliases (e.g. 'newest_cd_year') as
      # these may reference TEXT-typed columns containing numeric strings.
      # Do NOT touch a bind carrying dbd_attrs, even an undef one: the caller
      # took the binding over.
      defined $bind->[$i][1]
        and
      ! exists $bind->[$i][0]{dbd_attrs}
        and
      (
        ! $bind->[$i][0]{dbic_colname}
          or
        $bind->[$i][0]{dbic_colname} =~ /\(/  # expression (COUNT, MAX, etc.)
      )
    ) {
      # SQL_INTEGER ONLY for a value that is certainly a number: an integer
      # in canonical spelling, see $is_canonical_integer, on a bind that
      # states no datatype of its own. Whatever merely looks like a number
      # ('01234', '+5', ' 5') would reach SQLite respelled and silently stop
      # matching the TEXT it is compared with. A non-integer is not hinted
      # either: as SQL_INTEGER DBD::SQLite rejects it with a 'datatype
      # mismatch' warning and binds TEXT anyway, and as a REAL it would be
      # respelled just the same ('1.50', '1e3').
      #
      # Everything else is stated as text rather than left without an
      # attribute. Stating it is a decision, not a safeguard against
      # inheritance: a cached statement is no longer shared with calls that
      # bind other types (see _prepare_sth), so an attribute-less bind would
      # get what DBD::SQLite does by default. That default is text, but it
      # turns into a guess under sqlite_see_if_its_a_number, which an explicit
      # type switches off for these binds (karr k62).
      #
      # An integer this DBD::SQLite can not bind as one is text as well, with
      # a warning (karr k63). That question comes last: it is asked only of a
      # value that would have gone out as an integer.
      $bindattrs->[$i] = (
        ! $bind->[$i][0]{sqlt_datatype}
          and
        $is_canonical_integer->($bind->[$i][1])
          and
        ! $warn_integer_too_wide_for_dbd->($bind->[$i], $i)
      ) ? DBI::SQL_INTEGER() : DBI::SQL_VARCHAR();
    }

  }

  return $bindattrs;
}

sub with_deferred_fk_checks {
  my ($self, $sub) = @_;

  my $txn_scope_guard = $self->txn_scope_guard;

  $self->_do_query('PRAGMA defer_foreign_keys = ON');

  return preserve_context { $sub->() } after => sub { $txn_scope_guard->commit };
}


sub connect_call_use_foreign_keys {
  my $self = shift;

  $self->_do_query(
    'PRAGMA foreign_keys = ON'
  );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Storage - SQLite storage driver for DBIO

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

SQLite storage driver for DBIO. Extends L<DBIO::Storage::DBI> with
SQLite-specific behavior including C<INSERT ... RETURNING> for single
round-trip retrieval of autoincrement and C<retrieve_on_insert> values
(libsqlite 3.35+), the atomic upsert of L<DBIO::ResultSet/upsert> via
C<INSERT ... ON CONFLICT> (also gated at libsqlite 3.35+, see below), the
boolean-valued existence check behind L<DBIO::ResultSet/results_exist>,
savepoint support, foreign key pragma helpers, database file backup, and
workarounds for known L<DBD::SQLite> bugs.

=head2 Atomic upsert

C<supports_upsert> is declared exactly when C<insert_returning> is in effect.
SQLite has had the C<ON CONFLICT> grammar since libsqlite 3.24, but core names
the written row through C<last_insert_id> plus a C<SELECT> on the primary key
and never re-finds it by conflict target. An upsert that takes the
C<DO UPDATE> branch inserts nothing, so C<last_insert_rowid()> still reports
the previous insert -- without C<RETURNING> the call would hand back an
unrelated row. Gating the two capabilities together makes the returned row
correct by construction; on libsqlite 3.24 - 3.34 C<upsert> throws instead
(ADR 0036).

C<supports_upsert_where> -- the conditional branch,
C<DO UPDATE SET ... WHERE ...>, reachable as C<upsert>'s C<update_where> -- is
declared unconditionally instead. It is a fact about
L<DBIO::SQLite::SQLMaker>, not about the server: the C<WHERE> arrived with the
C<ON CONFLICT> grammar itself in 3.24, so there is no version to test, and the
RETURNING coupling above is about naming the written row, which a condition
that does not hold has no need of -- it writes nothing, and C<upsert> hands
back C<undef> (which is why core refuses C<< result => 'row_or_die' >>
together with C<update_where>). Core consults the two capabilities together.

=head2 Existence queries

C<supports_exists_query> is declared unconditionally, which is what makes
L<DBIO::ResultSet/results_exist>, L<DBIO::ResultSet/results_exist_async> and
L<DBIO::ResultSet/results_exist_as_query> work here instead of throwing (ADR
0037). This driver does not override
L<DBIO::Storage::DBI/_exists_value_sql>: core's base rendering,
C<SELECT CASE WHEN EXISTS E<lt>innerE<gt> THEN 1 ELSE 0 END>, is already the
spelling SQLite wants -- only the engines that refuse a C<FROM>-less C<SELECT>
have to append a dummy table.

No version gate, unlike the two capabilities above: C<CASE> arrived in
libsqlite 2.4.4 and the C<EXISTS> operator in 3.1.0, both below the 3.6.0 an
external libsqlite needs before L<DBD::SQLite> will build against it at all.
L<DBIO::ResultSet/has_rows> stays the portable alternative for callers that
must run against a driver which has not declared the capability.

=head2 Set operations

SQLite has B<four> compound operators and only four -- C<UNION>,
C<UNION ALL>, C<INTERSECT> and C<EXCEPT>: C<ALL> attaches to C<UNION> alone
(L<https://www.sqlite.org/lang_select.html>, "Compound Select Statements").
So four of L<DBIO::ResultSet>'s six set operations work here on core's base
spelling, and the remaining two, C<intersect_all> and C<except_all>, have no
spelling at all. This driver's L<DBIO::Storage::DBI/_set_operation_keyword>
override B<refuses> those two with a typed exception at query-build time,
rather than letting core's inherited C<INTERSECT ALL> / C<EXCEPT ALL> reach
the engine as a syntax error several layers below the method the caller
called (ADR 0039). C<except> is B<not> re-spelled: it is handed to
C<< $self->next::method >> and comes back C<EXCEPT>, core's base answer, as
do the other three.

The refusal is B<unconditional>, and that is a sourced engine fact rather
than the compromise ADR 0039 section 7 prices for the drivers whose gap is
version-bounded (Oracle gained C<MINUS ALL> in 21c). SQLite's four compound
operators arrived together on 2000-06-06, before version 1.0, and the set has
never grown: the changelog through 3.53.4 contains no C<INTERSECT ALL> and no
C<EXCEPT ALL>. There is thus no libsqlite on which the refusal withholds an
operation the engine would have accepted, and nothing here that a version
probe could have answered better -- which matters, because the hook is a
static class fact and may not open a connection to decide.

C<except> and C<intersect> are the nearest operations SQLite does have, and
the exception names them -- but they are not drop-in replacements: both
remove duplicate rows, which is precisely what the C<... ALL> variant is
asked for. Choosing one is the caller's decision, which is why this driver
throws instead of quietly substituting (ADR 0039 section 3).

This class is registered as the driver for C<SQLite> and is loaded
automatically when connecting to a SQLite DSN. It uses
L<DBIO::SQLite::SQLMaker> for SQL generation, C<LimitOffset> pagination,
double-quote identifiers, and L<DateTime::Format::SQLite> for datetime
parsing.

=head2 Query plans

L<DBIO::ResultSet/explain> asks the storage for the whole operation of
obtaining a query plan through L<DBIO::Storage::DBI/_explain_query> (ADR 0040;
it replaced the string-valued C<_explain_sql>). This driver B<must> override
it, because SQLite is the only engine in this family where core's inherited
C<EXPLAIN E<lt>queryE<gt>> is neither right nor loud.

SQLite B<accepts> a bare C<EXPLAIN>. What it returns is the VDBE bytecode of
the compiled statement -- C<addr>, C<opcode>, C<p1> .. C<p5>, C<comment>, one
row per virtual machine instruction -- which is a well-formed arrayref of row
arrayrefs and so is indistinguishable, at the call site, from the plan the
caller asked for. There is no exception and no empty result to notice: the
wrong question is answered confidently. The bytecode never names the index the
query uses, which is the one thing C<explain> is called for.

The plan comes from C<EXPLAIN QUERY PLAN>
(L<https://www.sqlite.org/eqp.html>), whose rows are C<id>, C<parent>,
C<notused>, C<detail>, and whose C<detail> carries the C<SCAN> /
C<SEARCH ... USING INDEX> text. Its I<contents> are engine-specific and
deliberately unstable -- SQLite documents the output as interactive debugging
material whose format may change between releases, and it did change
substantially in 3.24.0 -- which is no more than ADR 0040 section 2 already
says about every driver's plan rows.

Beyond the three added words the override is core's base implementation: on
SQLite obtaining a plan really is one statement, executed, returning rows that
are the plan, so nothing of ADR 0040's wider shape is needed here. The
statement goes through L<DBIO::Storage::DBI/_execute_rendered> as the contract
requires, which is what keeps tracing and therefore
L<DBIO::Storage::DBI/redact_bind_value> over the query's own bind values,
C<dbh_do> retry, C<NoBindVars> interpolation, and the read handler on a
L<DBIO::Replicated::Storage>.

=head2 Binds without a column

SQLite compares an INTEGER with a TEXT by storage class, and only a column
(or an expression that carries a column's affinity) converts the bound value
to its own type first. A bind that belongs to no column -- literal SQL such
as C<\[ 'COUNT(x) E<gt> ?', 3 ]> -- has nothing to go by, so the storage
decides from the spelling of the value: an integer in canonical decimal
spelling (C<3>, C<-7>, C<'99999'>; no leading zero, plus sign, whitespace or
fraction, within 64 bits) is bound as INTEGER, anything else as text. That
makes aggregate comparisons with a count work whether the number arrives as a
Perl number or as a string from a request parameter, and keeps a zip code like
C<'01234'> intact.

The decision follows the spelling, not the Perl type of the scalar, and this
leaves two limits, both against an expression that has B<no affinity> and
therefore no conversion of its own:

=over 4

=item * a canonical integer string against a text expression.
C<lower(name) = ?> with C<'99999'> binds an INTEGER, which never equals the text C<'99999'>,
so the row is not found. Against the column itself (C<name = ?>) it works,
the column's TEXT affinity turns the integer back into text.

=item * a non-integer against a numeric expression. C<AVG(x) E<gt> ?> with
C<1.5> binds text, and INTEGER and REAL sort below TEXT, so the comparison is
always false.

=back

SQLite has no type that is right for both C<lower(name) = '99999'> and
C<COUNT(x) E<gt> '3'>; the storage cannot know which one is meant, so it does
not guess further. State the type at the bind, which the storage leaves alone:

  # text: the integer-looking string stays a string
  $rs->search(\[ 'lower(name) = ?', [ { sqlt_datatype => 'varchar' } => '99999' ] ]);

  # real: the number reaches SQLite as a number
  $rs->search(undef, {
    group_by => 'me.artistid',
    having   => \[ 'AVG(me.artistid) > ?', [ { dbd_attrs => DBI::SQL_REAL() } => 1.5 ] ],
  });

=head2 SQL dialect of the DDL

C<_ddl_sql_dialect> answers C<sqlite>. The splitter that cuts install and
upgrade DDL into statements (L<DBIO::Deploy::Base/_execute_ddl>) reads one form
differently per engine, the backslash in a string literal, and SQLite is one
where it is an ordinary character: C<'a\'> is a complete literal. With the
dialect named, a literal that ends on a backslash no longer swallows the cut
behind it and the semicolon of a later literal. See
L<DBIO::Storage::DBI::Capabilities/_ddl_sql_dialect>.

=head1 METHODS

=head2 _extension_activation

    my $activation = $storage->_extension_activation($namespace);
    # { load => [ '/opt/sqlite/vec0.so' ], search_path => [] }

The seam of L<DBIO::Storage::DBI/_extension_activation>: what the declared
extensions (L<DBIO::SQLite/sqlite_extensions>) want of a new connection,
merged by core in the name order of the extensions
(L<DBIO::Extension::Protocol/activation>): the libraries to load. The list is
resolved here, at the first use of a connection and so after the driver is
resolved, never at C<connect>: the classes are loaded, their interface
version and their driver assertion checked
(L<DBIO::SQLite::Extension/resolve_list>). C<undef> -- and nothing else
happens to the connection -- for a schema that declares no extension and for
declared extensions with no library.

=head2 _activate_extensions

    $storage->_activate_extensions($activation);

The seam of L<DBIO::Storage::DBI/_activate_extensions>: C<load_extension>
needs the handle and not a statement. The connection's extension loading is
switched on, every library of the activation is loaded with
C<< $dbh->sqlite_load_extension >> in the order core merged them, and loading
is switched off again, so that nothing on the connection can call SQL
C<load_extension()> afterwards. A library that cannot be loaded dies with a
message naming it, and the handle is dropped from the storage, as core does
with any failing connect action. A connection of an async pool is a statement runner and
has no handle here, so it refuses.

=head2 _dbh_columns_info_for

Override the parent's C<column_info> lookup. DBD::SQLite does not implement
C<NULLABLE> correctly -- columns constrained by C<UNIQUE ... NOT NULL> come
back as nullable. This override layers the truth from C<PRAGMA table_info>
(C<notnull>) on top of the parent method's result so that C<is_nullable> is
correct for downstream consumers like L<DBIO::Storage::DBI/columns_info_for>.

For a C<PRIMARY KEY> column it also asks C<PRAGMA index_list> whether the key
is the rowid alias, because on SQLite that is the only key column which cannot
hold NULL -- see L<DBIO::SQLite::Util/column_is_nullable>, which both this
method and L<DBIO::SQLite::Introspect/table_columns_info> route the decision
through so the live path and the introspect path answer the same for the same
column.

=head2 backup

    my $backupfile = $storage->backup($dir);
    my $backupfile = $storage->backup;          # defaults to './'

Copy the live SQLite database file to C<$dir>. The backup filename includes
a timestamp prefix. Returns the full path to the backup file.

Throws an exception if the database filename cannot be determined from the
DSN or if the file copy fails.

=head2 vacuum

    $storage->vacuum;            # VACUUM
    $storage->vacuum($file);     # VACUUM INTO ?   (bind: $file)

Rebuild the database file, defragmenting it and reclaiming free pages. With no
argument this emits a bare C<VACUUM>. Given a target filename it emits
C<VACUUM INTO ?> (libsqlite 3.27+), writing a fresh, compacted copy of the
database to C<$file> while leaving the live database untouched; the filename is
passed as a bind parameter rather than interpolated into the SQL. The target
file must not already exist.

C<VACUUM> cannot run inside a transaction; call this outside any active
transaction.

=head2 bind_attribute_by_data_type

Returns C<DBI::SQL_BIGINT> for any integer-family column type (C<int>,
C<integer>, C<tinyint>, C<smallint>, C<mediumint>, C<bigint>, C<int1>,
C<int2>, C<int4>, C<int8>). Returns C<undef> for all other types, deferring
to the default binding behavior.

SQLite stores all numeric values as dynamically-sized integers up to 8 bytes,
so binding everything as C<SQL_BIGINT> is safe and avoids unnecessary type
coercions.

=head2 with_deferred_fk_checks

    $storage->with_deferred_fk_checks(sub { ... });

Execute C<$sub> inside a transaction with C<PRAGMA defer_foreign_keys = ON>.
Foreign key constraint checking is deferred until the transaction commits,
allowing bulk inserts or other operations that temporarily violate referential
integrity within the same transaction. The transaction is committed
automatically after C<$sub> returns.

=head2 connect_call_use_foreign_keys

A connect-time callback that executes C<PRAGMA foreign_keys = ON>. SQLite
does not enforce foreign key constraints by default. Enable it by passing
C<on_connect_call =E<gt> 'use_foreign_keys'> in your connection options:

    $schema->connect(
        'dbi:SQLite:db/app.db', '', '',
        { on_connect_call => 'use_foreign_keys' },
    );

=head1 SEE ALSO

=pod

=over

=item * L<DBIO::SQLite> - Schema component that activates this storage

=item * L<DBIO::SQLite::SQLMaker> - SQL generation for SQLite

=item * L<DBIO::Storage::DBI> - Base DBI storage class

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
