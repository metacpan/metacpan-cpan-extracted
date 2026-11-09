package DBIO::MySQL::Storage;
# ABSTRACT: MySQL storage layer for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

use base qw/DBIO::Storage::DBI/;

use DBIO::Carp;
use DBIO::Util qw( is_literal_value );
use DBIO::MySQL::MariaDBForkGuard ();
use DBIO::MySQL::Util ();

__PACKAGE__->register_driver('mysql' => __PACKAGE__);

# Async is an explicit, per-connection mode (core ADR 0030): a connection opened
# with connect(..., { async => 'ev' }) resolves the 'ev' mode through the mode
# registry to the native MySQL EV backend below. Registering on this driver
# storage class MRO-shadows the generic modes (forked/future_io) registered on
# the base storage, so 'ev' picks the MySQL-specific backend. There is no auto-
# fallback and no silent degrade: a mode that is neither requested nor registered
# is simply unavailable, and requesting an unregistered/uninstalled mode croaks
# (see DBIO::Storage::DBI::_async_storage). This only stores the class name --
# DBIO::MySQL::EV::Storage (the optional dbio-mysql-ev dist) is loaded lazily
# on first use, so registering it here is safe when the dist is absent.
__PACKAGE__->register_async_mode( ev => 'DBIO::MySQL::EV::Storage' );

# This is the ONLY async registration this driver needs, and it stays as-is
# under the storage-layer composition model (core karr #70): a mode maps to a
# transport BASE class, once, on this concrete driver storage. This dist writes
# storage_type only from its Schema components' connection() (DBIO::MySQL /
# DBIO::MySQL::MariaDB) -- choosing the driver BASE storage stays the driver's
# job. A driver EXTENSION does not subclass storage_type nor add a shadow
# register_async_mode / ::Async of its own: it registers a plain storage LAYER
# (DBIO::Schema::register_storage_layer) whose async mirror composes ON TOP of
# the resolved transport via DBIO::Storage::Composed. MySQL ships no such
# extension today, but the mechanism is core-provided and this reference driver
# honours it -- composition rides on top of this base; the mode->transport-base
# map does not grow per extension.

sub dbio_deploy_class { 'DBIO::MySQL::Deploy' }

__PACKAGE__->sql_maker_class('DBIO::MySQL::SQLMaker');
__PACKAGE__->sql_quote_char('`');
__PACKAGE__->datetime_parser_type('DateTime::Format::MySQL');

__PACKAGE__->_use_multicolumn_in(1);

# F02 / F10 -- transactional DDL. The capability asks exactly one question: can
# several DDL statements run inside ONE transaction and be taken back by a
# ROLLBACK? On both server products the answer is no, on every version, so this
# is a flat class-level fact and not a version gate like the set operations
# below. Every statement this dist's DDL and diff classes emit -- CREATE TABLE,
# CREATE VIEW, ALTER TABLE (ADD/DROP/MODIFY COLUMN, ADD/DROP FOREIGN KEY),
# CREATE INDEX, DROP INDEX, DROP TABLE -- is on both products' implicit-commit
# list: MySQL Reference Manual 15.3.3, "Statements That Cause an Implicit
# Commit" (https://dev.mysql.com/doc/refman/8.0/en/implicit-commit.html; the
# same section and the same list in 9.7), and MariaDB's "SQL statements Causing
# an Implicit Commit" (https://mariadb.com/docs/server/reference/sql-statements/
# transactions/sql-statements-that-cause-an-implicit-commit), which puts the
# consequence plainly: "All these statements cause an implicit commit before
# execution. This means that, even if the statement fails with an error, the
# transaction is committed. ... Such statements couldn't be rollbacked in any
# case."
#
# THE TRAP THIS COMMENT EXISTS FOR: atomic DDL is not transactional DDL, and
# the version numbers invite the confusion. MySQL 8.0 (Reference Manual 15.1.1,
# "Atomic Data Definition Statement Support",
# https://dev.mysql.com/doc/refman/8.0/en/atomic-ddl.html) and MariaDB 10.6.1
# (MDEV-17567, https://mariadb.com/docs/server/reference/sql-statements/
# data-definition/atomic-ddl) both made a SINGLE DDL statement crash-safe: an
# interrupted CREATE/ALTER/DROP no longer leaves a table without its data
# dictionary entry, an #sql-shadow file or a half-finished multi-table RENAME.
# That is a guarantee about a crash, not about a transaction, and MySQL's own
# manual says so in that very section: "Atomic DDL is not transactional DDL.
# DDL statements, atomic or otherwise, implicitly end any transaction that is
# active in the current session, as if you had done a COMMIT before executing
# the statement. This means that DDL statements cannot be performed within
# another transaction".
#
# So reading the server version and "tidying" the 0 below into a 1 buys nothing
# and costs the only thing that is left. It switches on the bracketed branch of
# DBIO::Deploy::Base::_execute_ddl, which wraps the statement loop in
# $storage->txn_do: the BEGIN goes out first and is committed away by the very
# next CREATE TABLE, so the closing COMMIT commits nothing that was still open
# and a ROLLBACK on failure takes back nothing at all. Statements 1..6 of a
# failing batch of 12 stay applied, exactly as they do today. What does change
# is that core's one-time "non-transactional DDL on ..." notice -- the only
# thing telling an operator that recovery here rests on re-running the upgrade
# against live state rather than on a rollback -- is no longer emitted. The
# warning goes quiet; the non-atomicity stays. Same reasoning applies to
# DBIO::DeploymentHandler, which reads this capability to decide whether a
# whole upgrade can run atomically, and to DBIO::Storage::Async, which declares
# nothing of its own and delegates the question to this class.
#
# Declared in tier 2 (__PACKAGE__->_use_X), NOT in tier 3 like the set-
# operation flags below, and the reason that drives those flags does not
# carry: core names this exact case -- "this engine commits DDL implicitly" --
# as its tier-2 example (DBIO::Storage::DBI::Capabilities, "Which tier a
# driver writes to"), and unlike the set operations this answer is the
# RESTRICTIVE one and identical to core's default, so losing it could at
# worst land on the same 0. Tier 2 is also what makes the declaration
# readable as a class method, which is the only way to tell a declared 0 from
# an inherited one -- t/58-deploy-transactional-ddl.t pins both.
#
# On the shared class, since which commit semantics DDL carries is a fact about
# the SERVER and not about the DBD; DBIO::MySQL::Storage::MariaDB is the
# DBD::MariaDB binding and inherits this rather than repeating it (karr k28,
# this dist's ADR 0001).
__PACKAGE__->_use_transactional_ddl(0);

# ADR 0036: INSERT ... ON DUPLICATE KEY UPDATE has been in MySQL since 4.1 and
# in every MariaDB, so the capability is a flat class-level fact rather than a
# version gate. The ADR's hard precondition for declaring it -- "only if the
# identity handed back is provably the row that was written" -- is what
# L</insert> and L</_mysql_upsert_plan> below exist for: on the table shapes
# where this engine cannot name the written row, the primary key is withheld
# so core returns undef (or throws for result => 'row_or_die') instead of
# confidently handing back an unrelated row.
__PACKAGE__->_use_supports_upsert(1);

# ADR 0037: results_exist and its two siblings are gated on this, and the gate
# means "somebody checked", not merely "the hook was overridden". It was
# checked: the base _exists_value_sql rendering is accepted by both server
# products this dist serves, so the hook is deliberately NOT overridden here.
# See the "The base EXISTS rendering is right for both server products"
# section below for what was checked and against what.
__PACKAGE__->_use_supports_exists_query(1);

# ADR 0039 section 7 -- which set operations the server at the other end has.
# Two facts, because the two products drew two different lines and one boolean
# cannot express a MariaDB 10.3/10.4, which has INTERSECT and EXCEPT but not
# their ALL forms. Both default to AVAILABLE: every non-EOL release of either
# product has all six, so a gate defaulting to 0 would refuse an operation that
# works on essentially the entire installed base. A deployment pinned to an
# older server turns the relevant one off and trades a syntax error from the
# server for a local exception naming the boundary -- see the "Set operations"
# section below and _set_operation_keyword.
#
# Declared as _determine_supports_*, NOT as __PACKAGE__->_use_*(1). _use_X is
# the CALLER's force slot, and this driver declares the PERMISSIVE answer to
# both set-operator capabilities -- INTERSECT/EXCEPT and their ALL forms are
# present on every supported release of either product, while core's default
# is the restrictive 0. The determination tier is where a permissive answer
# survives contact with a caller: it is the structural fallback, so a caller
# who forces a capability off and later clears the force (_use_X(undef))
# always lands back on the driver's 1, never on core's 0. Had the declaration
# sat in the force slot, an unclearable force would have silently turned four
# working operations off for the life of the storage. Both tiers are pinned
# static rather than version-probing, which is the whole constraint of ADR 0039
# section 7 and is nailed shut at the spot where a future author would reach
# for _server_info.
__PACKAGE__->mk_group_accessors( dbms_capability     => '_supports_set_operator_intersect_except' );
__PACKAGE__->mk_group_accessors( use_dbms_capability => '_use_set_operator_intersect_except' );
sub _determine_supports_set_operator_intersect_except { 1 }

__PACKAGE__->mk_group_accessors( dbms_capability     => '_supports_set_operator_all_family' );
__PACKAGE__->mk_group_accessors( use_dbms_capability => '_use_set_operator_all_family' );
sub _determine_supports_set_operator_all_family { 1 }


# ADR 0039 -- the keyword the six DBIO::ResultSet set operations join their
# operands with, and the seam that refuses the four neither product always had.
# Purely a refusal seam here: both MySQL and MariaDB use the ANSI spelling for
# every operation they have, so every path below ends in next::method.
#
# Deliberately a static class fact with no version probe. ResultSet's
# _set_operation bakes the keyword into a literal from clause at construction
# time, so a runtime-resolved keyword is not expressible at all -- and asking
# the server which product and version it is would open a connection during
# query build, purely in order to throw (ADR 0039 section 7). The two
# capabilities declared at the top of this class are what a deployment answers
# with instead; see the "Set operations" POD section for the version table.
sub _set_operation_keyword {
  my ($self, $op) = @_;

  # An undefined $op is core's programming error, and core's throw is the one
  # that names it. Guard first so we do not warn on the eq below on the way
  # there (the shape core's own POD example carries).
  return $self->next::method($op) unless defined $op;

  # UNION and UNION ALL predate anything this driver can meet on either
  # product. Only the other four have a boundary, so only they are asked about.
  if (   $op eq 'except'     or $op eq 'intersect'
      or $op eq 'except_all' or $op eq 'intersect_all') {

    # The outer boundary first: without INTERSECT/EXCEPT at all there is no
    # ALL form of them either, so this check subsumes the one below and a
    # deployment that only turned off the outer switch still gets a coherent
    # answer for all four.
    $self->throw_exception(
      "This server has no INTERSECT / EXCEPT, so this driver refuses "
    . "\$rs->$op. MySQL gained both in 8.0.31 (Reference Manual 15.2.4 and "
    . "15.2.8, WL #349) and MariaDB in 10.3 (MDEV-10141); this deployment has "
    . "declared its server older than that with "
    . "DBIO::MySQL::Storage->_use_set_operator_intersect_except(0). "
    . "_set_operation_keyword must answer as a static class fact -- "
    . "DBIO::ResultSet::_set_operation bakes the keyword into the query while "
    . "it is being built -- so this driver cannot check the server version "
    . "here, and the declaration is the only thing it can read (ADR 0039 "
    . "section 7). Pass (1) to undo it, or use \$rs->union / \$rs->union_all, "
    . "which every version of both products has."
    ) unless $self->_use_set_operator_intersect_except;

    $self->throw_exception(
      "This server has no INTERSECT ALL / EXCEPT ALL, so this driver refuses "
    . "\$rs->$op -- \$rs->" . ($op eq 'except_all' ? 'except' : 'intersect')
    . " is unaffected, but it is a different operation, not a fallback: it "
    . "collapses duplicates. MySQL got the ALL forms together with the "
    . "DISTINCT ones in 8.0.31 (WL #349), MariaDB only two releases later in "
    . "10.5.0 (MDEV-18844), having had the DISTINCT forms since 10.3; this "
    . "deployment has declared its server inside that gap with "
    . "DBIO::MySQL::Storage->_use_set_operator_all_family(0). "
    . "_set_operation_keyword must answer as a static class fact and cannot "
    . "check the server version here (ADR 0039 section 7), so the declaration "
    . "is the only thing it can read. Pass (1) to undo it."
    ) if ( $op eq 'except_all' or $op eq 'intersect_all' )
     and ! $self->_use_set_operator_all_family;
  }

  # Both products spell all six the ANSI way, so the base map answers every
  # operation this class did not refuse -- and an unknown $op lands on core's
  # throw there rather than being invented here.
  return $self->next::method($op);
}

sub with_deferred_fk_checks {
  my ($self, $sub) = @_;

  $self->_do_query('SET FOREIGN_KEY_CHECKS = 0');
  $sub->();
  $self->_do_query('SET FOREIGN_KEY_CHECKS = 1');
}


sub connect_call_set_strict_mode {
  my $self = shift;

  # the @@sql_mode puts back what was previously set on the session handle
  $self->_do_query(q|SET SQL_MODE = CONCAT('ANSI,TRADITIONAL,ONLY_FULL_GROUP_BY,', @@sql_mode)|);
  $self->_do_query(q|SET SQL_AUTO_IS_NULL = 0|);
}


# Each DBD's name for what this dist asks of it by a DBD-private name, keyed the
# way DBI names the DBD in $dbh->{Driver}{Name}: the two attributes the sync
# storage reads or writes, and the async binding the future_io transport
# drives (karr k59, k60). One table for both, so the two cannot disagree about
# a DBD.
my %DBD_ATTRIBUTE = (
  mysql   => {
    auto_reconnect => 'mysql_auto_reconnect',
    insertid       => 'mysql_insertid',
    async          => 'async',
    socket_fd      => 'mysql_fd',
    async_ready    => 'mysql_async_ready',
    async_result   => 'mysql_async_result',
    serverinfo     => 'mysql_serverinfo',
  },
  MariaDB => {
    auto_reconnect => 'mariadb_auto_reconnect',
    insertid       => 'mariadb_insertid',
    async          => 'mariadb_async',
    socket_fd      => 'mariadb_sockfd',
    async_ready    => 'mariadb_async_ready',
    async_result   => 'mariadb_async_result',
    serverinfo     => 'mariadb_serverinfo',
  },
);


sub _dbd_attribute {
  my ($self, $dbd, $what) = @_;

  my $attr = ( $DBD_ATTRIBUTE{ $dbd // '' } || {} )->{$what};
  return $attr if defined $attr;

  $self->throw_exception(
    "DBIO::MySQL::Storage knows the '$what' name of DBD::mysql and "
  . 'DBD::MariaDB only, and this connection belongs to '
  . ( defined $dbd ? "DBD::$dbd" : 'no DBD driver it can name' )
  );
}


sub _dbh_last_insert_id {
  my ($self, $dbh) = @_;

  $dbh->{ $self->_dbd_attribute($dbh->{Driver}{Name}, 'insertid') };
}


sub _run_connection_actions {
  my $self = shift;

  my $dbh       = $self->_dbh;
  my $reconnect = $self->_dbd_attribute($dbh->{Driver}{Name}, 'auto_reconnect');

  if (
    $dbh->{$reconnect}
      and
    ! exists $self->_dbio_connect_attributes->{$reconnect}
  ) {
    $dbh->{$reconnect} = 0;
  }

  # A forked child's exit must not close this process's connections
  # (karr k56, ADR 0009).
  DBIO::MySQL::MariaDBForkGuard->install if $dbh->{Driver}{Name} eq 'MariaDB';

  # Before the connection actions of the caller, so on_connect_do and
  # on_connect_call can still set the mode they want (karr k120).
  session_setup($dbh);

  $self->next::method(@_);
}


sub session_setup {
  my ($dbh) = @_;
  $dbh->do(strict_sql_mode_statement());
  return;
}


sub strict_sql_mode_statement {
  return q{SET SESSION sql_mode = IF(}
    . q{FIND_IN_SET('STRICT_ALL_TABLES', @@SESSION.sql_mode) OR }
    . q{FIND_IN_SET('STRICT_TRANS_TABLES', @@SESSION.sql_mode), }
    . q{@@SESSION.sql_mode, }
    . q{CONCAT_WS(',', NULLIF(@@SESSION.sql_mode, ''), 'STRICT_ALL_TABLES'))};
}


sub bind_attribute_by_data_type {
  my ($self, $data_type) = @_;
  return { TYPE => DBI::SQL_BINARY() }
    if defined $data_type
      && $data_type =~ /\A(?:(?:tiny|medium|long)?blob|(?:var)?binary|bytea)\z/i;
  return undef;
}


sub _adjust_bind_values {
  my ($self, $sth, $bind, $bind_attrs) = @_;
  return text_binds($self->_dbh, $bind, $bind_attrs);
}


sub text_binds {
  my ($dbh, $bind, $bind_attrs) = @_;

  return $bind unless $dbh && ($dbh->{Driver}{Name} // '') eq 'mysql'
    && ($dbh->{mysql_enable_utf8mb4} || $dbh->{mysql_enable_utf8});

  my @copy = @$bind;
  for my $i (0 .. $#copy) {
    my $v = $copy[$i][1];
    next if !defined $v || ref $v || utf8::is_utf8($v)
      || $v !~ /[^\x00-\x7F]/ || $bind_attrs->[$i];
    utf8::upgrade($v);
    $copy[$i] = [ $copy[$i][0], $v ];
  }
  return \@copy;
}


sub _get_server_version {
  my $self = shift;

  my ($version) = eval { $self->_get_dbh->selectrow_array('SELECT VERSION()') };

  return $version if defined $version and length $version;

  return $self->next::method(@_);
}


sub _is_mariadb {
  my $self = shift;

  return ( ($self->_server_info->{dbms_version} // '') =~ /mariadb/i ) ? 1 : 0;
}


sub _determine_supports_insert_returning {
  my $self = shift;

  return 0 unless $self->_is_mariadb;

  return ( ($self->_server_info->{normalized_dbms_version} // 0) >= 10.005 )
    ? 1 : 0;
}

# we need to figure out what mysql version we're running
sub sql_maker {
  my $self = shift;

  # it is critical to get the version *before* calling next::method
  # otherwise the potential connect will obliterate the sql_maker
  # next::method will populate in the _sql_maker accessor
  my $mysql_ver = $self->_server_info->{normalized_dbms_version};

  my $sm = $self->next::method(@_);

  # MySQL always uses backtick quoting — ensure it is active even when
  # the caller did not pass quote_names in connect_info.
  $sm->{quote_char} //= $self->sql_quote_char;
  $sm->{name_sep}   //= $self->sql_name_sep;

  # mysql 3 does not understand a bare JOIN
  $sm->{_default_jointype} = 'INNER' if $mysql_ver < 4;

  # ADR 0036: which spelling of "the value that was attempted to be inserted"
  # this server understands in an ON DUPLICATE KEY UPDATE set. The storage is
  # the only side that can ask the server, so it decides and the maker only
  # renders (see DBIO::MySQL::SQLMaker/_insert_row_alias).
  $sm->{_upsert_row_alias} = $self->_upsert_row_alias;

  # karr #30: which locking-read grammar the server has. Same split as the line
  # above -- the storage asks the server, the maker renders what it is told
  # (see DBIO::MySQL::SQLMaker/_lock_dialect).
  $sm->{_lock_dialect} = $self->_lock_dialect;

  $sm;
}


sub _lock_dialect {
  my $self = shift;

  my $info = $self->_server_info || {};
  my $ver  = $info->{normalized_dbms_version} // 0;

  # A version we could not read is treated as current, on both branches; see
  # the POD above. MariaDB answers the two modifiers separately because it
  # shipped them separately: NOWAIT in 10.3, SKIP LOCKED in 10.6 (karr #38).
  return {
    share       => 'LOCK IN SHARE MODE',
    of          => 0,
    nowait      => ( $ver and $ver < 10.003 ) ? 0 : 1,
    skip_locked => ( $ver and $ver < 10.006 ) ? 0 : 1,
    server      => 'a MariaDB (' . ($info->{dbms_version} // '?') . ')',
  } if $self->_is_mariadb;

  return {
    share       => 'LOCK IN SHARE MODE',
    of          => 0,
    nowait      => 0,
    skip_locked => 0,
    server      => 'a MySQL older than 8.0.1 (' . ($info->{dbms_version} // '?') . ')',
  } if $ver and $ver < 8.000001;

  return {
    share       => 'FOR SHARE',
    of          => 1,
    nowait      => 1,
    skip_locked => 1,
    server      => 'a MySQL 8.0.1 or newer',
  };
}


sub _upsert_row_alias {
  my $self = shift;

  return undef if $self->_is_mariadb;

  my $info = $self->_server_info || {};

  return undef unless ($info->{normalized_dbms_version} // 0) >= 8.000020;

  return 'new';
}


sub insert {
  my ($self, $source, $to_insert, $opts) = @_;

  my $on_conflict = $opts ? $opts->{on_conflict} : undef;
  return $self->next::method($source, $to_insert, $opts) unless $on_conflict;

  my $plan = $self->_mysql_upsert_plan($source, $to_insert, $opts);

  # the renderer gets the two MySQL-private keys it cannot derive itself;
  # localised so the caller's structure comes back out unchanged
  local $opts->{on_conflict} = { %$on_conflict, %{ $plan->{extra} } };

  my $returned = $self->next::method($source, $to_insert, $opts);

  return $returned if $plan->{nameable} or ! $plan->{wants_identity};

  # Core's nameability test is exactly "did every primary key column come
  # back for the written row". It did not: whatever primary key value is in
  # hand belongs to the row we *tried* to insert, not necessarily to the row
  # the engine touched. Withholding it is the difference between undef and a
  # confidently wrong row.
  delete @{$returned}{ @{ $plan->{primary_columns} } };

  # The default result shape is the one value nobody types, so only the
  # runtime can teach the caller who needs teaching. Core carps too, but it
  # can only report the symptom (no primary key came back); the reason is a
  # MySQL grammar fact and this is the layer that knows it.
  carp_once($plan->{reason}) if defined $plan->{reason};

  return $returned;
}

# Everything ADR 0036 needs decided before the statement runs, derived from
# the ResultSource alone. Returns:
#
#   nameable        => can the written row be named afterwards
#   wants_identity  => is anybody asking (false for result => 'void'/'count')
#   primary_columns => \@pk, the columns to withhold when not nameable
#   extra           => private on_conflict keys for DBIO::MySQL::SQLMaker
#   reason          => the carp text for the unresolvable path, or undef
#
# The options may carry `returning => 0`, a hint from the reader of the
# result: "I read LAST_INSERT_ID(), not RETURNING". Without it (key absent or
# true) nothing changes; with it the plan takes the LAST_INSERT_ID(pk) idiom
# on MariaDB 10.5+ as well, where it is otherwise left out.
#
# Throws for a conflict target this engine cannot honour.
sub _mysql_upsert_plan {
  my ($self, $source, $to_insert, $opts) = @_;

  my $on_conflict = $opts->{on_conflict};
  my $sname = $source->source_name || $source->result_class || 'this result source';

  my @pk = $source->primary_columns;
  my %declared = $source->unique_constraints;

  # Distinct unique indexes, keyed by their column set. The same columns
  # declared under two names (a named constraint mirroring the primary key,
  # as the core test schema's Artist does) is ONE index to the engine, and
  # "is there more than one" is what everything below turns on.
  my (%unique_cols, %unique_names);
  for my $name (sort keys %declared) {
    my $key = _mysql_colset_key(@{ $declared{$name} });
    $unique_cols{$key} ||= [ @{ $declared{$name} } ];
    push @{ $unique_names{$key} }, $name;
  }
  if (@pk) {
    my $key = _mysql_colset_key(@pk);
    $unique_cols{$key} ||= [ @pk ];
  }

  my $pk_key = @pk ? _mysql_colset_key(@pk) : undef;

  # ---- the conflict target the caller ended up with

  my $target = $on_conflict->{target};
  my (@target_cols, $target_key);
  if (ref $target eq 'ARRAY') {
    @target_cols = @$target;
  }
  elsif (ref $target eq 'HASH' and defined $target->{constraint}) {
    @target_cols = $source->unique_constraint_columns($target->{constraint});
  }
  # anything else is 'any': the caller asked for the engine's own "whichever
  # key collides", which is the one target shape MySQL can actually deliver
  $target_key = _mysql_colset_key(@target_cols) if @target_cols;

  # ---- ADR 0036 section 1: a demanded target this engine cannot honour

  if (defined $target_key) {
    my @others = grep { $_ ne $target_key } sort keys %unique_cols;

    if (@others) {
      my $others_desc = join '; ', map {
        my $names = $unique_names{$_};
        sprintf '%s(%s)',
          ($names && @$names ? join('/', @$names) . ' ' : ''),
          join(', ', @{ $unique_cols{$_} })
      } @others;

      $self->throw_exception(
        "upsert() on $sname: MySQL cannot honour the requested conflict "
      . 'target (' . join(', ', @target_cols) . '). ON DUPLICATE KEY UPDATE '
      . 'has no conflict target in its grammar -- it fires on ANY primary or '
      . "unique key collision -- and $sname has further unique key(s) besides "
      . "the target: $others_desc. A collision on one of those would silently "
      . 'update a row the target never named, where PostgreSQL and SQLite '
      . "raise a unique violation for the same call. Pass "
      . "conflict_target => 'any' to ask for MySQL's native \"whichever key "
      . 'collides" behaviour deliberately, or target the only unique key of '
      . 'the table.'
      );
    }
  }

  # ---- ADR 0036 section 4: can the written row be named afterwards

  my $col_infos = $source->columns_info;

  # With a real target there is provably no other unique key (checked just
  # above), so the collision can only have happened on it. With 'any' the
  # target is only known when the table has exactly one unique key anyway.
  my $effective_key = defined $target_key
    ? $target_key
    : ( keys %unique_cols == 1 ? (keys %unique_cols)[0] : undef );

  # A primary key column is known client-side only when the caller supplied a
  # plain value: a literal (\'UUID()') is computed by the server, so its value
  # is exactly as unknown here as a missing one.
  my @pk_unknown = grep {
    ! defined $to_insert->{$_} or is_literal_value($to_insert->{$_})
  } @pk;

  # LAST_INSERT_ID() carries one value, so the idiom needs a single-column
  # AUTO_INCREMENT primary key.
  my $autoinc_pk = (@pk == 1 and $col_infos->{$pk[0]}{is_auto_increment})
    ? $pk[0] : undef;

  my $action = $on_conflict->{action} || 'update';
  my $set    = $on_conflict->{set} || {};

  my %extra;

  # The DO NOTHING emulation writes a column to itself; the primary key is
  # the most harmless choice, the target the fallback.
  if ($action eq 'nothing') {
    my $noop = @pk ? $pk[0] : (@target_cols ? $target_cols[0] : undef);
    $extra{noop_column} = $noop if defined $noop;
  }

  # result => 'void' / 'count' asks for one round-trip and nothing spent on
  # naming the row, so no identity work is done and none is missing.
  my $wants_identity = $opts->{no_retrieve} ? 0 : 1;

  # ADR 0036 section 4, rule 1: where the engine hands the written row back
  # itself, none of the identity machinery below is needed -- no
  # LAST_INSERT_ID(pk) no-op in the conflict set, no case distinction. That is
  # MariaDB from 10.5 on (karr #29); MySQL has no RETURNING and never takes
  # this branch.
  #
  # Core asks for RETURNING only for the columns it does not already have, so
  # the rule is exactly "every primary key column is one of them". A key value
  # the caller supplied comes back out of the caller's own data and is still no
  # evidence of which row the statement touched -- with no conflict target in
  # the grammar the collision may have happened on another unique index -- so
  # the shapes below keep deciding those.
  #
  # Unless the caller says it does not read RETURNING: `returning => 0` in the
  # options is the reader hint of a transport that always reads
  # SELECT LAST_INSERT_ID() (the ev backend), so the idiom stays in.
  my $reader_reads_last_insert_id =
    defined $opts->{returning} && ! $opts->{returning};

  my $returning_names_the_row =
    $self->_use_insert_returning && @pk && @pk_unknown == @pk
      && ! $reader_reads_last_insert_id;

  my ($nameable, $reason) = (0, undef);

  if (! $wants_identity) {
    $nameable = 1;
  }
  elsif (! @pk) {
    # Nothing to name and nothing to withhold: core's own "no primary key
    # came back" message says it exactly, so there is no MySQL detail to add.
    $nameable = 0;
  }
  elsif ($returning_names_the_row) {
    $nameable = 1;
  }
  elsif (
    defined $autoinc_pk
      and
    # the value has to be generated by the engine -- an explicitly supplied
    # one (literal included) leaves LAST_INSERT_ID() untouched on an insert
    ! defined $to_insert->{$autoinc_pk}
      and
    ! exists $set->{$autoinc_pk}
  ) {
    # Case 1 -- the engine's own identity channel. A no-op on the stored
    # value that makes LAST_INSERT_ID() report the primary key of the row
    # that was actually touched, insert or update, no matter which unique
    # index collided. Core then retrieves it exactly as it does for a plain
    # autoinc insert.
    #
    # UNVERIFIED ASSUMPTION, the one place in this driver that depends on it
    # (karr #27, ADR 0036): that this also holds when the UPDATE branch
    # changes no value at all, which MySQL reports as 0 affected rows. If a
    # live round-trip shows LAST_INSERT_ID() stale in that case, this branch
    # -- and only this branch -- has to fall back to the unresolvable path.
    $extra{identity_column} = $autoinc_pk;
    $nameable = 1;
  }
  elsif (defined $effective_key and defined $pk_key
         and $effective_key eq $pk_key and ! @pk_unknown) {
    # Case 2 -- the collision provably happened on the primary key, and the
    # caller supplied its values, so the row is named without asking the
    # server anything.
    $nameable = 1;
  }
  else {
    # Case 3 -- no channel. Which of the three shapes it is decides what the
    # caller is told.
    $nameable = 0;

    my $detail;
    if (defined $autoinc_pk and exists $set->{$autoinc_pk}) {
      $detail = "the conflict set assigns the AUTO_INCREMENT primary key "
              . "'$autoinc_pk' itself, which rules out the "
              . 'LAST_INSERT_ID(pk) identity idiom';
    }
    elsif (defined $autoinc_pk) {
      $detail = "the data supplies an explicit value for the AUTO_INCREMENT "
              . "primary key '$autoinc_pk', so LAST_INSERT_ID() reports "
              . 'nothing about the row on the insert branch';
    }
    elsif (@pk_unknown) {
      $detail = 'the primary key (' . join(', ', @pk) . ') is not a single '
              . 'AUTO_INCREMENT column and the data does not supply it '
              . '(missing: ' . join(', ', @pk_unknown) . ')';
    }
    else {
      $detail = 'the primary key (' . join(', ', @pk) . ') is not a single '
              . 'AUTO_INCREMENT column, and with ' . scalar(keys %unique_cols)
              . ' unique keys on the table ('
              . join('; ', map { join(', ', @{ $unique_cols{$_} }) }
                           sort keys %unique_cols)
              . ') a collision cannot be attributed to it';
    }

    $reason = "upsert() on $sname cannot name the row it wrote, so no row is "
            . 'returned: ON DUPLICATE KEY UPDATE does not report which key '
            . "collided, and $detail. Pass result => 'count' or 'void' if the "
            . 'written row is not needed, or upsert against a table whose only '
            . 'unique key is the conflict target.';
  }

  return {
    nameable        => $nameable,
    wants_identity  => $wants_identity,
    primary_columns => \@pk,
    extra           => \%extra,
    reason          => $reason
  };
}

# Order-insensitive identity of a column set, so "the same unique index" is
# one comparison rather than a nested loop.
sub _mysql_colset_key { join "\0", sort @_ }

sub sqlt_type {
  return 'MySQL';
}


sub deploy_defaults {
  return (add_drop_table => 1);
}


sub deploy_setup {
  my ($self, $schema) = @_;
  eval { $self->connect_call_set_zero_date_permissive };
}

sub connect_call_set_zero_date_permissive {
  my $self = shift;
  $self->_do_query(
    q{SET SESSION sql_mode = REPLACE(REPLACE(@@SESSION.sql_mode,'NO_ZERO_DATE',''),'NO_ZERO_IN_DATE','')}
  );
}



sub _mask_error_values {
  my ($self, $text, $values, $statement) = @_;

  return $text unless defined $text and !ref $text;

  my $masked = eval { DBIO::MySQL::Util::mask_error_details($text, $values, $statement) };
  $text = $masked if defined $masked;

  return $self->next::method($text, $values, $statement);
}

# karr #33 -- the function DBIO::ResultSet::rand drops into an order_by
# literal. Core answers RANDOM(), which neither product has; both spell it
# RAND(). The spelling is the easy half. The half that has to be CHECKED is
# whether the engine evaluates it per row, because a function that is computed
# once hands every row the same sort key and ORDER BY <it> is then a silent
# non-shuffle (that is what Sybase ASE's rand() does -- dbio-sybase karr #28).
# Both products document per-row evaluation, and neither leaves it to
# inference: MySQL's manual endorses ORDER BY RAND() as the way "to retrieve
# rows in random order" and its RAND() entry shows SELECT i, RAND() FROM t
# returning a different value for each of three rows, while MariaDB's RAND()
# page says outright that ORDER BY RAND() makes the server "generate a random
# value for each of them". See the "Random ordering" POD section.
#
# On the class both DBDs and both products share, because it is an engine fact
# that holds for both of them (karr k28, this dist's ADR 0001).
sub _random_function { 'RAND()' }

sub _bind_host_into_dsn {
  my ($self, $driver, $dsn, $host, $port) = @_;

  return $self->next::method($driver, $dsn, $host, $port)
    unless defined $dsn and $dsn =~ /^(dbi:\w*(?:\([^)]*\))?:)(.*)\z/is;
  my ($prefix, $rest) = ($1, $2);

  for my $part (grep { length } split /;/, $rest) {
    return (undef, "the key '$1' naming the server by a socket")
      if $part =~ /^((?:mysql|mariadb)_socket)=/i;
  }

  # key=value parts: the core form, host= and port= tokens.
  if ($rest =~ /=/) {
    return (undef, 'a positional part beside key=value parts')
      if grep { length and !/^\w+=/ } split /;/, $rest;
    return $self->next::method($driver, $dsn, $host, $port);
  }

  return $self->next::method($driver, $dsn, $host, $port) unless length $rest;
  return (undef, 'a positional part beside a semicolon') if $rest =~ /;/;

  # database[:host[:port]], read the way both DBDs read it.
  my @part;
  my $left = $rest;
  while (length $left) {
    my $val;
    if ($left =~ /([^:;]*\[.*]|[^:;]*)[:;](.*)/) {
      ($val, $left) = ($1, $2);
    }
    else {
      ($val, $left) = ($left, '');
    }
    push @part, $val;
  }
  return (undef, 'a positional DSN with more than database, host and port')
    if @part > 3;

  $host = "[$host]" if $host =~ /:/;
  $port = $part[2] unless defined $port;
  return $prefix . join ':', $part[0], $host, grep { defined } $port;
}


sub _ddl_sql_dialect { 'mysql' }


# _explain_query is deliberately NOT overridden, and the non-override is the
# decision rather than an omission -- so it is recorded where the override used
# to sit. Core's base operation is
#
#   my (undef, $sth) = $self->_execute_rendered("EXPLAIN $sql", $bind);
#   return $sth->fetchall_arrayref;
#
# which is exactly right for both products: EXPLAIN <SELECT> is the plan
# statement on each, it does not execute the query, and each answers with a
# tabular rowset that fetchall_arrayref collects. See the "Query plans" POD
# section for the citations.
#
# What used to sit here was
#
#   sub _explain_sql { "EXPLAIN $_[1]" }
#
# and it was already DEAD when it was removed: core ADR 0040 / karr #138 took
# the _explain_sql string hook out -- not deprecated, not aliased -- and put
# _explain_query in its slot in DBIO 0.900004, the version the cpanfile pins.
# Core had stopped calling it, so it produced the same statement by inheritance
# while looking like the thing that produced it. It also said nothing: it was
# byte-for-byte core's own default even while the hook still existed.

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

    $self->_dbh->do("ROLLBACK TO SAVEPOINT $name")
}

sub is_replicating {
    my $status = shift->_replication_status_row
      or return;

    # Both column spellings, because the row's is decided by the statement the
    # server answered -- see _replication_status_statement.
    my $io  = $status->{Replica_IO_Running}  // $status->{Slave_IO_Running};
    my $sql = $status->{Replica_SQL_Running} // $status->{Slave_SQL_Running};

    # A status row whose thread columns we cannot find is not "not
    # replicating", it is "this driver did not understand the answer" -- which
    # is what core's undef means (DBIO::Replicated::Pool prints "does not
    # support is_replicating" and leaves the replicant to manual management).
    return undef unless defined $io and defined $sql;

    return ($io eq 'Yes') && ($sql eq 'Yes');
}


sub lag_behind_master {
    my $status = shift->_replication_status_row
      or return undef;

    return $status->{Seconds_Behind_Source} // $status->{Seconds_Behind_Master};
}


sub _replication_status_statement {
    my $self = shift;

    my $ver = $self->_server_info->{normalized_dbms_version} // 0;

    return ( $ver >= 10.005001 ) ? 'SHOW REPLICA STATUS' : 'SHOW SLAVE STATUS'
      if $self->_is_mariadb;

    # An unreadable version is the one case with a real choice to make, and it
    # goes to the legacy spelling: that is wrong only on MySQL 8.4 and up,
    # where the version is hardly ever unreadable, while the modern spelling
    # would be wrong on every MySQL below 8.0.22.
    return ( $ver >= 8.000022 ) ? 'SHOW REPLICA STATUS' : 'SHOW SLAVE STATUS';
}


sub _replication_status_row {
    my $self = shift;
    return $self->_get_dbh->selectrow_hashref($self->_replication_status_statement);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Storage - MySQL storage layer for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  package MyApp::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');

  # Optionally enable strict mode on connect
  my $schema = MyApp::Schema->connect(
    $dsn, $user, $pass,
    { on_connect_call => 'set_strict_mode' },
  );

=head1 DESCRIPTION

MySQL storage backend for L<DBIO>. Extends L<DBIO::Storage::DBI> with
MySQL-specific behavior:

=over 4

=item *

Uses backtick quoting and MySQL's C<LIMIT [offset,] rows> syntax, rendered by
L<DBIO::MySQL::SQLMaker/apply_limit>.

=item *

Routes SQL generation through L<DBIO::MySQL::SQLMaker>, which
automatically wraps C<UPDATE> and C<DELETE> statements that reference
the modification target in a subquery.

=item *

Disables the DBD's auto-reconnect (C<mysql_auto_reconnect> or
C<mariadb_auto_reconnect>) on every connect by default to prevent silent
transaction loss.

=back

This class is auto-registered for the C<mysql> DBI driver and is set as the
active storage class when L<DBIO::MySQL/connection> is called. That pin holds
for every DSN, so it also runs over a C<dbi:MariaDB:> DSN. Every DBD-private
attribute is therefore named by the DBD that owns the handle, never by this
class (L</_dbd_attribute>).

=head2 Connecting with utf8mb4: the attribute hash, not the DSN

Under L<DBD::mysql> (measured with 4.055) C<mysql_enable_utf8mb4> works only as
an attribute of the connect-info hash. Put in the DSN
(C<dbi:mysql:database=app;mysql_enable_utf8mb4=1>) it is ignored without a
word, and the strings that come back are undecoded bytes:

  $schema->connect(
    'dbi:mysql:database=app', $user, $pass,
    { mysql_enable_utf8mb4 => 1 },
  );

L<DBD::MariaDB> (measured with 1.24) has no such attribute: it refuses the
connect with C<Unknown attribute mysql_enable_utf8mb4> (and likewise for
C<mariadb_enable_utf8mb4>), whether in the DSN or the hash. Leave it out over a
C<dbi:MariaDB:> DSN.

=head2 The base EXISTS rendering is right for both server products

This class declares the C<supports_exists_query> capability (ADR 0037), which
is what enables L<DBIO::ResultSet/results_exist>,
L<DBIO::ResultSet/results_exist_as_query> and
L<DBIO::ResultSet/results_exist_async>. The flag is not a formality: core
defaults it to false everywhere and treats it as an assertion that somebody
B<checked> the rendering against this engine, so what was checked is recorded
here.

The statement is core's own L<DBIO::Storage::DBI/_exists_value_sql>, deliberately
B<not> overridden:

  SELECT CASE WHEN EXISTS (SELECT 42 FROM `artist` `me` WHERE ...) THEN 1 ELSE 0 END

It asks two things of the server, and both are documented for both products:

=over 4

=item *

B<A C<SELECT> with no C<FROM>.> The MySQL 8.0 Reference Manual, section 15.2.13
(I<SELECT Statement>): "SELECT can also be used to retrieve rows computed
without reference to any table", and "MySQL does not require C<FROM DUAL> if no
tables are referenced". The MariaDB C<SELECT> reference says the same -- "SELECT
can also be used to retrieve rows computed without reference to any table", with
"If no table is involved, C<FROM DUAL> can be specified" as the optional
alternative. This is the clause that forces Oracle, DB2 and Firebird to override
the hook; neither of these two needs to.

=item *

B<C<EXISTS> in a condition position>, as the C<WHEN> of a C<CASE>. That is
strictly less than these engines already do: ADR 0037's portability table
records MySQL and MariaDB as accepting C<EXISTS> as a bare I<value expression>
(C<SELECT EXISTS (...)>), which is the spelling core emitted before that ADR and
the reason C<results_exist> worked here all along. An engine that takes C<EXISTS>
as a value takes it as a predicate.

=back

Neither half is a version fact and neither is a DBD fact, so the declaration
belongs on this class -- shared by C<dbi:mysql:> and C<dbi:MariaDB:> connections
and by both server products -- rather than on
L<DBIO::MySQL::Storage::MariaDB>, which is the L<DBD::MariaDB> binding and
nothing else.

=head2 Set operations: version-bounded on both products, and spelled the same on both

L<DBIO::ResultSet/union> and its five siblings take their keyword from
L<DBIO::Storage::DBI/_set_operation_keyword> (ADR 0039). This class overrides
that hook, but B<not to re-spell anything>: both server products call all six
operations by their ANSI names on every release that has them, so core's base
map is right here and the override exists only to B<refuse>.

=head3 What each product has, and since when

C<UNION> and C<UNION ALL> predate anything this driver could meet, on either
product. The other four are younger, and the two products drew two different
lines:

=over 4

=item *

B<MySQL 8.0.31 -- all four at once.> "C<EXCEPT> was added in MySQL 8.0.31"
(MySQL 8.0 Reference Manual, section 15.2.4, I<EXCEPT Clause>) and "C<INTERSECT>
was added in MySQL 8.0.31" (same manual, section 15.2.8, I<INTERSECT Clause>).
Both pages document the modifier in the operator's own grammar --
C<query_expression_body EXCEPT [ALL | DISTINCT] query_expression_body> -- and
the 8.0.31 release notes say it outright: "In this release MySQL adds support
for the SQL standard C<INTERSECT> and C<EXCEPT> table operators. ...
C<INTERSECT> and C<EXCEPT> both support C<DISTINCT> and C<ALL>, with
C<DISTINCT> the default in both cases" (WL #349). So on MySQL there is B<one>
boundary, not two: 8.0.31 delivered C<INTERSECT>, C<INTERSECT ALL>, C<EXCEPT>
and C<EXCEPT ALL> together.

=item *

B<MariaDB 10.3, then 10.5 -- two boundaries.> "MariaDB has supported
C<INTERSECT> (as well as C<EXCEPT>) in addition to C<UNION> since MariaDB 10.3"
(MariaDB C<INTERSECT> reference; the 10.3.0 release notes list "C<INTERSECT> and
C<EXCEPT>" under new syntax, MDEV-10141). The C<ALL> forms came two releases
later: the MariaDB 10.5.0 release notes list "C<EXCEPT ALL> and C<INTERSECT
ALL>" under I<Syntax> (MDEV-18844), and both reference pages carry the version
banner "MariaDB starting with 10.5.0" over their I<ALL/DISTINCT> section, whose
pre-10.5 tab reads "Only C<EXCEPT DISTINCT> is available" and "C<DISTINCT> is
the only behavior available".

=back

A MariaDB between 10.3 and 10.4 inclusive therefore has C<EXCEPT> and
C<INTERSECT> but not their C<ALL> forms -- the one real deployment state that a
single availability flag could not express, and the reason there are two below.

=head3 The refusal is declared, not probed -- and it defaults to available

The hook must answer as a B<static class fact>: L<DBIO::ResultSet/_set_operation>
bakes the keyword into a literal C<from> clause while the query is being built,
so asking the server which product and version it is would open a connection at
query-build time, purely in order to throw (ADR 0039 section 7). This driver
cannot look, so a deployment that cares declares:

  # this deployment's server predates EXCEPT / INTERSECT entirely
  # (MySQL < 8.0.31, or MariaDB < 10.3)
  DBIO::MySQL::Storage->_use_set_operator_intersect_except(0);

  # ... or has them, but not their ALL forms (MariaDB 10.3 / 10.4)
  DBIO::MySQL::Storage->_use_set_operator_all_family(0);

Both default to B<1>, i.e. all six operations available and no refusal at all.
This is the opposite polarity from L<DBIO::Oracle::Storage>, which declares its
equivalent C<_use_set_operator_all_family> as C<0>, and the difference is an
engine fact rather than a taste: Oracle's long-term releases (11.2, 19c) are the
ones B<without> the C<... ALL> family, so a permissive default there would send
supported servers SQL they reject. Here the reverse holds. Every non-EOL release
of either product is past every boundary above -- MySQL 8.0 (extended support),
8.4 LTS and 9.x; MariaDB 10.6 LTS, 10.11 LTS, 11.4 LTS and 11.8 LTS -- so a
default of C<0> would refuse four working operations on essentially the whole
installed base, which is exactly the regression ADR 0039 section 3 declined when
it refused a capability gate defaulting to C<0>.

What the switches buy an old deployment is therefore not correctness but
B<diagnosis>: with the relevant one turned off, C<< $rs->except_all($other) >>
throws locally, before a single operand is rendered, with a message naming both
products' boundaries -- instead of reaching the server as
C<ERROR 1064 (42000): You have an error in your SQL syntax> several layers below
the method the caller called.

Reach for the B<class-level> form shown above: it names the class, so it holds
from load time and needs no storage to exist yet. The same switch can be set on
one storage -- C<< $schema->storage->_use_set_operator_all_family(0) >>, for a
process talking to more than one server -- on a schema that declares this
driver, whose storage is this class from the connect on (core ADR 0067).

=head3 Nothing is re-spelled, and nothing is refused unconditionally

Both products call set difference C<EXCEPT> on every release that has it, so
there is no keyword for this driver to rename. (MariaDB additionally accepts
C<MINUS> as a synonym from 10.6.1 on, but only under C<sql_mode=ORACLE>, which
DBIO never sets, and C<EXCEPT> keeps working in that mode anyway.) And no
operation is missing from B<all> versions of B<either> product, so unlike
L<DBIO::MSSQL::Storage> or L<DBIO::SQLite::Storage> this driver has nothing to
refuse outright -- ADR 0039 section 7's option (a) would here withhold four
operations from every server that has them.

Both declarations sit on this class rather than on
L<DBIO::MySQL::Storage::MariaDB>: which operations a server has is a fact about
the B<server>, and that subclass is the L<DBD::MariaDB> binding and nothing else
(this dist's ADR 0001). DBD::MariaDB reaches MySQL servers and C<dbi:mysql:>
reaches MariaDB ones, so a declaration made there would answer differently for
the same server depending on which DSN found it.

=head2 Random ordering: C<RAND()>, and it really is evaluated per row

L<DBIO::ResultSet/rand> drops L<DBIO::Storage::DBI/_random_function> into an
C<order_by> literal. This class answers C<RAND()>, because core's inherited
C<RANDOM()> exists on neither product.

The spelling is the easy half. The half worth checking is whether the engine
evaluates the function B<per row>: one computed once per statement hands every
row the same sort key, and C<ORDER BY> over it is then not a shuffle at all and
says nothing about it. That is not hypothetical -- it is what Sybase ASE's
C<rand()> does, which is why L<DBIO::Sybase::Storage::ASE> answers C<NEWID()>
instead. Here both products document the per-row behaviour, and neither leaves
it to inference:

=over 4

=item *

B<MySQL.> The C<RAND()> entry (MySQL 8.0 Reference Manual, section 14.6.2,
I<Mathematical Functions>) shows C<SELECT i, RAND() FROM t> over a three-row
table returning three different values, states that "C<RAND()> in a C<WHERE>
clause is evaluated for every row (when selecting from one table) or
combination of rows (when selecting from a multiple-table join)" and that
"thus, for optimizer purposes, C<RAND()> is not a constant value", and then
names this exact use: "If the goal is to retrieve rows in random order, you can
use a statement like this: C<SELECT * FROM tbl_name ORDER BY RAND();>", with
"To select a random sample from a set of rows, combine C<ORDER BY RAND()> with
C<LIMIT>" -- which is precisely the statement C<< $rs->rand($n) >> builds.

=item *

B<MariaDB.> The C<RAND()> reference page carries the same worked example with
three distinct values, and says what the server does with the C<ORDER BY> form
outright: C<SELECT * FROM my_table ORDER BY RAND() LIMIT 10> makes MariaDB
"read all rows in the table, generate a random value for each of them, order
them, and finally ... apply the C<LIMIT> clause". A random value for each of
them is the property being asserted here.

=back

Two caveats that are documented rather than discovered, and neither of which
changes the answer. MySQL's manual warns that "use of a B<column> with
C<RAND()> values in an C<ORDER BY> or C<GROUP BY> clause may yield unexpected
results because for either clause a C<RAND()> expression can be evaluated
multiple times for the same row" -- that is about selecting C<RAND()> into the
column list and then ordering by that alias, and it is the opposite failure
from the one that matters: over-evaluation still shuffles, and the same manual
recommends the direct C<ORDER BY RAND()> form on the very next line. And
C<RAND()> "is not meant to be a perfect random generator"; C<< $rs->rand >>
promises an unpredictable order, not a cryptographic one.

The cost is the other thing both manuals agree on: this sorts the whole result
set. MariaDB's page says the technique "should never be used on a large table
as it will be extremely slow", and the reason it gives is the mechanism above.
That is a property of the idiom, not of this driver.

The declaration sits on this class, shared by both DBD drivers and both server
products, because it is true of both: C<RAND()> is not a L<DBD::MariaDB> fact
(this dist's ADR 0001).

=head2 Query plans: core's plain C<EXPLAIN> is the operation, unchanged

L<DBIO::ResultSet/explain> asks this storage for a plan through core's
L<DBIO::Storage::DBI/_explain_query> seam (core ADR 0040), and this driver
B<does not override it>. What runs is core's base operation:

  EXPLAIN <the resultset's SELECT>

through L<DBIO::Storage::DBI/_execute_rendered>, with the plan collected as
C<< $sth->fetchall_arrayref >>. That is already the correct operation on both
products, which is why the non-override is a decision and is recorded as one:

=over 4

=item *

B<It is the plan statement on both.> "When C<EXPLAIN> is used with an
explainable statement, MySQL displays information from the optimizer about the
statement execution plan" (MySQL 8.0 Reference Manual, section 15.8.2,
I<EXPLAIN Statement>); "when you precede a C<SELECT>, C<UPDATE> or a C<DELETE>
statement with the keyword C<EXPLAIN>, MariaDB displays information from the
optimizer about the query execution plan" (MariaDB C<EXPLAIN> reference).

=item *

B<It does not execute the query.> The engines' executing variants are spelled
differently and are B<not> what this seam issues: C<EXPLAIN ANALYZE> on MySQL
(8.0.18+) and the C<ANALYZE> statement on MariaDB, whose own page describes it
as "similar to C<EXPLAIN>, but it runs the query". Plain C<EXPLAIN> plans. This
is the same cut L<DBIO::PostgreSQL::Storage> made when it dropped its
C<ANALYZE> override: a caller asking what the planner intends does not expect
side effects. A caller who genuinely wants measured timings overrides
C<_explain_query> on a storage subclass and connects through it -- routing
every statement through L<DBIO::Storage::DBI/_execute_rendered>, never
C<< $self->dbh >>, as the contract requires.

=item *

B<The answer is a rowset.> Both products return the plan as an ordinary result
set with named columns (C<id>, C<select_type>, C<table>, C<type>,
C<possible_keys>, C<key>, C<rows>, C<Extra>, ...), which is the shape
C<fetchall_arrayref> collects. Unlike SQL Server and Sybase ASE, neither needs
a session setting; unlike Oracle and DB2, neither writes into a plan table that
a second statement has to read; unlike SQLite, neither answers a bare
C<EXPLAIN> with something that is not a query plan.

=back

B<What is not verified.> The bind values of the explained query travel into the
C<EXPLAIN> as placeholders. Both DBDs replace those client-side by default --
L<DBD::MariaDB> documents that "by default prepared statements are not used and
placeholder replacement is done by DBD::MariaDB prior to sending SQL statement
to MariaDB or MySQL server" -- so the server never sees a prepared C<EXPLAIN>
unless C<mariadb_server_prepare> / C<mysql_server_prepare> is switched on, and
even then DBD::MariaDB "fallbacks to normal non-prepared statement and tries
again" for statements the server will not prepare. A connection that sets
C<mariadb_server_prepare_disable_fallback> removes that safety net; that
combination was not tested here, and no server was run for this section at all.

=head1 METHODS

=head2 with_deferred_fk_checks

  $storage->with_deferred_fk_checks(sub { ... });

Executes the given coderef with C<FOREIGN_KEY_CHECKS> disabled for the
duration of the call. Useful when loading data with circular foreign key
dependencies.

=head2 connect_call_set_strict_mode

  my $schema = MyApp::Schema->connect(
    $dsn, $user, $pass,
    { on_connect_call => 'set_strict_mode' },
  );

Connection callback that enables C<ANSI>, C<TRADITIONAL>, and
C<ONLY_FULL_GROUP_BY> SQL modes and disables C<SQL_AUTO_IS_NULL>. Pass
C<set_strict_mode> as an C<on_connect_call> option to activate it.

=head2 _dbd_attribute

  my $attr = $storage->_dbd_attribute($dbh->{Driver}{Name}, 'auto_reconnect');
  my $attr = DBIO::MySQL::Storage->_dbd_attribute(MariaDB => 'insertid');

The name the DBD driver C<$dbd> gives one of its private attributes or
methods, for C<mysql> (L<DBD::mysql>, C<mysql_*>) or C<MariaDB>
(L<DBD::MariaDB>, C<mariadb_*>). C<$dbd> is the driver name as DBI reports it
in C<< $dbh->{Driver}{Name} >>. Throws for any other driver, since this class
cannot know what that driver calls it.

  auto_reconnect   attribute: the auto-reconnect switch
  insertid         attribute: the last AUTO_INCREMENT id, on a database
                   and on a statement handle
  async            prepare attribute: arms a non-blocking statement
  socket_fd        database handle method: the connection's socket fd
  async_ready      statement handle method: the result will not block
  async_result     statement handle method: finalise the statement
  serverinfo       attribute: the server's version string from the handshake

The sync storage needs the first two. The C<future_io> transport
(L<DBIO::MySQL::Storage::Async>) needs all seven: they are its async binding.

Every lookup is keyed on the B<DBD>, not on the storage class. The class does
not tell you the DBD. L<DBIO::MySQL> pins this class for every DSN, so
C<load_components('MySQL')> over a C<dbi:MariaDB:> DSN runs this class on a
L<DBD::MariaDB> handle, which dies on a FETCH of any C<mysql_*> attribute
("Unknown attribute"). L<dbio-mysql-ev|DBIO::MySQL::EV> connects exactly that
way. The sync storage therefore asks with the handle's own driver
name (L</_run_connection_actions>, L</_dbh_last_insert_id>). The future_io
transport asks per connection: with the DBD the DSN names for the
connect attributes, which are built before a handle exists, and with the
handle's own driver name from then on
(L<DBIO::MySQL::Storage::Async/One dist, two DBD drivers>).

=head2 _dbh_last_insert_id

The C<AUTO_INCREMENT> id of the last INSERT on C<$dbh>. It reads the insertid
attribute of whichever DBD owns the handle: C<mysql_insertid> or
C<mariadb_insertid> (L</_dbd_attribute>).

=head2 _run_connection_actions

Turns the DBD's auto-reconnect off on every new handle, then runs the
inherited connection actions. The attribute is C<mysql_auto_reconnect> or
C<mariadb_auto_reconnect>, whichever DBD owns the handle (L</_dbd_attribute>).
An explicit value for that attribute in the connect attributes is honoured
(this dist's ADR 0005).

A reconnect that DBIO does not see loses the open transaction without an error.
L<DBD::mysql> turns the attribute on by itself at connect under C<MOD_PERL> or
C<GATEWAY_INTERFACE>. The reset runs at connect and spells the attribute for
the DBD that owns the handle, so a connect through L<DBD::MariaDB> works as
one through L<DBD::mysql> does.

=head2 session_setup

    DBIO::MySQL::Storage::session_setup($dbh);

What a connection of this driver does to its session before anything else runs
on it: C<< $dbh->do(strict_sql_mode_statement()) >>. One function for every
connection the driver opens -- the synchronous one (C<_run_connection_actions>)
and each pooled and listen connection of the C<future_io> transport
(L<DBIO::MySQL::Storage::Async/_mysql_connect>) -- so the two cannot differ.

=head2 strict_sql_mode_statement

    my $sql = DBIO::MySQL::Storage::strict_sql_mode_statement();

The statement every connection runs first (the sync storage in
C<_run_connection_actions>, every pooled and listen connection of the
C<future_io> transport): C<STRICT_ALL_TABLES> is added to the C<sql_mode> of the
session unless it already holds C<STRICT_ALL_TABLES> or C<STRICT_TRANS_TABLES>.
Both servers are strict by default; a server configured without it (or a
MySQL before 5.7, a MariaDB before 10.2.4) stores a value that does not fit
silently cut or rewritten -- eleven characters in a C<CHARACTER(10)> column are
kept as ten. The driver does not let that happen unasked. Only the session
changes, never the server; an C<on_connect_do> or C<on_connect_call> of the
caller runs afterwards and can set any mode.

=head2 bind_attribute_by_data_type

    my $attr = $storage->bind_attribute_by_data_type($data_type);

Returns C<< { TYPE =E<gt> DBI::SQL_BINARY } >> for the binary types (C<blob>
and its sizes, C<binary>, C<varbinary>, C<bytea>), C<undef> for any other.
Without it a value bound to a C<BLOB> column is text to L<DBD::MariaDB>, which
encodes every byte above 0x7F as UTF-8 on the way in (a byte string of 256
different bytes is stored as 384, C<0x83> as C<0xC2 0x83>). With the binary
type the bytes go in as they are.

=head2 _adjust_bind_values

Under L<DBD::mysql> with C<mysql_enable_utf8mb4> (or C<mysql_enable_utf8>) a
text value is sent as it is held: a string with characters above 0xFF is
encoded as UTF-8, one without (C<"\x{fc}"> in Perl's native 8-bit form) goes
out as the single byte C<0xFC>, which the server refuses as an incorrect string
value -- or, on a server that is not strict, stores cut. The same value written
as C<"\x{fc}\x{20ac}"> arrives whole. L<DBD::MariaDB> upgrades the string
itself. This hook gives L<DBD::mysql> the same reading: every plain string that
is not flagged as characters, and is not bound as binary
(L</bind_attribute_by_data_type>), is upgraded to characters in a copy before
it is bound. The caller's values are not touched. A handle without the
attribute is bytes in, bytes out, and stays as it was.

This is core's seam for a value changed before it is bound
(L<DBIO::Storage::DBI/_adjust_bind_values>), which both ways to the server run
through: the statements bound one by one (C<create>, C<search>, C<update>) and
each row of a C<populate> in void context. Overriding C<_bind_sth_params> would
have left the second one out.

B<This changes what an existing caller gets.> Text that the caller has already
encoded to UTF-8 and binds as bytes (a string not flagged as characters, with
bytes above 0x7F) is encoded once more under this attribute. That is the right
reading: with C<mysql_enable_utf8mb4> the DBD hands text back as characters,
so characters are what goes in, and bytes belong in a binary column
(C<blob>, C<binary>), which is bound as binary and left alone.

=head2 text_binds

    my $bind = DBIO::MySQL::Storage::text_binds($dbh, $bind, $bind_attrs);

The bind rule of L</_adjust_bind_values> as a function, for every statement the
driver sends: C<$bind> is the list of C<< [ $meta, $value ] >> pairs,
C<$bind_attrs> the DBI attribute per position (C<undef> for none, a C<TYPE>
for a value bound as binary). Returns C<$bind> itself, or -- under
L<DBD::mysql> with C<mysql_enable_utf8mb4> or C<mysql_enable_utf8> -- a copy in
which every plain string that is not flagged as characters and is not bound as
binary is upgraded to characters. The synchronous storage calls it from
C<_adjust_bind_values>, the C<future_io> transport for each statement it submits
(L<DBIO::MySQL::Storage::Async/_submit_query>), so a value reaches the server
the same way on both.

=head2 _get_server_version

The version of the connected server, read with C<SELECT VERSION()> instead of
the inherited C<get_info(SQL_DBMS_VER)>.

C<get_info> cannot be trusted here. L<DBD::MariaDB> answers it in a zero-padded
packed form -- C<08.00.4600> for MySQL 8.0.46, C<11.08.0800> for MariaDB 11.8.8
-- and core's normaliser (L<DBIO::Storage::DBI/_server_info>) stops at the first
dotted component above 999, so C<(08, 00, 4600)> collapses to C<8.0.0>. Every
gate finer than major.minor then reads a server that does not exist: the
C<< >= 8.0.20 >> row-alias gate of L</_upsert_row_alias> fails on a server that
has the alias, and C<11.08.0800> passes it while carrying no product name at
all, which is how a MariaDB server ends up being handed C<AS new> and answering
with a syntax error.

C<SELECT VERSION()> answers C<8.0.46> and C<11.8.8-MariaDB-ubu2404>: the true
numbers B<and> the product name L</_is_mariadb> reads. It costs one query per
connection -- C<_server_info> caches the result for the lifetime of the C<$dbh>
-- and it is the same string C<@@version> holds, so it is a fact about the
server rather than about the DBD driver (this dist's ADR 0001).

Falls back to the inherited C<get_info> route when the query yields nothing, so
a server that will not answer it is no worse off than before this override
existed.

=head2 _is_mariadb

True when the connected B<server> is a MariaDB, false when it is a MySQL.
Answered from the product name in the version string L</_get_server_version>
obtained, which is the only side that knows -- the two engines share a wire
protocol, a DBD driver, and (up to 5.5) a version numbering.

Deliberately B<not> answered from the storage class or the DBD driver name.
L<DBIO::MySQL::Storage::MariaDB> is the L<DBD::MariaDB> binding, not the MariaDB
server: DBD::MariaDB talks to MySQL servers and L<DBD::mysql> talks to MariaDB
ones, so the class the connection landed in answers a different question than
"which engine is at the other end" (this dist's ADR 0001, and the reason this method exists
rather than a second C<< =~ /mariadb/i >> at every call site).

=head2 _determine_supports_insert_returning

Declares C<insert_returning> for MariaDB 10.5 and up, which is where
C<INSERT ... RETURNING> arrived, and never for MySQL, which has no C<RETURNING>
at all.

ADR 0036 assumed MariaDB could not combine C<RETURNING> with
C<ON DUPLICATE KEY UPDATE> and built the whole MySQL identity story on that
assumption. It is wrong: measured on MariaDB 11.8.8 on 2026-07-25, the
combination is accepted and hands back the right row on B<both> branches -- the
update branch returned the pre-existing row carrying its new values. So MariaDB
falls under the ADR's rule 1, "the engine returns the written row", and needs
neither the C<LAST_INSERT_ID(pk)> idiom nor the follow-up C<SELECT> the other
rules cost. C<_mysql_upsert_plan> leaves the idiom out where this
capability is in effect.

Gated on the B<server> (L</_is_mariadb> plus the version), not on the storage
class. Declaring it in L<DBIO::MySQL::Storage::MariaDB> would tie a server
capability to the DBD driver: the same MariaDB server would have C<RETURNING>
through a C<dbi:MariaDB:> DSN and not through a C<dbi:mysql:> one, and a MySQL
server reached through L<DBD::MariaDB> -- which is how this dist's live suite
reaches MySQL -- would be promised a clause its parser rejects (this dist's ADR 0001).

C<insert_returning_bound> is deliberately not declared: like PostgreSQL and
SQLite, and unlike Oracle's C<RETURNING ... INTO :bind>, MariaDB hands the
values back as an ordinary result set on the statement handle, which is exactly
what core fetches when no returning container is requested.

=head2 _lock_dialect

  my $dialect = $storage->_lock_dialect;

The locking-read grammar of the connected B<server>, handed to
L<DBIO::MySQL::SQLMaker/_lock_select> through this class's C<sql_maker>. A
hashref:

=over 4

=item *

C<share> -- the keyword C<< $rs->search({}, { for => 'share' }) >> renders as,
C<FOR SHARE> or C<LOCK IN SHARE MODE>.

=item *

C<of> -- whether C<< for => { of => ... } >> can be rendered at all.

=item *

C<nowait> -- likewise for C<< modifier => 'nowait' >>.

=item *

C<skip_locked> -- likewise for C<< modifier => 'skip_locked' >>. Two keys and
not one C<modifiers> flag, because the two products did not introduce the two
modifiers together.

=item *

C<server> -- a human label for the exception the maker throws on a refusal,
carrying the version string the boundaries below were measured against.

=back

Four engine facts decide it, and all four are read from the B<server>:

=over 4

=item *

B<MySQL 8.0.1 introduced all three parts at once.> "C<SELECT ... FOR SHARE> is
a replacement for C<SELECT ... LOCK IN SHARE MODE>, but C<LOCK IN SHARE MODE>
remains available for backward compatibility. The statements are equivalent.
However, C<FOR SHARE> supports C<OF I<table_name>>, C<NOWAIT>, and C<SKIP
LOCKED> options." (MySQL 8.0 Reference Manual, section 17.7.2.4, I<Locking
Reads>.) So on a MySQL before 8.0.1 the only spelling is C<LOCK IN SHARE MODE>
and there is no C<OF> and no modifier to render; from 8.0.1 on, C<FOR SHARE> is
the one that carries them.

=item *

B<MariaDB has C<FOR SHARE> in no version, and C<OF> in none either.> Its
C<SELECT> grammar reads C<< [FOR UPDATE lock_option | LOCK IN SHARE MODE
lock_option] >> with C<< lock_option: [WAIT n | NOWAIT | SKIP LOCKED] >> -- the
modifiers attach to both locking clauses, and no C<OF> appears anywhere.

=item *

B<MariaDB's two modifiers did not arrive together.> C<NOWAIT> (and the
MariaDB-only C<WAIT n> this driver has no DSL for) came in 10.3: MDEV-11379,
"AliSQL: [Feature] Issue#8: SELECT FOR UPDATE WAIT", fix version 10.3.0,
resolution Fixed. C<SKIP LOCKED> came three releases later, in 10.6: MDEV-13115,
"Implement SELECT [FOR UPDATE|LOCK IN SHARED MODE] SKIP LOCKED", fix version
10.6.0, resolution Fixed. A MariaDB from 10.3 through 10.5 therefore has one
modifier and not the other -- the deployment state a single flag could not
express, exactly as the MariaDB 10.3/10.4 gap in the set operations above needed
two switches rather than one. Where C<SKIP LOCKED> does exist it is still not
unconditional: the MariaDB C<SELECT> reference records that it is "only
implemented on InnoDB tables and ignored otherwise", so on another engine the
modifier is accepted and silently does nothing. That is invisible from here --
the storage engine is a per-table property of the statement, not of the server --
so this method does not gate on it; it is named because a silently ignored
modifier is a different trap from a rejected one.

=item *

B<C<LOCK IN SHARE MODE> is understood by every version of both products>, which
is why it is the answer whenever C<FOR SHARE> is not available rather than
something needing its own fallback.

=back

Decided here, from L</_is_mariadb> plus the server version, and B<not> from
the storage class. A choice made on L<DBIO::MySQL::Storage::MariaDB>'s
C<sql_maker_class>, i.e. on the DBD driver name, gets two of the four
DBD/engine combinations wrong: a MariaDB server reached through a
C<dbi:mysql:> DSN (which does not reach that subclass: a schema declares its
driver, and one that loads the MySQL component keeps this class) would be
handed C<FOR SHARE>, which MariaDB rejects, and a MySQL 8 server reached
through L<DBD::MariaDB> -- how this dist's own live suite reaches MySQL --
would be handed C<LOCK IN SHARE MODE OF `t` NOWAIT>, which MySQL also rejects,
because the legacy spelling is exactly the one that carries neither part.

An unknown or unreadable server version is treated as a current MySQL, the same
polarity the set-operation declarations above use and for the same reason: every
non-EOL MySQL is past 8.0.1, and both servers that need the older spelling are
ones this method can actually recognise. The MariaDB branch answers the same
way within its own product: a version string that names MariaDB but carries no
readable number is taken to have both modifiers, since every non-EOL MariaDB is
past 10.6.

=head2 _upsert_row_alias

Returns the row-alias name to use in
C<INSERT ... VALUES (...) AS new ON DUPLICATE KEY UPDATE col = new.col>, or
C<undef> when the older C<VALUES(col)> function must be used instead.

MySQL 8.0.20 introduced the row alias and deprecated C<VALUES(col)> in the
same release, so the switch is a pure server-version question -- answered
here from C<< _server_info->{normalized_dbms_version} >>, never from the DBD
driver name (this dist's ADR 0001). The one wrinkle is MariaDB: it never grew the alias
syntax, and its version numbers (10.x, 11.x) sail straight past a numeric
C<< >= 8.0.20 >> gate, so L</_is_mariadb> is consulted first. Both halves rest
on L</_get_server_version> asking the server itself; with the inherited
C<get_info> string neither of them is reliable.

=head2 insert

Rides the core insert path (ADR 0036 section 2) and adds the two things only
this driver can decide, both from static schema metadata and both before a
single statement is sent:

=over 4

=item *

B<Conflict-target validation> (ADR 0036 section 1). MySQL is the only engine
whose grammar has no conflict target, so a caller who demanded one gets an
exception when the table has any further unique key -- the guarantee is not
deliverable here, and the same call raises a unique violation on PostgreSQL
while it would silently rewrite an unrelated row on MySQL.

=item *

B<Row identity> (ADR 0036 section 4). Whether the written row can be named,
and if so how. With an AUTO_INCREMENT primary key the conflict set gets the
C<< `pk` = LAST_INSERT_ID(`pk`) >> idiom appended so the ordinary core
retrieval (C<last_insert_id> plus a C<SELECT> on the primary key) names the
row that was actually touched. Where no channel exists, the primary key is
withheld from the returned column set, which is core's signal for "the engine
could not name the row": C<row_or_undef> returns C<undef>, C<row_or_die>
throws.

On a server that has C<RETURNING> -- MariaDB 10.5 and up, see
L</_determine_supports_insert_returning> -- none of that applies to a statement
whose primary key core is fetching: the engine hands the written row back
itself, so the idiom is left out of the conflict set rather than carried along
as a no-op assignment nobody reads. A transport that reads C<SELECT
LAST_INSERT_ID()> instead of C<RETURNING> (the C<ev> backend) says so with
C<< returning => 0 >> in the options handed to C<_mysql_upsert_plan>; the plan
then keeps the idiom on MariaDB 10.5 and up as it does everywhere else. What remains decided the hard way is the
shape where the caller supplied the primary key, because core then asks for no
C<RETURNING> column at all and the supplied value is still no evidence of which
row a targetless statement touched.

=back

A plain insert (no C<on_conflict> in the options) passes straight through.

Two things worth knowing about the boundaries of this:

=over 4

=item *

B<Only declared constraints are visible.> Both rules read
L<DBIO::ResultSource/unique_constraints>, so a unique index that exists in the
database but was never declared on the result class cannot be taken into
account -- the engine will still fire on it. Declaring the unique keys is
therefore not decoration here; it is what makes the target rule true.

=item *

B<< C<< on_conflict => 'nothing' >> can still hand back a row. >> The
emulation assigns a column to itself, and on an AUTO_INCREMENT table that
assignment is the identity idiom, so an already-present row is named and
returned. PostgreSQL's C<DO NOTHING ... RETURNING> yields no row in the same
situation and C<upsert> returns C<undef> there. Telling the two apart here
would mean reading affected-rows, which C<CLIENT_FOUND_ROWS> (on by default in
DBD::mysql and in DBD::MariaDB) makes ambiguous on MySQL and on MariaDB alike
-- 1 for the row that was already there as for the one just inserted, and so
C<< result => 'count' >> does not tell them apart either (measured, see
L<DBIO::MySQL::SQLMaker/_insert_on_conflict>) -- so the more useful of the two
answers is given rather than a guess.

=back

=head2 deploy_defaults

MySQL has no transactional DDL and no C<IF NOT EXISTS> on all statement types.
Returns C<< add_drop_table => 1 >> so that L<DBIO::Test> can safely re-deploy
the same schema in a test sequence without hitting C<table already exists>
errors.

=head2 deploy_setup

Strips C<NO_ZERO_DATE> and C<NO_ZERO_IN_DATE> from the session C<sql_mode>
before deploying a schema during tests.  MySQL 8 strict mode rejects
C<0000-00-00> which the test suite uses to verify
C<datetime_undef_if_invalid> behaviour.

Delegates to L</connect_call_set_zero_date_permissive>. Note this only
relaxes the C<sql_mode> on the handle live at deploy time; when later
B<writes> (not just the deploy) must tolerate zero dates, wire
C<set_zero_date_permissive> through C<on_connect_call> instead so every
(re)connect inherits the relaxed mode.

=head2 connect_call_set_zero_date_permissive

  my $schema = MyApp::Schema->connect(
    $dsn, $user, $pass,
    { on_connect_call => 'set_zero_date_permissive' },
  );

Strips C<NO_ZERO_DATE> and C<NO_ZERO_IN_DATE> from the session C<sql_mode>
so C<0000-00-00> can be written under MySQL 8 strict mode. Installed as an
C<on_connect_call> it re-runs on every (re)connect, so the session actually
issuing the writes -- not merely the connection alive at deploy time --
carries the relaxed mode. This is the seam L</deploy_setup> delegates to.

=head2 _mask_error_values

  my $text = $storage->_mask_error_values($text, \@values, $statement);

The seam of core (L<DBIO::Storage::DBI/_mask_error_values>) through which the
text of an error passes before it is thrown, with the rules of the MySQL and
MariaDB engines in front of the base's: the sentences in which the server quotes
a value (C<Duplicate entry>, C<Incorrect ... value>, the excerpt after C<near>)
and the bound values in the forms both DBDs write them, even when they are
shorter than the base looks for (L<DBIO::MySQL::Util/mask_error_details>). The
type, the column, the key and the constraint stay.

  Duplicate entry 'geheim42' for key 'users.PRIMARY'
  # becomes
  Duplicate entry '***' for key 'users.PRIMARY'

Applies to L<DBIO::MySQL::Storage::MariaDB> as well. Never throws; a text it
cannot treat is answered unchanged.

=head2 _bind_host_into_dsn

    my $dsn = $storage->_bind_host_into_dsn('mysql', 'dbi:mysql:app:db1:3306', 'db2', 3307);
    # 'dbi:mysql:app:db2:3307'

The seam a L<DBIO::AccessBroker::HostBound> view binds its host (and port) into a
DSN with (L<DBIO::Storage::DBI/_bind_host_into_dsn>). DBD::mysql
and DBD::MariaDB read the same two forms and both reach this method. The key
form (C<host=>, C<port=>) is core's default. This adds the positional form
C<database[:host[:port]]>, in which the parts that are not C<key=value> fill
database, host and port in that order: the host is put in its place (a missing
one is added), the port as well when the view has one and the DSN's own stays
when it has not, and the form stays positional.

It declines, naming the form and never a value of the DSN, what it cannot
bind without guessing: a C<mysql_socket=> or C<mariadb_socket=> key (the socket
names the server and the host would be ignored, so a replicant would still
reach the local one), a positional part next to C<key=value> parts or a
semicolon, and more than three positional parts.

=head2 _ddl_sql_dialect

    my $dialect = $storage->_ddl_sql_dialect;    # 'mysql'

Names the SQL dialect this driver's DDL is written in, for the splitter
L<DBIO::Deploy::Base/_execute_ddl> cuts install and upgrade DDL with
(L<DBIO::Storage::DBI::Capabilities/_ddl_sql_dialect>). Declared,
the splitter reads a backslash in a string literal as MySQL does, as an escape:
C<'it\'s; fine'> is one literal. Undeclared, it takes both readings and cuts at
the semicolon either of them sees. MariaDB declares C<mysql> as well, so
L<DBIO::MySQL::Storage::MariaDB> inherits this; it is a fact about the SQL both
products speak, like C<_random_function>, not about the DBD.

=head2 is_replicating

Returns true if the connected MySQL or MariaDB replica is currently replicating
from its source (both IO and SQL threads running). Intended for use with
L<DBIO::Replicated::Storage>.

Reads the thread columns under both spellings, because the row it gets them
from carries whichever the statement L</_replication_status_statement> chose
produced: a MySQL 8.0.22 or newer answering C<SHOW REPLICA STATUS> names them
C<Replica_IO_Running> and C<Replica_SQL_Running>, everything else
C<Slave_IO_Running> and C<Slave_SQL_Running>. Returns C<undef> -- core's "this
driver cannot answer" -- when the server is not a replica, or when a status row
came back in which neither spelling is present.

=head2 _replication_status_statement

  my $sql = $storage->_replication_status_statement;

Which spelling of the replica-status statement the connected B<server>
understands: C<SHOW REPLICA STATUS> or C<SHOW SLAVE STATUS>. Both products
renamed it, at different releases, and one of them has since B<removed> the old
name, so this is a fact about the server and its version and nothing else
(this dist's ADR 0004):

=over 4

=item *

B<MySQL renamed it in 8.0.22 and removed the old name in 8.4.> "From MySQL
8.0.22, use C<SHOW REPLICA STATUS> in place of C<SHOW SLAVE STATUS>, which is
deprecated from that release" (MySQL 8.0 Reference Manual, section 15.7.7.35),
and the 8.4 manual lists C<SHOW SLAVE STATUS> under I<Features Removed in MySQL
8.4>: "Removed SQL statements relating to replicas ... C<SHOW SLAVE STATUS>: Use
C<SHOW REPLICA STATUS>." So on a MySQL 8.4 replica the legacy statement is a
syntax error, not a deprecation warning.

=item *

B<MySQL renamed the output columns with it.> "The statement works in the same
way as before, only the terminology used for the statement B<and its output> has
changed" (section 15.7.7.36). C<SHOW REPLICA STATUS> answers with
C<Replica_IO_Running>, C<Replica_SQL_Running> and C<Seconds_Behind_Source>;
C<SHOW SLAVE STATUS>, where it still exists, keeps the C<Slave_> /
C<Seconds_Behind_Master> names. This is why picking the statement is only half
the job -- L</is_replicating> and L</lag_behind_master> read both spellings.

=item *

B<MariaDB added the new name in 10.5.1 and kept both, with the old columns.>
Its C<SHOW REPLICA STATUS> page documents the grammar as
C<< SHOW { SLAVE | REPLICA } ["connection_name"] STATUS >> and still describes
the output as C<Slave_IO_Running>, C<Slave_SQL_Running> and
C<Seconds_Behind_Master>. So on MariaDB the rename is a pure alias and either
statement works; this method still prefers the modern spelling where the server
has it, so that one rule serves both products.

=back

=head2 _replication_status_row

    my $row = $storage->_replication_status_row;

Returns the replica-status row as a hashref, or C<undef> when the connected
server is not a replica. The statement it issues comes from
L</_replication_status_statement>, i.e. from the server's product and version;
the column names in the row it returns follow from that same choice.

This is the engine seam: anything that needs to read replication state
should go through here instead of issuing C<SHOW ... STATUS> itself.

=head2 lag_behind_master

Returns the number of seconds the replica is behind its source, as reported by
the replica-status row -- C<Seconds_Behind_Source> on a MySQL answering the
modern statement, C<Seconds_Behind_Master> everywhere else. Returns C<undef> if
replication status is unavailable.

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::MySQL> - Schema component that activates this storage

=item * L<DBIO::MySQL::SQLMaker> - SQL generation used by this storage

=item * L<DBIO::MySQL::Storage::MariaDB> - MariaDB-specific subclass

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
