package DBIO::DuckDB::Storage;
# ABSTRACT: DuckDB storage driver for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

use base qw/DBIO::Storage::DBI/;
use mro 'c3';

use Try::Tiny;
use Math::BigInt ();
use FFI::Platypus::Buffer ();
use version ();
use DBIO::Util qw(mask_connect_secrets);
use DBIO::DuckDB::Extension ();
use DBIO::DuckDB::Util ();
use DBIO::Extension::Protocol ();
use namespace::clean;

__PACKAGE__->register_driver('DuckDB' => __PACKAGE__);

sub dbio_deploy_class { 'DBIO::DuckDB::Deploy' }

__PACKAGE__->sql_maker_class('DBIO::DuckDB::SQLMaker');
__PACKAGE__->sql_quote_char ('"');

# ADR 0037: core's base _exists_value_sql renders
#   SELECT CASE WHEN EXISTS <inner> THEN 1 ELSE 0 END
# which DuckDB accepts unchanged -- so this driver declares the capability
# and overrides nothing. See the CAPABILITIES POD below for the three
# assumptions that form makes and where each is documented.
__PACKAGE__->_use_supports_exists_query(1);

# F02 / F10 -- transactional DDL. Declared 1: DuckDB the engine has
# transactional DDL, comprehensively, and this storage now ends the
# transactions the DBI driver underneath cannot (ADR 0005).
#
# DuckDB the engine has transactional DDL, comprehensively. Measured on
# libduckdb v1.5.3 via DBD::DuckDB 0.16: CREATE TABLE, DROP TABLE, ALTER TABLE
# (ADD / DROP / ALTER COLUMN), CREATE INDEX, DROP INDEX, CREATE SEQUENCE and
# CREATE VIEW all roll back inside BEGIN ... ROLLBACK, and the whole install
# batch this driver emits -- CREATE SEQUENCE, CREATE TABLE with
# DEFAULT nextval('...'), CREATE INDEX -- commits as one transaction with the
# sequence live afterwards. DuckDB documents the ALTER TABLE half outright --
# "All the changes made by ALTER TABLE fully respect the transactional
# semantics ... and can be fully reverted through a rollback"
# (duckdb.org/docs/stable/sql/statements/alter_table) -- and documents no
# statement this driver emits as one that may not be in a transaction, unlike
# PostgreSQL's ALTER TYPE ... ADD VALUE. Nothing here needs core's
# _ddl_statement_is_transactional escape. Nor is the deploy path the reason:
# DBIO::DuckDB::Diff emits plain statements in tables-then-columns-then-indexes
# order, with no SQLite-style create/copy/drop/rename rebuild and no pragma
# brackets that a txn_do wrap could swallow. Bracketed, the real path works --
# install, diff, apply and a second empty diff all pass, and a batch whose
# last statement fails rolls the earlier ones back instead of leaving them
# applied.
#
# One engine-side caveat, forward-looking rather than a breakage today. DuckDB
# refuses to alter a column an index depends on, and documents the remedy as
# "drop the index, alter the table, and then recreate the index" (same page).
# That remedy only works UNBRACKETED: measured here, DROP INDEX followed by
# ALTER TABLE ... ALTER COLUMN ... TYPE in one transaction still dies with
# "Cannot change the type of this column: an index depends on it!", because the
# type-change check does not see the uncommitted DROP INDEX. It is specific to
# the type change -- DROP COLUMN and SET NOT NULL after a DROP INDEX both
# commit fine. The diff cannot emit that pair today (indexes are diffed after
# columns, so a type change on an indexed column already fails, wrapped or
# not), so nothing regresses; but a wrap does foreclose the documented fix for
# it, and that is worth knowing before anyone reorders the phases.
#
# What used to block the 1 is that DBD::DuckDB could not end such a
# transaction. Its rollback issues ROLLBACK and then immediately reopens one:
#
#     $dbh->do('ROLLBACK');
#     $dbh->do('BEGIN TRANSACTION');
#
# which is right for AutoCommit=0, and DBI restores AutoCommit=1 afterwards --
# but the AutoCommit STORE handler that would COMMIT the reopened transaction
# is unreachable. It guards the commit branch with
# C<my $never_set = !$old_value>, so the preceding branch, C<!$old_value &&
# $value && $never_set>, has the identical condition and always wins; the
# 0 -> 1 transition is a silent no-op. (DBD::DuckDB 0.16, the current CPAN
# release, sub STORE.)
#
# So every txn_do that ROLLS BACK used to leave DuckDB inside an open
# transaction while DBI believes AutoCommit is on, and the next txn_begin died
# -- "cannot start a transaction within a transaction", or "Current transaction
# is aborted (please ROLLBACK)" when the rollback followed a failed statement.
# On the :memory: DSN that is DuckDB's headline mode it was worse than an
# error: DBIO::Storage::DBI::_exec_txn_begin deliberately retries begin_work on
# reconnect, so the poisoned handle was silently replaced by a connection to a
# brand-new, EMPTY in-memory database -- the deployed schema simply gone, with
# nothing raised.
#
# _exec_txn_rollback below closes the stray transaction itself (ADR 0005), so
# the engine argument for a 1 stands on its own: a failed apply rolls back
# whole AND the connection survives, and core's documented recovery -- re-run
# the upgrade, the diff is recomputed against live state -- works. The upstream
# STORE-branch fix (giterlizzi/perl-DBD-DuckDB#54) is still worth landing; the
# override is a no-op in behaviour once it is.
__PACKAGE__->_use_transactional_ddl(1);


sub sql_maker {
  my $self = shift;
  my $sm = $self->next::method(@_);
  $sm->{quote_char} //= $self->sql_quote_char;
  $sm->{name_sep}   //= $self->sql_name_sep;
  $sm;
}

sub _determine_supports_insert_returning { 1 }

# DBD::DuckDB 0.16's rollback issues ROLLBACK and then immediately reopens
# a transaction (BEGIN TRANSACTION), and the AutoCommit STORE branch that
# would close it again is unreachable code -- so after any txn_do that
# rolls back, DuckDB is still inside a transaction DBI believes is closed,
# and the next txn_begin dies (karr k15, ADR 0005). Close the orphan
# ourselves. The "no transaction is active" error is the expected outcome
# once DBD::DuckDB's STORE branch is fixed upstream -- swallow exactly
# that, so the normal rollback path is not broken.
sub _exec_txn_rollback {
  my $self = shift;
  $self->next::method(@_);
  try {
    $self->_dbh->do('ROLLBACK');
  }
  catch {
    die $_ unless $_ =~ /no transaction is active/i;
  };
}

sub _ping {
  my $self = shift;
  my $dbh = $self->_dbh or return undef;
  return undef unless $dbh->FETCH('Active');
  return try { $dbh->do('SELECT 1'); 1 } catch { undef };
}

# A DBD::DuckDB 0.16 statement handle cannot be used a second time, and DBI's
# statement cache exists to hand it out a second time (karr k33, ADR 0007).
# Three defects in DBD::DuckDB::st, independent of one another, measured on
# libduckdb v1.5.3, see docs/upstream/:
#
#   - finish deletes duckdb_stmt. The handle stays in CachedKids and
#     prepare_cached returns it dead: the second auto-increment insert, find
#     or single of one SQL shape dies in bind_param, and the second populate
#     -- core finishes after execute_for_fetch -- is a segmentation fault.
#   - execute never sets Active, so prepare_cached($sql, {}, 3) cannot see
#     that a handle is being read, and two open cursors of one SQL shape share
#     one handle.
#   - execute leaves duckdb_chunk and duckdb_chunk_row of the previous result
#     in place. A handle that was not read to its end goes on reading the OLD
#     chunk after the next execute: ->first for one value, then ->first for
#     another, answers the second row of the first search. No error.
#
# Core asks this accessor, in _prepare_sth, whether to prepare or to
# prepare_cached, so answering here covers every statement core prepares. It
# is a method and not a value set at construction for the sake of a schema
# that names no driver: its storage is configured as the generic
# DBIO::Storage::DBI and becomes this class on the first use of the handle,
# and connect_info resets every storage option on each call besides. A value
# would have to survive both; a method of the class has nothing to survive.
#
# Recognising dead handles as they come out of the cache (dbio-firebird's
# _sth_is_alive) would mend the first defect only. Unlike the statement
# release below this is not bound to a DBD::DuckDB version: not caching is
# correct against any release, and caching again is a decision to take once a
# release has been measured -- t/49-statement-reuse.t carries the sentinel.
sub disable_sth_caching { 1 }

# karr k43 (core k298, k307) -- which lowercase keys of a broker's answer are
# attributes of the DBD and may go to DBI->connect. DBI's own registry, which
# core asks, has no prefix for DBD::DuckDB (DBI->driver_prefix("DuckDB") is
# empty), though the DBD takes duckdb_* attributes. $driver is the DBD name off
# the DSN: any other one is core's to answer.
sub _dbd_attribute_prefixes {
  my ($self, $driver) = @_;

  return 'duckdb_' if defined $driver && $driver eq 'DuckDB';

  return $self->next::method($driver);
}

# DBD::DuckDB 0.16 never frees a prepared statement (karr k25). Its
# st::finish calls duckdb_destroy_prepare($stmt) with the handle BY VALUE,
# where the C function takes duckdb_prepared_statement* -- FFI::Platypus
# turns a non-reference argument for a pointer type into NULL, without a
# warning, and libduckdb does nothing on NULL. And there is no st::DESTROY,
# so a handle nobody called finish on -- every $dbh->do, every handle DBIO
# prepares for an update, a delete or a cursor -- is not even attempted. Each
# leaked statement keeps the database instance alive, so duckdb_close in
# disconnect cannot drop the last reference and the lock on the database file
# outlives the handle until the process exits. Measured on libduckdb v1.5.3,
# see docs/upstream/.
#
# So this storage frees them: a DBI per-handle callback on the statement
# handles of ITS OWN connection, before finish and before DESTROY. Nothing in
# the DBD::DuckDB namespace is touched and no other DuckDB handle in the
# process is affected.
#
# What keeps that from becoming a double free once upstream frees them too:
#
#   - it takes the pointer out of the handle BEFORE freeing it. DBI runs a
#     callback ahead of the method, so whatever DBD::DuckDB does afterwards
#     finds undef, which arrives in C as NULL (by value) or as a pointer to
#     NULL (by reference) -- libduckdb does nothing on either (measured).
#   - it is bound to the releases whose finish has been read. A newer
#     DBD::DuckDB is left alone until someone has looked at it;
#     t/47-disconnect-releases-file-lock.t goes red if that release still
#     leaks, and its TODO passes if it does not.
#
# It stands down in a forked child, as core does for the connection itself
# (_verify_pid): only the process that opened the database releases anything
# in it. One thing it cannot reach: with AutoCommit => 0, DBD::DuckDB runs
# BEGIN TRANSACTION inside DBI->connect, before there is a handle to install
# a callback on, and that one statement stays.
#
# The same finish has a second defect, and the same callback answers it (karr
# k38). It hands libduckdb the handle's result unconditionally --
#
#     my $res = delete $sth->{duckdb_res};
#     duckdb_destroy_result($res);
#
# -- and a handle has a result only once an execute has succeeded: execute
# stores it after the engine accepted the statement, finish deletes it. On a
# handle that was never executed, whose only executes were refused, or that
# was finished before, $res is undef, which reaches C as NULL, and
# duckdb_destroy_result(NULL) is a segmentation fault (measured). Core
# finishes the handle of a bulk insert whatever happened to it, so a populate
# in void context whose first row the engine refuses did not throw: it ended
# the process.
#
# So in front of finish, a handle without a result is given an empty one --
# a zeroed duckdb_result, which is the state duckdb_destroy_result itself
# leaves a result in and does nothing on (measured, any number of times).
# DBD::DuckDB's finish then runs as written. It is in the callback and not in
# an override of core's two bulk-insert methods because the defect is in
# finish and not in populate: this covers every finish on the connection,
# cleanup code after a refused execute in dbh_do included, where an override
# would cover the one caller and copy a hundred lines of core to do it.
#
# Not for DESTROY -- DBD::DuckDB 0.16 has none, a dropped handle touches no
# result -- and not under the pid check: an empty result frees nothing, and a
# forked child that finishes a handle it inherited would crash just the same.
# A release that guards its own finish gets no callback at all (the version
# bound above), and would find nothing wrong with an empty result if it did.
# t/51-finish-without-result.t carries the sentinel.
my $_STATEMENT_LEAK_READ_UP_TO = version->parse('0.16');

sub _run_connection_actions {
  my $self = shift;
  $self->_duckdb_release_statements($self->_dbh);
  $self->_duckdb_text_callbacks($self->_dbh);
  $self->_duckdb_exact_decimals;
  return $self->next::method(@_);
}

sub _duckdb_release_statements {
  my ($self, $dbh) = @_;

  return unless ($dbh->{Driver}{Name} // '') eq 'DuckDB';
  return if version->parse(DBD::DuckDB->VERSION) > $_STATEMENT_LEAK_READ_UP_TO;
  return if $dbh->{private_dbio_duckdb_statement_release};

  my $pid = $$;
  my $release = sub {
    my $sth = shift;
    return if $$ != $pid;
    my $stmt = $sth->{duckdb_stmt} or return;
    $sth->{duckdb_stmt} = undef;
    DBD::DuckDB::FFI::duckdb_destroy_prepare(\$stmt);
    return;
  };

  # finish only: something for it to destroy where the handle has no result.
  my $give_result = sub {
    my $sth = shift;
    $sth->{duckdb_res} //= DBD::DuckDB::FFI::Result->new;
    return;
  };

  my %before = (
    finish  => sub { $release->($_[0]); $give_result->($_[0]); return },
    DESTROY => $release,
  );

  # Chain in front of whatever the application installed, on a copy: the
  # hash it handed to connect may be shared between connections.
  my $callbacks = $dbh->{Callbacks} || {};
  my $child     = $callbacks->{ChildCallbacks} || {};
  my %ours;
  for my $method (qw/finish DESTROY/) {
    my $mine   = $before{$method};
    my $theirs = $child->{$method};
    $ours{$method} = $theirs
      ? sub { $mine->($_[0]); goto &$theirs }
      : sub { $mine->($_[0]); return };
  }

  $dbh->{Callbacks} = { %$callbacks, ChildCallbacks => { %$child, %ours } };
  $dbh->{private_dbio_duckdb_statement_release} = 1;

  return;
}

# DECIMAL, read back exact (karr k49, Bind conformance).
#
# DBD::DuckDB 0.16 reads a DECIMAL as its unscaled integer divided by 10**scale
# -- a perl double -- and prints that with sprintf("%.${scale}f"). A double holds
# 15 to 17 digits, so the 20-digit 1234567890123456.7890 of a numeric(20,4)
# comes back as 1234567890123456.7500: the stored value is right and the read
# invents the tail, with no error. Its HUGEINT reader, which a wide DECIMAL
# goes through, also subtracts 2**128 from every value whose upper word is odd
# (`$upper & (1 << 64)` is `$upper & 1`), so a numeric(20,4) above 2**64
# unscaled units reads wrong too.
#
# So the reader is replaced, once, by one that formats the unscaled integer as
# a string and puts the point in by hand; same output shape as before (scale
# digits, a sign only when negative). Only the readers of the 0.16 DBD that
# were read; a newer one is left alone. The replacement is of the DBD's
# private function, which is why it is bound to the version: 0.16 is the
# newest DBD::DuckDB there is, and the only one measured. t/58 holds the DBD's
# own misreading as a fact, in a child process that never loads this class, and
# goes red when a DBD reads these values right -- then this replacement goes.
my $_DECIMAL_READER_FIXED;

sub _duckdb_exact_decimals {
  return if $_DECIMAL_READER_FIXED;
  return unless DBD::DuckDB->can('VERSION');
  return if version->parse(DBD::DuckDB->VERSION) > $_STATEMENT_LEAK_READ_UP_TO;
  return unless defined &DBD::DuckDB::st::_vector_decimal;

  my %width = (
    DBD::DuckDB::Constants::DUCKDB_TYPE_SMALLINT() => [ 2, 's<' ],
    DBD::DuckDB::Constants::DUCKDB_TYPE_INTEGER()  => [ 4, 'l<' ],
    DBD::DuckDB::Constants::DUCKDB_TYPE_BIGINT()   => [ 8, 'q<' ],
  );
  my $hugeint = DBD::DuckDB::Constants::DUCKDB_TYPE_HUGEINT();

  my $original = \&DBD::DuckDB::st::_vector_decimal;
  no warnings 'redefine';
  *DBD::DuckDB::st::_vector_decimal = sub {
    my ($logical_type, $vector_data, $row_idx) = @_;

    my $scale = DBD::DuckDB::FFI::duckdb_decimal_scale($logical_type);
    my $type  = DBD::DuckDB::FFI::duckdb_decimal_internal_type($logical_type);

    my $unscaled;
    if (my $w = $width{$type}) {
      $unscaled = Math::BigInt->new(
        unpack $w->[1], FFI::Platypus::Buffer::buffer_to_scalar(
          $vector_data + $row_idx * $w->[0], $w->[0]
        )
      );
    }
    elsif ($type == $hugeint) {
      my ($lower, $upper) = unpack 'Q< q<',
        FFI::Platypus::Buffer::buffer_to_scalar($vector_data + $row_idx * 16, 16);
      $unscaled = Math::BigInt->new($upper)->blsft(64)->badd($lower);
    }
    else {
      goto &$original;
    }

    my $negative = $unscaled->is_neg;
    my $digits   = $unscaled->copy->babs->bstr;
    $digits = ('0' x ($scale + 1 - length $digits)) . $digits
      if length $digits <= $scale;
    substr($digits, length($digits) - $scale, 0, '.') if $scale;
    return ($negative ? '-' : '') . $digits;
  };

  $_DECIMAL_READER_FIXED = 1;
  return;
}

# Text in, text out; typed binds that stay typed (karr k49, Bind conformance).
#
# DBD::DuckDB 0.16 does three things to a string that lose it, none of them
# with an error:
#
#   - it writes a perl string to libduckdb as it sits in memory, so a string
#     with characters above 0x7f that perl holds as latin-1 ("\x{fc}" without
#     the utf8 flag) is invalid UTF-8 and the bind dies, and one perl holds
#     as UTF-8 only works by accident;
#   - it hands every VARCHAR back as the bytes libduckdb stores, never as
#     characters, so "\x{20ac}" comes back as three characters;
#   - bind_param takes its type from an attribute only for that one call:
#     execute(@bind), which is what execute_for_fetch -- a populate -- calls,
#     binds again without it, so a bytes value meant for a BLOB is sniffed
#     into a VARCHAR and refused.
#
# The callbacks below sit in front of bind_param and the fetch methods of every
# statement of this connection. bind_param remembers a bind type per parameter
# and applies it to a later bind without one, and encodes a text value as UTF-8
# before the DBD sees it (a copy: the application's variable is never touched);
# a fetch decodes the VARCHAR and ENUM columns of the row it returns, in place,
# so a bound column (bind_columns) sees characters as well. BLOB columns are
# left as bytes. Both run the DBD's own method with the callbacks standing down and
# replace the dispatch (undef $_), so nothing runs twice. Bound to DBD::DuckDB <= 0.16 like
# the statement release above.
sub _duckdb_text_callbacks {
  my ($self, $dbh) = @_;

  return unless ($dbh->{Driver}{Name} // '') eq 'DuckDB';
  return if version->parse(DBD::DuckDB->VERSION) > $_STATEMENT_LEAK_READ_UP_TO;
  return if $dbh->{private_dbio_duckdb_text_callbacks};

  # the method itself, run again through dispatch with our callbacks standing
  # down (the flag), and the dispatch of the original call replaced by its
  # result
  my $plain = sub {
    my ($sth, $method, @args) = @_;
    my ($ok, @result);
    my $error;
    $sth->{private_dbio_duckdb_in_callback} = 1;
    {
      local $@;
      $ok = eval { @result = $sth->$method(@args); 1 };
      $error = $@ unless $ok;
    }
    $sth->{private_dbio_duckdb_in_callback} = 0;
    die $error unless $ok;
    undef $_;
    return $result[0];
  };

  my $bind_param = sub {
    my ($sth, $i, $value, $attr) = @_;
    return if $sth->{private_dbio_duckdb_in_callback};
    my $types = $sth->{private_dbio_duckdb_bind_types} ||= {};
    if (defined $attr and not ref $attr) {
      $types->{$i} = $attr;
    }
    elsif (not defined $attr and defined $types->{$i}) {
      $attr = $types->{$i};
    }
    if (defined $value and not ref $value
        and (not defined $attr or ref $attr or $attr != DBI::SQL_BLOB())
        and $value =~ /[^\x00-\x7f]/) {
      utf8::encode($value);
    }
    return $plain->($sth, 'bind_param', $i, $value, $attr);
  };

  my $fetch = sub {
    my $sth = $_[0];
    return if $sth->{private_dbio_duckdb_in_callback};
    my $row = $plain->($sth, 'fetchrow_arrayref');
    return $row unless $row;

    my $logical = $sth->{duckdb_col_logical_types} or return $row;
    my $cache   = $sth->{private_dbio_duckdb_text_columns};
    unless ($cache and $cache->[0] == $logical) {
      my @text = grep {
        my $id = DBD::DuckDB::FFI::duckdb_get_type_id($logical->[$_]);
        $id == DBD::DuckDB::Constants::DUCKDB_TYPE_VARCHAR()
          or $id == DBD::DuckDB::Constants::DUCKDB_TYPE_ENUM()
      } 0 .. $#$logical;
      $cache = $sth->{private_dbio_duckdb_text_columns} = [ $logical, \@text ];
    }
    for my $c (@{ $cache->[1] }) {
      utf8::decode($row->[$c])
        if defined $row->[$c] and not utf8::is_utf8($row->[$c]);
    }
    return $row;
  };

  my %ours = (
    bind_param       => $bind_param,
    fetch            => $fetch,
    fetchrow_arrayref => $fetch,
  );

  my $callbacks = $dbh->{Callbacks} || {};
  my $child     = $callbacks->{ChildCallbacks} || {};
  my %chained;
  for my $method (keys %ours) {
    my $mine   = $ours{$method};
    my $theirs = $child->{$method};
    $chained{$method} = $theirs
      ? sub { my $r = $theirs->(@_); defined $_ ? $mine->(@_) : $r }
      : $mine;
  }

  $dbh->{Callbacks} = { %$callbacks, ChildCallbacks => { %$child, %chained } };
  $dbh->{private_dbio_duckdb_text_callbacks} = 1;

  return;
}


sub _mask_error_values {
  my ($self, $text, $values, $statement) = @_;
  return $text unless defined $text and !ref $text;

  # a non-ASCII value reaches the engine as UTF-8 bytes and comes back in its
  # text in that form, which core's net (the value as written) does not look for
  $values = [ map {
    my $v = $_;
    (defined $v && !ref $v && $v =~ /[^\x00-\x7f]/ && utf8::is_utf8($v))
      ? ($v, do { my $b = $v; utf8::encode($b); $b })
      : $v;
  } @{ $values // [] } ];

  my ($head, $tail) = DBIO::DuckDB::Util::_split_excerpt($text, $statement);
  $head = DBIO::DuckDB::Util::mask_error_details($head, $values);
  return $self->next::method($head, $values, $statement) . $tail;
}


sub duckdb_appender {
  my ($self, $table, $schema) = @_;
  $self->throw_exception('Usage: $storage->duckdb_appender($table [, $schema])') unless $table;
  return $self->_get_dbh->x_duckdb_appender($table, $schema);
}


sub duckdb_arrow_fetch {
  my ($self, $sql, $binds) = @_;
  $self->throw_exception('Usage: $storage->duckdb_arrow_fetch($sql [, \@binds])')
    unless defined $sql and length $sql;
  my $dbh = $self->_get_dbh;
  return try {
    # loaded here, not at the top: the module binds libduckdb's Arrow
    # functions when it loads, and a missing library is an exception of this
    # method, not a storage class that does not load
    require DBIO::DuckDB::Arrow;
    DBIO::DuckDB::Arrow->fetch($dbh, $sql, $binds // [],
      sub { $self->_mask_error_values($_[0], $binds // [], $sql) });
  }
  catch {
    $self->throw_exception("$_");
  };
}


sub duckdb_read_csv {
  my ($self, $path, $opts) = @_;
  $self->throw_exception('Usage: $storage->duckdb_read_csv($path [, \%opts])') unless $path;
  my $sth = $self->_get_dbh->x_duckdb_read_csv($path, $opts // {});
  my @rows;
  while (my $row = $sth->fetchrow_hashref) { push @rows, { %$row } }
  return \@rows;
}


sub duckdb_read_parquet {
  my ($self, $path) = @_;
  $self->throw_exception('Usage: $storage->duckdb_read_parquet($path)') unless $path;
  return $self->_get_dbh->selectall_arrayref(
    'SELECT * FROM read_parquet(?)',
    { Slice => {} },
    $path,
  );
}


sub duckdb_read_json {
  my ($self, $path, $opts) = @_;
  $self->throw_exception('Usage: $storage->duckdb_read_json($path [, \%opts])') unless $path;
  my $sth = $self->_get_dbh->x_duckdb_read_json($path, $opts // {});
  my @rows;
  while (my $row = $sth->fetchrow_hashref) { push @rows, { %$row } }
  return \@rows;
}


sub duckdb_version {
  my $self = shift;
  return $self->_get_dbh->x_duckdb_version;
}


sub duckdb_install_extension {
  my ($self, $name, %opts) = @_;
  $self->throw_exception('extension name required') unless $name;
  $name =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/
    or $self->throw_exception("invalid extension name: $name");
  my $dbh = $self->_get_dbh;
  $dbh->do("INSTALL $name");
  $dbh->do("LOAD $name") if $opts{load};
  return 1;
}


sub _extension_activation {
  my ($self, $name) = @_;
  my $none = { load => [], search_path => [] };

  my $list = DBIO::DuckDB::Extension->resolve_list($self->schema)
    or return $none;

  return DBIO::Extension::Protocol->new(
    entries           => [ $list->entries ],
    driver            => {},
    connection_schema => $name,
    restricted        => 0,
  )->activation;
}


sub _activate_extensions {
  my ($self, $activation) = @_;
  $self->_do_query($_) for $self->_extension_activation_sql($activation);
  return $self;
}


sub _extension_activation_sql {
  my ($self, $activation) = @_;

  $self->throw_exception('DuckDB extensions have no search_path; an extension asked for '
    . join(', ', @{ $activation->{search_path} }))
    if @{ $activation->{search_path} || [] };

  my @sql;
  for my $name (@{ $activation->{load} || [] }) {
    $name =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/
      or $self->throw_exception("invalid extension name: $name");
    push @sql, "INSTALL $name", "LOAD $name";
  }
  return @sql;
}


sub duckdb_checkpoint {
  my $self = shift;
  $self->_get_dbh->do('CHECKPOINT');
  return 1;
}


sub quack_serve {
  my ($self, $addr, %opts) = @_;
  $addr //= 'quack:localhost';
  _validate_quack_addr($self, $addr);

  $self->duckdb_install_extension('quack', load => 1);

  my $dbh = $self->_get_dbh;

  if (defined $opts{token}) {
    _validate_quack_token($self, $opts{token});
    my $token = $opts{token};
    my $tok_lit = $opts{token};
    $tok_lit =~ s/'/''/g;
    my $addr_lit = $addr;
    $addr_lit =~ s/'/''/g;
    $dbh->do("CALL quack_serve('$addr_lit', token => '$tok_lit')");
  }
  else {
    my $addr_lit = $addr;
    $addr_lit =~ s/'/''/g;
    $dbh->do("CALL quack_serve('$addr_lit')");
  }

  return 1;
}


sub quack_attach {
  my ($self, $addr, %opts) = @_;
  $self->throw_exception('Usage: $storage->quack_attach($addr, as => $name, ...)') unless $addr;
  _validate_quack_addr($self, $addr);

  my $as = $opts{as}
    or $self->throw_exception('quack_attach: "as" option (catalog alias) is required');
  $as =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/
    or $self->throw_exception("quack_attach: invalid catalog alias '$as'");

  $self->duckdb_install_extension('quack', load => 1);

  my $addr_lit = $addr;
  $addr_lit =~ s/'/''/g;
  my $attach_sql = "ATTACH '$addr_lit' AS $as";
  $attach_sql .= ' (READ_ONLY)' if $opts{read_only};

  if (defined $opts{token}) {
    _validate_quack_token($self, $opts{token});
    my $tok_lit = $opts{token};
    $tok_lit =~ s/'/''/g;
    my $secret = _quack_secret_name($self, $as);

    # One transaction, because DuckDB's secret store is transactional and a
    # leftover is not harmless: of two secrets with the same scope the name
    # that sorts first wins, so the secret of a failed attach would shadow
    # the token of a later alias for the same address. The rollback also
    # puts back a secret this CREATE OR REPLACE overwrote (karr k32).
    #
    # DuckDB quotes the failed statement in its error text, and the CREATE
    # SECRET one holds the token (a NUL in it fails the parse, and the parser
    # repeats it): the token goes through mask_connect_secrets as the
    # password of the connect info (karr k42).
    try {
      $self->txn_do(sub {
        my $dbh = $self->_get_dbh;
        $dbh->do("CREATE OR REPLACE SECRET $secret (TYPE quack, TOKEN '$tok_lit', SCOPE '$addr_lit')");
        $dbh->do($attach_sql);
      });
    }
    catch {
      my $msg = mask_connect_secrets("$_", [ undef, undef, $opts{token}, {} ]);
      $msg .= "\n" unless $msg =~ /\n\z/;
      die $msg;
    };
  }
  else {
    $self->_get_dbh->do($attach_sql);
  }

  return 1;
}


sub quack_detach {
  my ($self, $name) = @_;
  $self->throw_exception('Usage: $storage->quack_detach($name)') unless defined $name;
  $name =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/
    or $self->throw_exception("quack_detach: invalid catalog name '$name'");
  my $dbh = $self->_get_dbh;
  # Cleaning up wins over the DETACH result: the DROP runs even when the
  # DETACH died, and the DETACH error is the one reported, also when the
  # DROP dies too (karr k36).
  my $detached = eval { $dbh->do("DETACH $name"); 1 };
  my $detach_error = $@;
  my $dropped = eval {
    $dbh->do('DROP SECRET IF EXISTS ' . _quack_secret_name($self, $name));
    1;
  };
  my $drop_error = $@;
  die $detach_error unless $detached;
  die $drop_error unless $dropped;
  return 1;
}


sub connect_call_quack_attach {
  my ($self, $args) = @_;
  $self->throw_exception('connect_call_quack_attach: hashref argument required')
    unless ref $args eq 'HASH';
  my $addr = $args->{addr}
    or $self->throw_exception('connect_call_quack_attach: "addr" required in args hashref');
  return $self->quack_attach($addr, %{ $args }{ grep { $_ ne 'addr' } keys %$args });
}

# ---- private helpers ----

sub _validate_quack_addr {
  my ($self, $addr) = @_;
  $addr =~ /^quack:/
    or $self->throw_exception(
      "quack address must start with 'quack:' (got: " . mask_connect_secrets($addr) . ')'
    );
  $addr =~ /'/
    and $self->throw_exception("quack address must not contain single quotes");
  $addr =~ /\n/
    and $self->throw_exception("quack address must not contain newlines");
  return 1;
}

sub _validate_quack_token {
  my ($self, $tok) = @_;
  $tok =~ /\n/
    and $self->throw_exception("quack token must not contain newlines");
  return 1;
}

# Name of the secret quack_attach creates for an alias and quack_detach
# drops again. Both validate the alias as an identifier before asking.
sub _quack_secret_name {
  my ($self, $alias) = @_;
  return "dbio_quack_$alias";
}


# Types a double cannot represent exactly, keyed by the lower-cased data_type
# with any size/precision suffix removed (so 'decimal(38,10)' arrives here as
# 'decimal'). Spellings cover both what DBIO::DuckDB::DDL accepts and what
# DuckDB itself reports back through introspection.
my %_BIND_AS_STRING = map { $_ => 1 } qw(
  bigint  bigserial  int8  int64  long
  ubigint  uint64
  hugeint  uhugeint  int128  uint128
  varint  bignum
  decimal  numeric  dec  money
);

# Text and binary columns: DBD::DuckDB sniffs a value that looks like a number
# or a boolean ('01234', '5.0', '1') and binds it as one, so a text column hands
# back 1234.0 for '01234' and a comparison fails with a conversion error; a
# value with a NUL or a byte string fails to bind as text. The column's own
# type decides instead (karr k49, Bind conformance).
my %_BIND_AS_TEXT = map { $_ => 1 } qw(
  varchar  char  bpchar  text  string  nvarchar  nchar  clob  json
);
my %_BIND_AS_BLOB = map { $_ => 1 } qw(
  blob  bytea  binary  varbinary  longblob  mediumblob  tinyblob
);

sub bind_attribute_by_data_type {
  my ($self, $data_type) = @_;

  return undef unless defined $data_type;

  (my $type = lc $data_type) =~ s/\(.*//s;
  $type =~ s/\A\s+//;
  $type =~ s/\s+\z//;

  return DBI::SQL_BIGINT()  if $_BIND_AS_STRING{$type};
  return DBI::SQL_VARCHAR() if $_BIND_AS_TEXT{$type};
  return DBI::SQL_BLOB()    if $_BIND_AS_BLOB{$type};
  return undef;
}


sub _get_server_version {
  my $self = shift;

  my $version = $self->next::method(@_);

  $version =~ s/^v(?=[0-9])// if defined $version;

  return $version;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::Storage - DuckDB storage driver for DBIO

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

DuckDB storage driver for DBIO. Extends L<DBIO::Storage::DBI> with
DuckDB-specific behavior and escape-hatch methods for DuckDB-native
features that do not fit the row-oriented DBI model.

Sits on top of L<DBD::DuckDB>, a pure-FFI DBI driver. No XS compile,
C<libduckdb> must be installed at runtime.

Registered as the driver for C<DuckDB> and loaded automatically when
connecting to a C<dbi:DuckDB:*> DSN.

=head1 METHODS

=head2 _mask_error_values

    my $text = $storage->_mask_error_values($text, \@values, $statement);

Core's seam for the text an engine writes into an error (ADR 0075), with what
DuckDB adds to it. DuckDB writes the offending value into the error, also when
it was a bind -- C<Could not convert string 'x' to INT32>, C<Duplicate key
"email: x" violates unique constraint.> -- and a message names keys, columns
and options, never values. What the caller needs stays: the type, the column,
the constraint, the table.

The C<LINE 1: ...> excerpt DuckDB appends is the caller's statement and stays
as it is, when it is DuckDB's own -- the end of the text, a piece of a line of
C<$statement>, the caret line. The text before it passes
L<DBIO::DuckDB::Util/mask_error_details> (the sentences of the engine, and the
bound values where a key is ambiguous) and then core's masking of the bound
values (each value of four characters or more, as written and as the handle
quotes it); the excerpt is put back untouched, so a bound value like C<INSERT>
does not change it. A text with something that only looks like the excerpt (a
bound value can) is masked whole.

Core hands in the values bound to the statement for every text that reaches an
exception, so the masking does not depend on the DBD::DuckDB version or on the
statement handle callbacks (L</DISCONNECT AND THE DATABASE FILE>). The
appender (C<append_row>, C<flush>, C<close>) has no bound values: its text is
masked by the sentences alone.
The Arrow path (L</duckdb_arrow_fetch>) masks its engine errors through this
method with its binds. DuckDB reports no constraint, table or detail of its
own, so C<_dbi_error_fields> stays core's.

=head2 duckdb_appender

    my $appender = $storage->duckdb_appender($table);
    my $appender = $storage->duckdb_appender($table, $schema);

Returns a L<DBD::DuckDB::Appender> bound to C<$table> (optionally
qualified with C<$schema>, default C<main>). The Appender is DuckDB's
native bulk-insert API -- dramatically faster than row-by-row INSERT
for loading large batches.

    my $app = $storage->duckdb_appender('events');
    for my $event (@events) {
        $app->append_row(
            id   => $event->{id},
            name => $event->{name},
            ts   => $event->{ts},
        );
    }
    $app->flush;

Uses L<DBD::DuckDB/x_duckdb_appender> under the hood.

=head2 duckdb_arrow_fetch

    my $t = $storage->duckdb_arrow_fetch($sql, \@binds);
    # $t->{names}    [ 'decade', 'n' ]
    # $t->{formats}  [ 'i', 'l' ]
    # $t->{columns}  [ [ 1970, 1980 ], [ 200, 310 ] ]
    # $t->{rows}     2

Runs C<$sql> with C<@binds> and reads the result through libduckdb's Arrow
interface (C<duckdb_data_chunk_to_arrow>), block by block and column by
column, without DBI's row iterator. The answer is columnar:

=over 4

=item C<names>

The column names, in the order of the result. Columns are told apart by
position, since a result may have two columns of one name.

=item C<formats>

The Arrow format string of each column, as libduckdb reports it (C<i>
INTEGER, C<l> BIGINT, C<g> DOUBLE, C<u> VARCHAR, C<+l> LIST, ...).

=item C<columns>

One array reference of values per column, in the same order. Every column
holds C<rows> values; NULL is C<undef>.

=item C<rows>

The number of rows.

=back

An empty result has C<names> and C<formats>, an empty array in every column
and C<rows> 0.

The values are those a C<selectall_arrayref> of the same statement returns,
laid on their side: integers and floats as numbers, HUGEINT and DECIMAL as
exact decimal strings with the scale of the column, text as characters (UTF-8
decoded), BLOB as bytes, a LIST and an ARRAY as an array reference, a STRUCT
as a hash reference, a MAP as a hash reference of its pairs, an ENUM as its
text. Text inside LIST, STRUCT and MAP is decoded to characters as well.

DATE, TIME, TIMESTAMP (every unit) and INTERVAL are DuckDB's own text, exactly
what C<CAST(v AS VARCHAR)> returns: the fraction is padded to the precision of
the type and loses its trailing zeros (C<11:30:00.12>, C<11:30:00.000005>),
years up to 0 are written as C<0044-03-15 (BC)> with the year counted as
C<1 - year> (in a timestamp C<(BC)> stands between date and time:
C<0044-03-15 (BC) 12:00:00.5>), an infinite value is C<infinity> or
C<-infinity>, and an INTERVAL carries its sign and time part
(C<1 day 03:00:00>). The row path of L<DBD::DuckDB> 0.16 differs in the
fraction, the BC years, INTERVAL (the time part is left out) and infinity (the
far dates C<5881580-07-11> and C<294247-01-10 04:00:54.775807>).

TIMESTAMP WITH TIME ZONE is in UTC, as C<CAST(v AS VARCHAR)> has it under
C<SET TimeZone = 'UTC'> (C<2026-10-31 01:02:03+00>), whatever the zone of the
session is; this is the one place where the values differ from the row path
on purpose.

The buffers of a block are read once per column.

A result that holds a type the decoder does not render -- UNION, BIT, BIGNUM,
TIME WITH TIME ZONE, in a column of their own or inside a LIST, ARRAY, STRUCT
or MAP, and a MAP whose key is a LIST, ARRAY, STRUCT or MAP (a hash has text
keys) -- throws before the first row is read. The exception names the column
and the Arrow format, never a value. A statement the engine refuses throws its
error. The statement and everything libduckdb handed out for the Arrow
conversion are released on every way out, so the connection stays usable and a
disconnect gives the database file back.

=head2 duckdb_read_csv

    my $rs = $storage->duckdb_read_csv('/path/to/file.csv', \%opts);

Wraps DuckDB's C<read_csv> table function. Returns an arrayref of row
hashrefs. C<%opts> is passed through to
L<DBD::DuckDB/x_duckdb_read_csv>.

=head2 duckdb_read_parquet

    my $rs = $storage->duckdb_read_parquet('/path/to/file.parquet');

Runs C<SELECT * FROM read_parquet(?)> against DuckDB. Returns an arrayref
of row hashrefs. Requires DuckDB's C<parquet> extension (bundled with
most builds).

=head2 duckdb_read_json

    my $rs = $storage->duckdb_read_json('/path/to/file.json', \%opts);

Wraps DuckDB's C<read_json> table function via
L<DBD::DuckDB/x_duckdb_read_json>.

=head2 duckdb_version

    my $v = $storage->duckdb_version;

Returns the linked libduckdb version string (e.g. C<v1.0.0>).

=head2 duckdb_install_extension

    $storage->duckdb_install_extension('httpfs');
    $storage->duckdb_install_extension('httpfs', load => 1);

Runs C<INSTALL $name>. With C<< load => 1 >> also runs C<LOAD $name>.

=head2 _extension_activation

    my $activation = $storage->_extension_activation($namespace);

What the declared extensions want of a new connection (ADR 0066, activation),
merged by core in the name order of the extensions
(L<DBIO::Extension::Protocol/activation>): C<< { load => [ ... ],
search_path => [ ... ] } >>. The classes are resolved and their driver
assertion is checked (L<DBIO::DuckDB::Extension/resolve_list>). A schema that
declares no extension has an empty activation and nothing is loaded.

=head2 _activate_extensions

    $storage->_activate_extensions($activation);

Writes the activation of L</_extension_activation> as statements: for every
library of C<load>, C<INSTALL name> and then C<LOAD name>, through
C<_do_query>. C<INSTALL> of an installed extension does nothing (measured), so
the same statements run on every connection; an extension DuckDB does not have,
or cannot fetch, is an error and the connect fails with it. DuckDB has no
C<search_path> of extensions; an entry there is refused. The name is checked as
in L</duckdb_install_extension>.

=head2 _extension_activation_sql

    my @sql = $storage->_extension_activation_sql($activation);

The statements of L</_activate_extensions> without running them, for a caller
that runs them on a connection of its own (the throwaway target database of
L<DBIO::DuckDB::Deploy/_build_target_model>).

=head2 duckdb_checkpoint

    $storage->duckdb_checkpoint;

Issues a C<CHECKPOINT> to flush the WAL and compact storage.

=head2 quack_serve

    $storage->quack_serve('quack:localhost:9500');
    $storage->quack_serve('quack:localhost:9500', token => 'my-secret');

Loads the quack extension (C<INSTALL quack; LOAD quack>) then starts a
Quack server on the given C<$addr>. The server continues to serve the
current database until the process exits or the connection is closed.

C<$addr> must start with C<quack:> and must not contain single quotes or
newlines. C<token> is optional; when given it is embedded as a SQL
string literal (single quotes escaped).

Returns 1 on success. Throws a L<DBIO::Exception> on validation failure or SQL error.

=head2 quack_attach

    $storage->quack_attach('quack:localhost:9500', as => 'remote');
    $storage->quack_attach('quack:localhost:9500',
        as        => 'remote',
        token     => 'my-secret',
        read_only => 1,
    );

Loads quack, then C<ATTACH>es the remote Quack server as a named catalog.

C<as> is required and must be a valid SQL identifier
(C<\A[A-Za-z_][A-Za-z0-9_]*\z>). C<$addr> must start with C<quack:> and
contain no single quotes or newlines. C<read_only> attaches the catalog
in read-only mode.

With C<token>, the token goes into a temporary DuckDB secret of its own,
named C<dbio_quack_E<lt>aliasE<gt>> after the C<as> alias and scoped to
C<$addr>:

    CREATE OR REPLACE SECRET dbio_quack_remote
        (TYPE quack, TOKEN '...', SCOPE 'quack:localhost:9500')

So several Quack servers, each with its own token, attach to one
connection, and L</quack_detach> drops the secret of its alias again.
Without C<token> no secret is created or touched -- a C<TYPE quack> secret
you created yourself is picked up by DuckDB as usual.

The secret and the C<ATTACH> run as one transaction
(L<DBIO::Storage/txn_do>). When the C<ATTACH> fails -- token rejected,
server unreachable, alias still attached -- DuckDB's exception is rethrown
and the secret store is as it was before the call: nothing is left behind,
and a secret that already existed under that name (the alias is still
attached) keeps its token. Called inside a transaction of your own, a
failed C<ATTACH> aborts that transaction -- DuckDB answers every further
statement with C<Current transaction is aborted> until it is rolled back --
and its rollback restores the secrets the same way.

Two limits of DuckDB's secret lookup, measured on libduckdb 1.5.3:

=over 4

=item *

B<A scope is a prefix, not an exact address.> The secret whose scope is
the longest prefix of the address wins, and a scoped secret beats an
unscoped one. The token for C<quack:localhost:95> is therefore also
offered to C<quack:localhost:9511> as long as that address has no secret
of its own. Still far narrower than an unscoped secret, which is sent to
every Quack address.

=item *

B<Two secrets with the same scope are not ambiguous to DuckDB:> the name
that sorts first wins, whichever was created last. Two aliases for one
address should carry the same token.

=back

What the attached catalog shows, measured on libduckdb 1.5.3
(C<t/63-quack-client-catalog.t>; behaviour of the extension, not of this
driver):

=over 4

=item *

B<Tables the server creates after the ATTACH are invisible to the client>
("Table with name ... does not exist"), even on the first query and with the
secret intact. The client's catalog is a snapshot taken at attach time; rows
of tables that were there are read live. Detach and attach again
(L</quack_detach>, then C<quack_attach>) takes a new snapshot, and so does
attaching a second alias.

=item *

B<The database listings throw.> C<duckdb_databases()>,
C<PRAGMA database_list> and C<SHOW DATABASES> fail with "InMemory not
implemented yet" as long as a Quack catalog is attached. To test whether an
alias is attached, use C<information_schema.schemata> (C<catalog_name>) or
C<duckdb_schemas()> (C<database_name>), which do list it.
C<information_schema.tables> and C<duckdb_tables()> list none of its tables.

=back

Returns 1 on success.

=head2 quack_detach

    $storage->quack_detach('remote');

Detaches a previously attached Quack (or any) catalog by name, then drops
the secret L</quack_attach> created for that alias, if there is one
(C<DROP SECRET IF EXISTS dbio_quack_E<lt>nameE<gt>>). Secrets of other
aliases and secrets you created yourself stay. Name must be a valid SQL
identifier.

The drop also runs when the C<DETACH> fails (an alias that is not
attached, say), so a secret left behind is cleaned up by calling this
again. The C<DETACH> error is then thrown after the drop; if the drop
fails as well, the C<DETACH> error is still the one thrown.

Nothing here needs the quack extension, so this also detaches a file or
in-memory catalog on a connection that never loaded it.

Inside a transaction that is rolled back afterwards, DuckDB restores the
dropped secret but not the attachment -- C<DETACH> is not undone. Calling
C<quack_detach> for that alias again throws the C<DETACH> error (the alias
is gone) and drops the restored secret.

Returns 1 on success.

=head2 connect_call_quack_attach

    on_connect_call => [[ quack_attach => {
        addr      => 'quack:localhost:9500',
        as        => 'remote',
        token     => 'my-secret',
        read_only => 0,
    }]]

On-connect hook that calls L</quack_attach> with the supplied hashref.
Use via C<on_connect_call> in the connection options to auto-attach a
Quack server whenever the storage connects.

C<addr> and C<as> are required in the hashref. C<token> and C<read_only>
are optional. See L</quack_attach> for validation rules.

=head2 bind_attribute_by_data_type

    my $attr = $storage->bind_attribute_by_data_type($data_type);

Returns C<DBI::SQL_BIGINT> for the numeric types whose values a C double
cannot carry exactly -- C<bigint>, C<ubigint>, C<hugeint>, C<uhugeint>,
C<int128>, C<varint>, C<decimal> / C<numeric> and C<money>, plus the alias
spellings of those this driver accepts (C<int8>, C<int64>, C<long>,
C<bigserial>, C<uint64>, C<uint128>, C<bignum>, C<dec>). A size or precision
suffix is ignored, so C<decimal(38,10)> is recognised as C<decimal>. Returns
undef for everything else, including C<integer> and narrower.

B<Why an override is needed at all.> DBD::DuckDB chooses the libduckdb bind
function from the I<value> when no DBI bind attribute is supplied, and every
scalar that looks like a number takes its C<duckdb_bind_double> branch. On
libduckdb v1.5.3 / DBD::DuckDB 0.16 that means C<< SELECT typeof(?) >> with a
plain C<3> answers C<DOUBLE>, and inserting C<9007199254740993> into a BIGINT
column stores C<9007199254740992> -- silently, no warning, no error. Two
adjacent BIGINT keys past 2^53 collapse onto one double, so a later
C<< $rs->find($key) >> can answer with the wrong row. DECIMAL loses its tail
the same way; HUGEINT and UBIGINT past the int64 range fail outright with a
conversion error.

B<Why C<SQL_BIGINT> rather than C<SQL_INTEGER>.> DBD::DuckDB's C<bind_param>
offers exactly two useful branches: C<SQL_INTEGER> binds through
C<duckdb_bind_int64>, anything else falls through to C<duckdb_bind_varchar>
and lets DuckDB cast the string to the parameter's own type -- exactly, at any
width. The int64 branch cannot carry the wide types (2^127-1 arrives as C<-1>,
silently) and truncates DECIMAL, and because it runs the value through perl's
C<int()> it would turn a non-numeric bind into a stored C<0> where DuckDB
currently raises. The string route keeps every one of those failures loud.

B<What that route costs, and the workaround.> A parameter DuckDB cannot type
from its context arrives as C<STRING_LITERAL>, and a few operator overloads
are then ambiguous: measured on 1.5.3, C<< bigint_col * ? >> and
C<< decimal_col * ? >> inside a literal-with-bind expression raise
C<Binder Error: Could not choose a best candidate function>. It is a loud,
immediate failure with a local fix -- cast in the SQL
(C<< \[ 'b * CAST(? AS BIGINT)', [ b => 2 ] ] >>) or bypass this method with
an explicit C<dbd_attrs> bind attribute.

B<Why the integer family is deliberately excluded.> Every value an INTEGER or
narrower column can hold is already exact in a double, so those types have
nothing to gain -- while C<< integer_col + ? >> I<is> one of the ambiguous
overloads (C<+(INTEGER, STRING_LITERAL)> collides with C<+(INTEGER, DATE)>),
which would break the counter-increment idiom
C<< \[ 'n + ?', [ n => 1 ] ] >>. The one thing they forgo is the plan-shape
win: an unattributed bind makes DuckDB widen the I<column> to meet the
parameter (C<< CAST(id AS DOUBLE) = 3.0 >>), and a cast on the column side
disables zone-map pruning. The types listed above no longer pay that; INTEGER
columns still do.

=head2 _get_server_version

The engine version, with DuckDB's leading C<v> taken off.

libduckdb spells its own version C<v1.5.3>: that is what
C<duckdb_library_version()> answers, and DBD::DuckDB hands the string through
unchanged for C<SQL_DBMS_VER> -- C<DBD::DuckDB::GetInfo::sql_dbms_ver> is a
C<FETCH> of C<duckdb_version>. Core's normaliser in
L<DBIO::Storage::DBI/_server_info> reads the number off the B<front> of that
string:

  my ($numeric_version) = $server_version =~ /^([\d\.]+)/;
  my @verparts = split (/\./, $numeric_version);

The C<v> sits in front of the anchor, so the match fails, and two things
follow. Every call warns C<Use of uninitialized value $numeric_version in
split>; and -- the half that makes no noise -- C<normalized_dbms_version> is
never set, so anything gating a feature on the engine version reads C<undef>
and decides wrong.

That regex is right for the rest of the family, which answers with a bare
number. DuckDB is the odd one out, and C<_get_server_version> is the seam
provided for exactly that, so the correction lives here rather than in the
shared normaliser.

B<Only the leading C<v> goes.> C<duckdb.h> documents
C<duckdb_library_version()> as returning "the version of the linked DuckDB,
with a version postfix for dev versions", and no dev build was available to
measure that postfix's shape, so nothing behind the C<v> is touched: core's
own regex decides where the number ends, as it already does for
L<DBIO::MySQL::Storage>'s C<11.8.8-MariaDB-ubu2404>.

What this hook returns B<is> what core stores in C<dbms_version> --
C<_server_info> keeps no second, rawer slot -- so C<dbms_version> reads
C<1.5.3> on this driver. DuckDB's own spelling stays reachable, verbatim and
unnormalised, through L</duckdb_version>. Pinned in
F<t/46-server-version.t>.

=head1 CAPABILITIES

=head2 supports_exists_query

Declared true. L<DBIO::ResultSet/results_exist> and its two siblings probe
this capability and throw without it (ADR 0037), so the declaration is what
makes them usable on DuckDB at all.

This driver does B<not> override
L<DBIO::Storage::DBI/_exists_value_sql>: core's base rendering,

  SELECT CASE WHEN EXISTS <inner> THEN 1 ELSE 0 END

is already valid DuckDB. That form makes three portability assumptions, and
DuckDB's documentation covers all three:

=over 4

=item * B<C<EXISTS> as a boolean value expression>, not merely as a
predicate. The SQL dialect reference documents C<EXISTS> as returning
"either true when the subquery returns one or more records, and false
otherwise", and its own example selects that value directly --
C<< SELECT EXISTS (FROM grades WHERE course = 'Math') AS math_grades_present; >>
(L<https://duckdb.org/docs/stable/sql/expressions/subqueries>).

=item * B<A C<SELECT> with no C<FROM> clause.> The same documented example
is exactly that: a complete statement whose outer query has no C<FROM>.
DuckDB treats the C<FROM> clause as optional in both directions -- it also
allows the converse, a C<FROM> with no C<SELECT>
(L<https://duckdb.org/docs/stable/sql/query_syntax/from>).

=item * B<A boolean as the C<WHEN> condition of a C<CASE>.> C<CASE WHEN cond
THEN a ELSE b END> is documented as "identical to the ternary condition used
in many programming languages", i.e. C<cond> is any boolean-valued
expression, which is what C<EXISTS> yields
(L<https://duckdb.org/docs/stable/sql/expressions/case>).

=back

The third assumption ADR 0037 catalogued -- C<AS> before a derived-table
alias -- no longer applies to anyone: core dropped the
C<SELECT * FROM ( ... ) AS _existence_subq> wrapper when it introduced this
hook. It was never a DuckDB problem, but the statement is now one DuckDB
accepts B<and> shorter.

Note that the base rendering also settles the boolean-transport footgun ADR
0037 describes: the statement yields an integer C<1>/C<0> rather than an
engine boolean, so no DBD-level true/false spelling can be misread.

=head2 transactional_ddl

Declared B<true>, and unlike every other C<1> in this family that is not a
statement about the engine. DuckDB has transactional DDL: C<CREATE> /
C<DROP> / C<ALTER TABLE>, C<CREATE INDEX>, C<CREATE SEQUENCE> and
C<CREATE VIEW> all roll back inside an ordinary transaction, and this
driver's own install batch commits as one unit.

The blocker used to be underneath, in L<DBD::DuckDB>: its C<rollback>
reopens a transaction and the C<AutoCommit> handler that would close it
again is unreachable code, so any C<txn_do> that rolls back left the
connection inside a transaction DBI did not know about and the next
C<txn_begin> died. This storage's C<_exec_txn_rollback> override now ends
the stray transaction itself (ADR 0005), so a failed apply rolls back whole
B<and> the connection survives -- core's documented recovery, re-running
the upgrade against live state, works. The full reasoning and the
measurement are in
L<DBIO::DuckDB::Deploy/Transactional DDL -- the engine has it, the rollback
override ends the orphan>.

=head2 savepoints

B<None.> DuckDB has no C<SAVEPOINT>: measured on libduckdb v1.5.3,
C<SAVEPOINT>, C<RELEASE SAVEPOINT> and C<ROLLBACK TO SAVEPOINT> are each a
C<Parser Error>, inside a transaction and outside one. This storage therefore
defines none of C<_exec_svp_begin>, C<_exec_svp_release> and
C<_exec_svp_rollback>, which is what core goes by:
L<DBIO::Storage/svp_begin>, L<DBIO::Storage/svp_release> and
L<DBIO::Storage/svp_rollback> throw C<Your Storage implementation doesn't
support savepoints> and send the engine nothing.

That makes C<auto_savepoint> (L<DBIO::Storage::DBI/auto_savepoint>) a setting
to leave off on this driver. With it on, every nested C<txn_do> and every
nested C<txn_scope_guard> is refused with that exception, before the inner
block runs. The refusal itself costs the outer transaction nothing -- an outer
block that catches it carries on and commits -- and one that lets it pass
rolls back, as for any other exception. With it off, which is the default,
the inner level joins the outer transaction: there is one transaction and it
ends as a whole (L<DBIO::Storage/txn_rollback> says what a rollback inside a
nested level does). Pinned in F<t/48-no-savepoints.t>.

=head1 SET OPERATIONS

DuckDB has all six, spelled the ANSI way: C<UNION>, C<UNION ALL>,
C<INTERSECT>, C<INTERSECT ALL>, C<EXCEPT> and C<EXCEPT ALL>, each with its
own section in the dialect reference
(L<https://duckdb.org/docs/stable/sql/query_syntax/setops>). This driver
therefore does B<not> override
L<DBIO::Storage::DBI/_set_operation_keyword> (ADR 0039): it inherits core's
base map unchanged, and all six of L<DBIO::ResultSet>'s set-operation
methods work with nothing declared here.

=head2 The one version boundary, and why it is not refused

The C<... ALL> variants are not as old as the rest. Until DuckDB B<0.10.0>
(2024-02-13) the C<ALL> modifier on C<INTERSECT> and C<EXCEPT> was parsed
and then B<silently ignored>, so C<EXCEPT ALL> ran with C<EXCEPT>
semantics and returned de-duplicated rows. It was implemented for real in
0.10.0 (duckdb/duckdb PR #9636, merged 2023-11-22, first released in
v0.10.0; a competing proposal to raise an error instead, PR #9553, was
closed unmerged).

That is a version-bounded gap, which is what ADR 0039 section 7 is about,
so it was weighed rather than waved through -- and the answer is still to
declare nothing:

=over 4

=item * B<Refusing unconditionally> would withhold C<intersect_all> and
C<except_all> from every DuckDB released since February 2024, the whole of
the 1.x line included, to protect users of a pre-1.0 beta. That is exactly
the trade ADR 0039 section 3 rejects for a capability gate -- a real
outage on every working version in exchange for a defect on none that are
in practice reachable.

=item * B<A class-level opt-in> would have to default to off to mean
anything, which is the same regression wearing a switch, and nobody would
ever set it.

=back

The boundary is documented here instead, because the pre-0.10.0 failure
mode is a B<silent wrong answer> rather than a syntax error, and a silent
wrong answer is worth writing down even where it is not worth a refusal.
It is also hard to reach on purpose: L<DBD::DuckDB> loads L<Alien::DuckDB>
unless C<DUCKDB_NO_ALIEN> is set, and Alien::DuckDB 0.04 ships libduckdb
1.5.3 (0.03 shipped 1.2.2). Running this driver against a libduckdb older
than 0.10.0 means deliberately pointing it at a 2023 pre-1.0 build.

=head1 RANDOM ORDERING

DuckDB spells it C<random()>, a per-row C<DOUBLE> in C<[0,1)>, and function
names are case-insensitive -- so core's inherited C<RANDOM()> is already the
right call and this driver does B<not> override
L<DBIO::Storage::DBI/_random_function>. Measured on
libduckdb v1.5.3: eight rows of C<SELECT RANDOM()> give eight distinct
values, and C<ORDER BY RANDOM()> permutes; DuckDB has no query-constant
variant to be caught by, the way ClickHouse's C<randConstant()> catches
that engine.

The other spelling in this family, MySQL's C<RAND()>, does B<not> exist on
DuckDB -- C<Catalog Error: Scalar Function with name rand does not exist!>
-- so the inheritance is not "either would do". A wrong default here fails
loudly, by naming the function it could not find, which is core's stated
reason for having no capability flag beside this hook. Pinned in
F<t/43-random-and-explain.t>, engine side included.

=head1 QUERY PLANS

DuckDB has a plain C<EXPLAIN> that returns the plan without running the
query, so this driver does B<not> override
L<DBIO::Storage::DBI/_explain_query> either (ADR 0040). C<< $rs->explain >>
answers with a single row of two columns, C<explain_key> and
C<explain_value> -- the key is C<physical_plan> and the value is DuckDB's
box-drawn plan as one string. Its contents are engine-specific, as ADR 0040
section 2 says of every engine here; nothing in this family formats plans
alike.

DuckDB also prepares a B<parameterised> C<EXPLAIN>, which is what lets
core's default hand the explained query's bind list straight through
without the driver taking the statement apart.

What is deliberately B<not> reached for is C<EXPLAIN ANALYZE>. On DuckDB
that is a different operation rather than a formatting option -- it answers
under the key C<analyzed_plan>, and it B<runs the query>: measured on
libduckdb v1.5.3, an explained-and-analyzed C<SELECT nextval(...)> advances
the sequence and an explained-and-analyzed C<INSERT> writes the row, while
the plain C<EXPLAIN> of either does neither. A caller asking what the
planner intends does not expect its data to move, so a future override
adding timings would be buying them with side effects. Pinned in
F<t/43-random-and-explain.t>, including the requirement of ADR 0040
section 3 that the statement travel L<DBIO::Storage::DBI/_execute_rendered>
-- free while the hook is inherited, and the first thing an override loses.

=head1 NO STATEMENT CACHE

This storage prepares every statement afresh.
L<DBIO::Storage::DBI/disable_sth_caching> is B<always on> here: the accessor
answers true whatever it is given, and C<< disable_sth_caching => 0 >> in the
connect attributes is accepted and changes nothing. There is no way to switch
the cache on.

The reason is L<DBD::DuckDB>. Core prepares through L<DBI/prepare_cached>,
which hands out the same statement handle again when the same SQL comes
again, and a DBD::DuckDB 0.16 handle does not survive that, in three ways that
are independent of one another (measured on libduckdb v1.5.3):

=over 4

=item * B<C<finish> destroys the prepared statement>, and the handle stays in
the cache. The second C<create> that lets the engine assign the key, the
second C<find> and the second C<single> of one shape died with C<bind_param
failed>; the second C<populate> with the same columns ended the process with a
segmentation fault.

=item * B<C<execute> never marks the handle C<Active>>, so DBI cannot tell a
handle that is being read from a free one. Two result sets of one SQL shape
that were read side by side shared a handle and got each other's rows.

=item * B<C<execute> keeps the rows left unread by the run before.> After
C<< $rs->search({ rank => 1 })->first >>, the same search for C<< rank => 2 >>
answered the I<second row of the first search>. No error and no warning --
which is why this is not left to a setting.

=back

What it costs is one C<duckdb_prepare> per statement: a few tenths of a
millisecond in-process, which showed as roughly a tenth on top of an ORM
statement that does next to nothing.

Handles you prepare yourself through C<dbh_do> are outside this. One from
C<< $dbh->prepare >> that is executed once is fine; one that is executed
again, or one from C<< $dbh->prepare_cached >>, has the defects above.

Pinned in F<t/49-statement-reuse.t>, which also carries the plain-DBI
sentinel that shows when a DBD::DuckDB release has fixed them; ADR 0007 has
the decision and what was rejected.

=head1 DISCONNECT AND THE DATABASE FILE

DuckDB locks a read-write database file exclusively from C<connect> on, and
while the lock is held no other process can open the file -- not even
read-only. C<< $storage->disconnect >> gives the file back, with one rule and
two exceptions.

B<The rule:> DuckDB keeps the database open for as long as a prepared
statement on it exists, whatever happened to the connection. A statement
handle that outlives C<disconnect> -- a cursor still being iterated, an
C<$sth> the caller holds -- therefore keeps the lock until it is gone.

B<What this storage does about L<DBD::DuckDB>.> DBD::DuckDB 0.16 never frees
a prepared statement: C<finish> hands C<duckdb_destroy_prepare> the handle by
value where the function takes a pointer to it, which reaches C as C<NULL>,
and there is no C<DESTROY> for a handle nobody called C<finish> on, such as
every C<< $dbh->do >>. On a plain DBI handle the lock consequently survives
C<disconnect> until the process exits. This storage frees the statements of
its own connection through a DBI per-handle callback (L<DBI/Callbacks>), in
front of C<finish> and C<DESTROY>; callbacks the application installed there
are chained behind it and keep firing. Nothing outside the storage's own
handle is changed.

B<The exceptions:>

=over 4

=item * B<A DBD::DuckDB newer than 0.16.> The callback frees memory DBD::DuckDB
owns, so it runs only against the releases whose C<finish> has been read.
Against a newer one the storage does nothing and that release's own behaviour
shows.

=item * B<C<< AutoCommit => 0 >>.> DBD::DuckDB issues C<BEGIN TRANSACTION>
inside C<< DBI->connect >>, before the storage has a handle to put a callback
on. That statement is never freed, and the lock is held until the process
exits.

=back

Measured on libduckdb v1.5.3 and pinned in
F<t/47-disconnect-releases-file-lock.t>, which asks a second process to open
the file and reads F</proc/locks>. (Opening the file from the same process
proves nothing: an advisory lock does not stop C<open>, and closing any
descriptor on the file drops the process's own lock on it.)

=head1 FINISH ON A HANDLE WITHOUT A RESULT

A statement the engine refuses is an exception on this storage, also where
the statement handle is finished afterwards.

L<DBD::DuckDB> 0.16 ends the process with a segmentation fault when C<finish>
is called on a statement handle that has no result: one that was never
executed, one whose only C<execute> the engine refused, or one that was
finished before. Cleanup code calls C<finish> exactly then, and so does core
after a bulk insert -- a C<populate> in void context whose first row was
refused (a key that is taken, a value that does not convert) did not throw,
it took the process down.

The per-handle callback described above also stands in front of that: a
handle without a result is given an empty one for C<finish> to destroy. The
C<populate> throws with the engine's reason, its transaction is rolled back
and the connection carries on; a C<finish> of your own on a handle from
C<dbh_do> returns as usual. Like the statement release, this is installed
for DBD::DuckDB up to 0.16 only and changes nothing outside the storage's own
connection -- a plain DBI handle on DuckDB still crashes there.

Measured on libduckdb v1.5.3 and pinned in F<t/51-finish-without-result.t>,
which runs every case in a process of its own.

=head1 ESCAPE HATCHES

DBI is row-oriented. DuckDB is columnar. These methods bypass the DBI
statement-handle path where it hurts:

=head1 QUACK (CLIENT-SERVER RPC)

Quack is a DuckDB extension (v1.5+) that exposes an embedded DuckDB
instance over HTTP-based RPC, turning it into a lightweight server. The
client remains a normal in-process DuckDB using DBD::DuckDB -- no new
transport layer.

B<Requires libduckdb E<gt>= 1.5.> Alien::DuckDB E<gt>= 0.04 ships
1.5.3, so these methods work out of the box; the older 0.03 shipped
1.2.2, which does not include quack. Only against such an older
installation must you supply a newer libduckdb via
C<DUCKDB_NO_ALIEN=1 LD_LIBRARY_PATH=/path/to/1.5.x>.

=head1 SEE ALSO

=pod

=over

=item * L<DBIO::DuckDB> - Schema component that activates this storage

=item * L<DBIO::DuckDB::SQLMaker> - SQL generation for DuckDB

=item * L<DBIO::DuckDB::Deploy> - test-deploy-and-compare schema deploy

=item * L<DBD::DuckDB> - underlying DBI driver

=item * L<DBIO::Storage::DBI> - Base DBI storage class

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
