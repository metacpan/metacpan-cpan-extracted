package DBIO::MSSQL::Storage;
# ABSTRACT: Base Class for Microsoft SQL Server support in DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

use base qw/
  DBIO::Storage::DBI::UniqueIdentifier
  DBIO::Storage::DBI::IdentityInsert
/;
use mro 'c3';

use Context::Preserve 'preserve_context';
use Scope::Guard ();
use DBIO::Util qw(is_literal_value is_plain_value);
use DBIO::MSSQL::Storage::StopAtFirstError ();
use DBIO::MSSQL::DDL ();
use DBIO::MSSQL::Util ();
use Try::Tiny;
use namespace::clean;

__PACKAGE__->mk_group_accessors(simple => qw/
  _identity _identity_method _no_scope_identity_query
/);

__PACKAGE__->sql_maker_class('DBIO::MSSQL::SQLMaker');

__PACKAGE__->register_driver('MSSQL' => __PACKAGE__);

__PACKAGE__->sql_quote_char([qw/[ ]/]);

__PACKAGE__->datetime_parser_type (
  'DBIO::MSSQL::Storage::DateTime::Format'
);

__PACKAGE__->new_guid('NEWID()');

# ADR 0037. The base rendering of DBIO::Storage::DBI::_exists_value_sql --
#
#   SELECT CASE WHEN EXISTS <inner> THEN 1 ELSE 0 END
#
# -- is grammatical Transact-SQL exactly as core writes it, so this driver
# declares the capability and deliberately does NOT override the hook. The
# declaration means somebody read the grammar, so here is what was read, in
# the three places the fragment could have broken:
#
#   * no FROM. SELECT (Transact-SQL) gives <query_specification> as
#     "SELECT <select_list> [ INTO ... ] [ FROM { <table_source> } [ ,...n ] ]"
#     -- FROM is optional, so SQL Server needs none of the dummy tables Oracle
#     (DUAL), DB2 (SYSIBM.SYSDUMMY1) and Firebird (RDB$DATABASE) do.
#   * CASE in the select list. "CASE can be used in any statement or clause
#     that allows a valid expression ... such as SELECT", and the searched
#     form is "CASE WHEN Boolean_expression THEN result_expression ... END".
#   * EXISTS as that Boolean_expression. EXISTS (Transact-SQL) is
#     "EXISTS ( subquery )" with return type Boolean, and Microsoft's own CASE
#     page (example E) writes "CASE WHEN EXISTS (SELECT * FROM ...) THEN ..."
#     verbatim. What T-SQL does not have is EXISTS as a *value* expression --
#     bare SELECT EXISTS (...) is a syntax error here, which is precisely the
#     PostgreSQL-ism ADR 0037 moved core off.
__PACKAGE__->_use_supports_exists_query(1);

# F02 / F10, karr k23 (handoff from core karr k130). Every other declaration in
# this family bar PostgreSQL's is a 0, where the declaration records a decision
# and changes nothing. This one changes what runs:
# DBIO::Deploy::Base::_execute_ddl brackets the install / apply batch in
# $storage->txn_do, and DBIO::DeploymentHandler brackets a whole upgrade (which
# has a consequence of its own -- see "Transactional DDL" in
# DBIO::MSSQL::Deploy). A 1 is therefore a promise about the statements THIS
# driver emits, not about Transact-SQL at large, and the inventory below was
# walked rather than assumed.
#
# THE ENGINE FACT, and the first thing to be honest about: Microsoft nowhere
# says "SQL Server rolls DDL back" for SQL Server. That sentence exists only in
# the Fabric Data Warehouse documentation, which is a different product. The
# SQL Server documentation states the rule the other way round, as a CLOSED
# EXCEPTION LIST -- which is weaker prose and much stronger evidence, because it
# is checkable against an inventory. "Transaction locking and row versioning
# guide", section "Explicit transactions": "You can use all Transact-SQL
# statements in an explicit transaction, except for the following statements:
# CREATE DATABASE, ALTER DATABASE, DROP DATABASE, CREATE FULLTEXT CATALOG,
# ALTER FULLTEXT CATALOG, DROP FULLTEXT CATALOG, DROP FULLTEXT INDEX, ALTER
# FULLTEXT INDEX, CREATE FULLTEXT INDEX, BACKUP, RESTORE, RECONFIGURE, Full-text
# system stored procedures, sp_dboption ... or any system procedure that
# modifies the master database".
#
# The same passage then carves out the one statement that is allowed in a
# transaction but not undone by one -- "UPDATE STATISTICS can be used inside an
# explicit transaction. However, UPDATE STATISTICS commits independently of the
# enclosing transaction and can't be rolled back" -- and that carve-out is what
# makes the list usable rather than merely suggestive: Microsoft distinguishes
# "may not appear in a transaction" from "appears but does not roll back", and
# names the single member of the second category. Two more pieces corroborate
# the rollback half for the statements this driver actually emits: the
# transaction log guide lists "Creating or dropping a table or index" among the
# operations recorded in the log, alongside "data definition language (DDL)
# statements to any table"; and the online-index guidelines say outright "To
# make sure that the index operation can be rolled back, the transaction log
# can't be truncated until the index operation is completed".
#
# THE INVENTORY that reaches _execute_ddl is DBIO::MSSQL::DDL::install_ddl plus
# DBIO::MSSQL::Diff::as_sql, and it is exactly ten shapes:
#
#   CREATE TABLE ... (inline PRIMARY KEY / UNIQUE / FOREIGN KEY, IDENTITY(1,1))
#   CREATE VIEW ... AS ...
#   CREATE [UNIQUE ][CLUSTERED|NONCLUSTERED ]INDEX ... ON ...
#   DROP TABLE ...
#   DROP INDEX ... ON ...
#   ALTER TABLE ... ADD <column>
#   ALTER TABLE ... DROP COLUMN ...
#   ALTER TABLE ... ALTER COLUMN ...
#   ALTER TABLE ... ADD CONSTRAINT ... FOREIGN KEY ...
#   ALTER TABLE ... DROP CONSTRAINT ...
#
# Not one is on the list, and not one carries an option that is. Four near
# misses were checked and are near misses only because this driver emits none
# of them:
#
#   * RESUMABLE = ON -- "The DDL command with RESUMABLE = ON can't be executed
#     inside an explicit transaction" (CREATE INDEX / ALTER INDEX). A hard
#     prohibition, and the one that would bite if index options were ever made
#     configurable.
#   * ALTER INDEX REORGANIZE -- "Not rolled back when performed within a
#     transaction and the transaction is rolled back" (ALTER INDEX). This driver
#     has no ALTER INDEX at all: a definition change is a DROP INDEX / CREATE
#     INDEX pair.
#   * memory-optimized tables -- "Memory-optimized tables and natively compiled
#     stored procedures cannot be created or dropped in the context of a user
#     transaction" (Transact-SQL Constructs Not Supported by In-Memory OLTP).
#     This is the only documented prohibition that touches plain CREATE TABLE,
#     and it is reached only through WITH (MEMORY_OPTIMIZED = ON), which neither
#     DBIO::MSSQL::DDL nor DBIO::MSSQL::Diff::Table can render -- they emit no
#     WITH clause on a table at all.
#   * ONLINE = ON -- NOT forbidden, only cautioned ("be careful when you run an
#     online index operation inside an explicit user transaction ... causes the
#     locks to be held until the end of the transaction", Guidelines for online
#     index operations). Named here because it is the one that gets repeated as
#     a prohibition and is not one. This driver renders no index options either.
#
# So core's per-statement escape hatch -- _ddl_statement_is_transactional, the
# ADR 0026 addendum PostgreSQL needs for ALTER TYPE ... ADD VALUE -- is
# deliberately NOT overridden here. There is nothing for it to except.
# t/42-deploy-transactional-ddl.t sweeps the emitted set against both lists and
# goes red if an emitter ever grows one, which is when the hook becomes the
# answer rather than a downgrade of this declaration.
#
# CREATE DATABASE and DROP DATABASE are the forbidden statements this
# distribution does issue, and they are irrelevant to this capability because
# they never travel the batch path: DBIO::MSSQL::Deploy::_create_temp_db and
# _drop_temp_db hand them to $dbh->do directly on a handle in AutoCommit mode (a handle with
# AutoCommit off is refused, karr k80),
# which is exactly the autocommit mode their reference pages require ("The DROP
# DATABASE statement must run in autocommit mode and isn't allowed in an
# explicit or implicit transaction").
#
# BOTH TRANSPORTS carry the promise, and the declaration sits on this
# transport-neutral base because the transport has no vote in it. Over DBD::ODBC
# the bracket is core's begin_work / commit / rollback on the connection; over
# DBD::Sybase + FreeTDS it is DBIO::Sybase::Storage::FreeTDS's _exec_txn_*,
# which issue literal BEGIN TRAN / COMMIT / ROLLBACK -- the explicit transaction
# the documentation above is written about, in the most literal form. The known
# FreeTDS hazard does not reach here as long as no cursor is open on the
# handle: DBD::Sybase has no real MARS and fakes a second active statement with
# a child connection that deadlocks against a write in a transaction (which is
# why t/10 and t/20 skip the MAS complexes), but _execute_ddl runs one
# statement after another on ONE handle and $dbh->do on DDL leaves no rowset
# pending, so no second statement is ever active. It is the same shape as any
# other txn_do this driver already runs on that transport.
#
# RESTRICTION, NOT MEASURED FOR THE DEPLOY PATH (karr k44): with a cursor open
# on the handle while the deploy runs, BEGIN TRAN goes out on the second
# connection (t/61, karr k41) and the DDL then runs without a transaction --
# the capability promises more than the transport keeps in that case.
#
# WHERE THIS MUST NOT MOVE: DBIO::MSSQL::Storage::Sybase is
# `use base qw/ DBIO::Sybase::Storage  DBIO::MSSQL::Storage /` under mro c3, so
# the Sybase transport class precedes this one in the linearisation that
# Class::Accessor::Grouped::get_inherited walks. Sybase ASE is an
# implicit-commit engine and dbio-sybase declares 0 for it; that 0 lives on
# DBIO::Sybase::Storage::ASE today, which is not in that chain. If it ever rises
# to DBIO::Sybase::Storage it would shadow this 1 silently for every DBD::Sybase
# connection. t/42 pins the declaring class per subclass so that surfaces as a
# red test naming the offender rather than as a lost guarantee.
#
# THE ONE DOCUMENTED WAY TO BREAK THIS, and it is a session setting rather than
# a statement: SNAPSHOT isolation. "The Database Engine doesn't support
# versioning of metadata. For this reason, there are restrictions on what DDL
# operations can be performed in an explicit transaction that's running under
# snapshot isolation. The following DDL statements aren't permitted under
# snapshot isolation after a BEGIN TRANSACTION statement: ALTER TABLE, CREATE
# INDEX, CREATE XML INDEX, ALTER INDEX, DROP INDEX, DBCC REINDEX, ALTER
# PARTITION FUNCTION, ALTER PARTITION SCHEME, or any common language runtime
# (CLR) DDL statement ... Violations of this principle can cause error 3961"
# (same locking guide). That covers half this driver's inventory, so the
# declaration is bounded by it: a caller whose session runs at SET TRANSACTION
# ISOLATION LEVEL SNAPSHOT will see 3961 out of a bracketed deploy where an
# unbracketed one succeeded. Nothing here sets that isolation level and core
# does not either, so it is opt-in -- and it would break a hand-written txn_do
# around the same DDL identically. Worth knowing that the enabling database
# option is on by default in Azure SQL Database ("set to OFF for user databases
# in SQL Server and Azure SQL Managed Instance, and set to ON for databases in
# Azure SQL Database"), though the session still has to ask for the isolation
# level. If this ever turns up in the field, the fix is the per-statement hook
# or a documented refusal, not a silent downgrade.
#
# WHAT IS NOT VERIFIED: no SQL Server was run for this. The reasoning is
# documentary (the pages named above) plus this driver's own statement
# inventory, which is a string question and is swept offline in t/42. It holds
# for the SQL Server engine and, with the snapshot caveat above, for Azure SQL
# Database and Managed Instance, whose reference pages repeat the same
# prohibitions verbatim. Azure Synapse dedicated SQL pools were checked and are
# no worse for DDL -- "The CREATE DATABASE and DROP DATABASE (Transact-SQL)
# commands cannot be used inside an explicit transaction" is the whole of their
# extra list -- but they have no savepoints and no nesting, which is a separate
# matter from this capability and not addressed here. A live run should check
# the one thing a document cannot: that a mid-batch failure under DBD::ODBC and
# under DBD::Sybase really does leave the earlier statements gone.
__PACKAGE__->_use_transactional_ddl(1);

sub dbio_deploy_class { 'DBIO::MSSQL::Deploy' }

sub deploy_setup { }


sub _prep_for_execute {
  my $self = shift;
  my ($op, $ident, $args) = @_;

# cast MONEY values properly
  if ($op eq 'insert' || $op eq 'update') {
    my $fields = $args->[0];

    my $colinfo = $ident->columns_info([keys %$fields]);

    for my $col (keys %$fields) {
      # $ident is a result source object with INSERT/UPDATE ops
      if (
        $colinfo->{$col}{data_type}
          &&
        $colinfo->{$col}{data_type} =~ /^money\z/i
      ) {
        if(
          length ref $fields->{$col}
            and
          my $lit = is_literal_value( $fields->{$col} )
        ) {
          # We are being fed a literal value
          # Generally there is not much we can do about it, *except*
          # in the unambiguous case of a lone bind parameter
          $fields->{$col} = \[ 'CAST(? AS MONEY)', @{$lit}[ 1 .. $#$lit ] ]
            if $lit->[0] eq '?';
        }
        # nonliteral - wrap away
        else {
          $fields->{$col} = \['CAST(? AS MONEY)', [ $col => $fields->{$col} ]];
        }
      }
    }
  }

  # UNIQUEIDENTIFIER columns that look like is_auto_increment are
  # actually populated by NEWID() (see DBIO::Storage::DBI::UniqueIdentifier
  # _prefetch_autovalues) - they are NOT real IDENTITY columns. Suppress
  # the SET IDENTITY_INSERT wrapper the parent IdentityInsert would emit
  # for any autoinc column with a value, otherwise MSSQL complains that
  # the table has no IDENTITY property.
  my $suppress_identity_insert = 0;
  if ($op eq 'insert' and $self->_autoinc_supplied_for_op) {
    my $colinfo = $ident->columns_info;
    my $is_guid_autoinc = 0;
    for my $col (keys %$colinfo) {
      next unless $colinfo->{$col}{is_auto_increment};
      my $dt = $colinfo->{$col}{data_type} || '';
      if ($dt =~ /^(?:uniqueidentifier(?:str)?|guid)\z/i) {
        $is_guid_autoinc = 1;
        last;
      }
    }
    $suppress_identity_insert = 1 if $is_guid_autoinc;
  }

  my ($sql, $bind);
  if ($suppress_identity_insert) {
    local $self->{_autoinc_supplied_for_op} = 0;
    ($sql, $bind) = $self->next::method(@_);
  }
  else {
    ($sql, $bind) = $self->next::method(@_);
  }

  # SELECT SCOPE_IDENTITY only works within a statement scope. We
  # must try to always use this particular idiom first, as it is the
  # only one that guarantees retrieving the correct id under high
  # concurrency. When this fails we will fall back to whatever secondary
  # retrieval method is specified in _identity_method, but at this
  # point we don't have many guarantees we will get what we expected.
  # http://msdn.microsoft.com/en-us/library/ms190315.aspx
  # http://davidhayden.com/blog/dave/archive/2006/01/17/2736.aspx
  if (
    $self->_perform_autoinc_retrieval
      and
    not $self->_no_scope_identity_query
      and
    not $suppress_identity_insert
  ) {
    $sql .= "\nSELECT SCOPE_IDENTITY()";
  }

  return ($sql, $bind);
}

sub _execute {
  my $self = shift;

  # always list ctx - we need the $sth
  my ($rv, $sth, @bind) = $self->next::method(@_);

  if ($self->_perform_autoinc_retrieval) {

    # attempt to bring back the result of SELECT SCOPE_IDENTITY() we tacked
    # on in _prep_for_execute above
    my $identity;

    # we didn't even try on ftds
    unless ($self->_no_scope_identity_query) {
      ($identity) = try { $sth->fetchrow_array };
      $sth->finish;
    }

    # SCOPE_IDENTITY failed, but we can do something else
    if ( (! $identity) && $self->_identity_method) {
      ($identity) = $self->_dbh->selectrow_array(
        'select ' . $self->_identity_method
      );
    }

    $self->_identity($identity);
  }

  return wantarray ? ($rv, $sth, @bind) : $rv;
}

# karr k62. Core's void-context populate executes its rows with
# execute_for_fetch, which DBI runs to the end of the data whatever became of
# the tuple before. SQL Server rolls the whole transaction back on some
# statement errors (Msg 8114), so the tuples after the failing one would run
# in autocommit and stay, while the ones before it are gone with the
# transaction. The handle core is given stops at the first failing tuple.
sub _dbh_execute_for_fetch {
  my ($self, $source, $sth, @rest) = @_;

  return $self->next::method(
    $source, DBIO::MSSQL::Storage::StopAtFirstError->new($sth), @rest,
  );
}


# karr k50. Three questions about a binary value, asked by the two access path
# classes -- each binds such a value in its own way, and this class, which
# knows no transport, in none.

# Is this the data type of a column whose values are bytes? The native binary
# types, and the names DBIO::MSSQL::DDL makes a binary column of. Not "bit"
# (a boolean here) and not "timestamp" (a date and time to DBIO).
sub _is_binary_data_type {
  my ($self, $data_type) = @_;

  return 0 unless defined $data_type;

  return $data_type =~ /\A \s*
    (?: (?:var)? binary (?: \s+ varying )?
      | image | blob | bytea | (?: tiny | medium | long ) blob
    )
    \s* (?: \( [^)]* \) )? \s* \z/xi ? 1 : 0;
}

# karr k47, k58. The type a column has ON THE SERVER, from the declaration:
# the one DBIO::MSSQL::DDL deploys it as, which resolves a portable name
# through DBIO::MSSQL::Adapter (text is nvarchar(max), varchar and string
# are nvarchar, char is nchar). Both access paths decide what to do with a
# value by this and not by the DBIO name -- a 'text' column is an NVARCHAR(MAX)
# and must be read and written as one. Takes the column info (data_type, size)
# or a bare data type; returns the lower-cased type, 'nvarchar(max)' or
# 'ntext', and the data type as it was when the DDL has no answer for it (a
# size it refuses, an unknown name). A type with parentheses is the server's
# own and stands (varchar(max) is a VARCHAR(MAX)).
sub _server_data_type {
  my ($self, $column) = @_;

  my $info = ref $column eq 'HASH' ? $column : { data_type => $column };

  return undef unless defined $info->{data_type};

  my $native = eval { DBIO::MSSQL::DDL::_mssql_column_type($info) };

  return lc( defined $native ? $native : $info->{data_type} );
}

# The bytes of a value for such a column: its characters 0 to 255, whatever
# form Perl holds the string in. A character above 255 is no byte; it is
# refused, not turned into the bytes of its UTF-8 form.
sub _binary_value_bytes {
  my ($self, $value, $column) = @_;

  return $value if not defined $value;

  if (length ref $value) {
    return $value unless is_plain_value $value;   # as core binds it: untouched
    $value = "$value";
  }

  my $bytes = $value;
  return $bytes if utf8::downgrade($bytes, 1);

  my ($position) = grep { ord( substr $value, $_, 1 ) > 255 } 0 .. length($value) - 1;

  $self->throw_exception(sprintf
    'A value for the binary column%s has a character above 255 (U+%04X at '
  . 'position %d of %d), which is no byte. A binary value is the bytes of '
  . 'the string given, one per character: encode a text before it is stored '
  . 'in a binary column.',
    ( defined $column ? " '$column'" : '' ),
    ord( substr $value, $position, 1 ), $position, length $value,
  );
}

# populate in void context hands the storage the rows, not bind values. The
# data set with every value bound to a binary column as its bytes, and
# whether there is such a value at all. Throws for a character above 255,
# before anything is sent.
sub _bulk_binary_values_as_bytes {
  my ($self, $source, $cols, $data) = @_;

  my $colinfos = $source->columns_info($cols);
  my @binary   = map {
    $self->_is_binary_data_type( $colinfos->{ $cols->[$_] }{data_type} ) ? 1 : 0
  } 0 .. $#$cols;

  my $found = 0;
  my @rows  = map {
    my @row = @$_;

    for my $i (0 .. $#row) {
      # a literal with bind values, \[ $sql, @bind ]: each bind has its own type
      if (ref $row[$i] eq 'REF' and ref ${ $row[$i] } eq 'ARRAY') {
        my ($sql, @bind) = @${ $row[$i] };
        my $resolved = $self->_resolve_bindattrs($source, \@bind, $colinfos);

        next unless grep {
          $self->_is_binary_data_type( $_->[0]{sqlt_datatype} )
        } @$resolved;

        $found  = 1;
        $row[$i] = \[ $sql, map { [
          $_->[0],
          $self->_is_binary_data_type( $_->[0]{sqlt_datatype} )
            ? $self->_binary_value_bytes( $_->[1], $_->[0]{dbic_colname} )
            : $_->[1],
        ] } @$resolved ];
      }
      elsif ($binary[$i] and ref $row[$i] ne 'SCALAR') {
        $found  = 1;
        $row[$i] = $self->_binary_value_bytes( $row[$i], $cols->[$i] );
      }
    }

    \@row;
  } @$data;

  return $found ? ( \@rows, 1 ) : ( $data, 0 );
}

sub last_insert_id { shift->_identity }


#
# MSSQL is retarded wrt ordered subselects. One needs to add a TOP
# to *all* subqueries, but one also *can't* use TOP 100 PERCENT
# http://sqladvice.com/forums/permalink/18496/22931/ShowThread.aspx#22931
#
sub _select_args_to_query {
  #my ($self, $ident, $select, $cond, $attrs) = @_;
  my $self = shift;
  my $attrs = $_[3];

  my $sql_bind = $self->next::method (@_);

  # see if this is an ordered subquery
  if (
    $$sql_bind->[0] !~ /^ \s* \( \s* SELECT \s+ TOP \s+ \d+ \s+ /xi
      and
    scalar $self->_extract_order_criteria ($attrs->{order_by})
  ) {
    $self->throw_exception(
      'An ordered subselect encountered - this is not safe! Please see "Ordered Subselects" in DBIO::MSSQL::Storage'
    ) unless $attrs->{unsafe_subselect_ok};

    $$sql_bind->[0] =~ s/^ \s* \( \s* SELECT (?=\s) / '(SELECT TOP ' . $self->sql_maker->__max_int /exi;
  }

  $sql_bind;
}


# savepoint syntax is the same as in Sybase ASE

sub _exec_svp_begin {
  my ($self, $name) = @_;

  $self->_dbh->do("SAVE TRANSACTION $name");
}

# A new SAVE TRANSACTION with the same name releases the previous one.
sub _exec_svp_release { 1 }

sub _exec_svp_rollback {
  my ($self, $name) = @_;

  $self->_dbh->do("ROLLBACK TRANSACTION $name");
}

sub sqlt_type { 'SQLServer' }


sub _connect_params_dsn {
  my ($self, $driver, $params) = @_;

  # $driver is the name this class is registered for -- 'MSSQL', which no DBD
  # carries -- so it is not what goes into the DSN.
  my ($dbname, $host, $port) = @{$params}{qw(dbname host port)};

  my $pair = 'DBD::Sybase reaches a server by its address only when it has '
    . 'both (dbi:Sybase:host=<host>;port=<port>)';

  $self->throw_exception(
    'Cannot build a DBD::Sybase DSN from the connection parameter host '
  . "without a port: $pair, and a host alone it ignores. No port is assumed "
  . 'here -- 1433 is only where a default instance usually listens. Give '
  . 'port as well, or supply a dsn instead (dbi:Sybase:... or dbi:ODBC:...).'
  ) if defined $host && !defined $port;

  $self->throw_exception(
    'Cannot build a DBD::Sybase DSN from the connection parameter port '
  . "without a host: $pair, and a port alone it ignores. Give host as well, "
  . 'leave port out, or supply a dsn instead (dbi:Sybase:... or dbi:ODBC:...).'
  ) if defined $port && !defined $host;

  return 'dbi:Sybase:' . join ';',
    ( defined $host   ? ("host=$host", "port=$port") : () ),
    ( defined $dbname ? "database=$dbname"           : () );
}


sub _bind_host_into_dsn {
  my ($self, $driver, $dsn, $host, $port) = @_;

  # DBD::Sybase takes host=/port= (core's default, which also declines
  # server=NAME); any other DBD is not this seam's to translate.
  return $self->next::method($driver, $dsn, $host, $port)
    unless defined $driver and lc $driver eq 'odbc';

  return (undef, 'a DSN without a dbi:ODBC: prefix')
    unless defined $dsn and $dsn =~ /\A(dbi:odbc(?:\([^)]*\))?:)(.*)\z/is;
  my ($prefix, $rest) = ($1, $2);

  # Parts split on ';' outside braces ({ODBC Driver 18 for SQL Server}, or a
  # value holding a ';').
  my @parts;
  my $at = 0;
  while ($rest =~ /\G((?:[^;{]|\{[^}]*\})*)(;|\z)/gc) {
    push @parts, $1;
    $at = pos $rest;
    last unless length $2;
  }
  return (undef, 'an unbalanced { in the DSN') unless $at == length $rest;

  my (@server, @port);
  for my $i (0 .. $#parts) {
    next unless length $parts[$i];
    return (undef, 'a part without key=value form (a data source name)')
      unless $parts[$i] =~ /\A\s*(\w+)\s*=/;
    my $key  = $1;
    my $lkey = lc $key;

    return (undef, "the key '$key' naming a data source or a configured server, "
      . 'which holds no host to replace')
      if $lkey eq 'dsn' or $lkey eq 'filedsn' or $lkey eq 'servername';
    return (undef, "the key '$key' naming the server's address beside Server")
      if $lkey eq 'address' or $lkey eq 'addr';

    push @server, $i if $lkey eq 'server';
    push @port,   $i if $lkey eq 'port';
  }

  return (undef, "the key 'Server' more than once") if @server > 1;
  return (undef, "the key 'Port' more than once")   if @port > 1;
  return (undef, 'a DSN without a Server key') unless @server;

  my ($skey, $svalue) = $parts[ $server[0] ] =~ /\A\s*(\w+)\s*=(.*)\z/s;

  return (undef, "the key '$skey' with a braced value") if $svalue =~ /\A\s*\{/;
  return (undef, "the key '$skey' with an instance name (host\\instance)")
    if $svalue =~ /\\/;
  return (undef, "the key '$skey' with a ':' in its value (a protocol prefix "
    . 'such as tcp:, or an IPv6 address)')
    if $svalue =~ /:/;

  if ($svalue =~ /\A[^,]*,(.*)\z/s) {
    # Server=host,port
    my $old_port = $1;
    return (undef, "both a port after the comma of '$skey' and a Port key")
      if @port;
    $parts[ $server[0] ] = "$skey=$host," . ($port // $old_port);
  }
  elsif (@port) {
    # Server=host;Port=n
    $parts[ $server[0] ] = "$skey=$host";
    if (defined $port) {
      my ($pkey) = $parts[ $port[0] ] =~ /\A\s*(\w+)/;
      $parts[ $port[0] ] = "$pkey=$port";
    }
  }
  else {
    return (undef, "the key '$skey' without a port form (a ',port' behind it "
      . 'or a Port key) beside a port of the view')
      if defined $port;
    $parts[ $server[0] ] = "$skey=$host";
  }

  return $prefix . join ';', @parts;
}


# The class of this driver for each DBD that reaches SQL Server (ADR 0035).
my %ACCESS_PATH_CLASS = (
  ODBC   => 'DBIO::MSSQL::Storage::ODBC',
  Sybase => 'DBIO::MSSQL::Storage::Sybase',
);

sub _adapt_to_access_path {
  my ($self, $dbd) = @_;

  # A connection coderef names no DBD until it has run, and core does not run
  # it for the hook. Connect info without a DSN -- a schema that only writes
  # SQL -- has nothing to run and stays the declared class.
  $dbd = $self->_get_dbh->{Driver}{Name}
    if not defined $dbd and ref $self->_dbi_connect_info->[0];

  # The DBD of another driver, or one nobody knows: core judges that.
  my $class = defined $dbd && $ACCESS_PATH_CLASS{$dbd}
    or return;

  # A storage pinned to the access-path class itself is already there.
  return if $self->isa($class);

  # Only the declared base moves. A private subclass pinned by hand has to
  # stay an instance of itself -- core checks that after the hook and throws
  # -- and neither class above inherits it. (A layer class core composed over
  # the declared base does not count as one: core's declared class is the
  # base then.)
  unless ( ( $self->_declared_storage_class || ref $self ) eq __PACKAGE__ ) {

    # Over DBD::Sybase such a class is refused (karr k42, k43; ADR 0008): the
    # base is transport-neutral and has none of what the Sybase class does for
    # this DBD. Over DBD::ODBC it is left alone.
    # The DBD::ODBC class (or a derivation of it) is no derivation of the base
    # that lacks anything: it is the wrong class for this DBD (karr k42).
    $self->throw_exception(
      'A storage class derived from ' . __PACKAGE__ . ' (' . ($self->_declared_storage_class || ref $self)
    . ') is built for DBD::ODBC and cannot be used over DBD::Sybase: the '
    . 'class and the DSN contradict each other. Pin '
    . 'DBIO::MSSQL::Storage::Sybase (or a class derived from it) for '
    . 'dbi:Sybase:, or give a dbi:ODBC: DSN.'
    ) if $dbd eq 'Sybase' and $self->isa($ACCESS_PATH_CLASS{ODBC});

    $self->throw_exception(
      'A storage class derived from ' . __PACKAGE__ . ' (' . ($self->_declared_storage_class || ref $self)
    . ') cannot be used over DBD::Sybase: the base class is transport-neutral '
    . 'and has none of what this access path needs (transaction statements, '
    . 'the 4000 byte limit of bind values, reading binary values). Derive '
    . 'from DBIO::MSSQL::Storage::Sybase instead, or connect through '
    . 'DBD::ODBC (dbi:ODBC:...).'
    ) if $dbd eq 'Sybase';

    return;
  }

  $self->throw_exception(
    'A connection to Microsoft SQL Server through DBD::Sybase needs '
  . 'DBIO::Sybase, which is not installed: DBIO::MSSQL::Storage::Sybase, the '
  . 'storage class for this access path, is built on DBIO::Sybase::Storage. '
  . 'Install DBIO::Sybase, or connect through DBD::ODBC (dbi:ODBC:...).'
  ) if $dbd eq 'Sybase'
    and not $self->load_optional_class('DBIO::Sybase::Storage');

  $self->ensure_class_loaded($class);
  bless $self, $class;

  # The turn of the class the storage became: what is left to decide on that
  # access path is its own (NoBindVars over DBD::Sybase).
  $self->_adapt_to_access_path($dbd);
}


sub _random_function { 'NEWID()' }

# karr k22 / ADR 0040 -- the WHOLE operation of obtaining a query plan. Core's
# inherited operation is "EXPLAIN <query>" and Transact-SQL has no EXPLAIN
# statement at all, so there is nothing here for the server to parse. SQL
# Server is one of the two engines ADR 0040 widened this seam from a string to
# a method for, and spelling is not the reason: obtaining a plan here is not a
# statement but a SESSION SETTING, three round-trips with state left behind in
# between.
#
# The OFF is a Scope::Guard rather than a third line, and that is the whole
# point of this method's shape. If the middle statement throws -- a syntax
# error in the explained query, a dropped connection, anything -- an unguarded
# OFF is skipped and the SESSION IS LEFT POISONED: SHOWPLAN_ALL stays on for
# the life of that connection, so every later query on it returns a plan
# instead of its rows, with no error anywhere to notice. Well-formed rowsets,
# silently answering a question nobody asked, for as long as the handle is
# pooled -- a worse defect than the missing EXPLAIN this override fixes, and
# unlike it, quiet. The guard fires on both paths and touches nothing in
# flight, so the explained query's own exception is what propagates.
#
# All three statements go through _execute_rendered, which ADR 0040 section 3
# makes a requirement of the contract with no engine-named exceptions: it keeps
# _query_start / _query_end tracing and therefore redact_bind_value (ADR 0025)
# over the caller's own WHERE-clause values, dbh_do retry, NoBindVars
# interpolation, and the read handler rather than the master's on a replicated
# storage. Core delegates this whole method rather than the statements inside
# it, so all three land on one connection -- which a session setting requires.
sub _explain_query {
  my ($self, $sql, $bind) = @_;

  # Alone in its batch, which each _execute_rendered call is.
  $self->_execute_rendered('SET SHOWPLAN_ALL ON', []);

  # Created only now, on purpose: a SET that failed was never applied, and
  # turning off a setting the session never got would replace the real error
  # with a second one.
  my $showplan_off = Scope::Guard->new(sub {
    $self->_execute_rendered('SET SHOWPLAN_ALL OFF', []);
  });

  # Not executed while the setting is on -- the server answers this statement
  # with its plan. The binds still travel with it: the statement is parsed, so
  # its placeholders are still its own.
  my (undef, $sth) = $self->_execute_rendered($sql, $bind);

  # Fetched BEFORE the guard fires (return evaluates, then the scope unwinds).
  # Also deliberate: the OFF is a statement, and issuing one with an unfetched
  # rowset pending is what desynchronises a DBD::Sybase connection.
  return $sth->fetchall_arrayref;
}

# ADR 0039. Transact-SQL has four of the six set operations, spelled the ANSI
# way, so the only opinion this driver has is a refusal -- everything else goes
# to next::method and inherits the base keyword.
#
# The engine fact, read rather than assumed: the <query_expression> production
# in SELECT (Transact-SQL) is
#
#   { <query_specification> | ( <query_expression> ) }
#   [ { UNION [ ALL ] | EXCEPT | INTERSECT }
#     <query_specification> | ( <query_expression> ) [ ...n ] ]
#
# -- the optional ALL sits inside the UNION alternative only. The dedicated
# EXCEPT and INTERSECT page carries the same production, "{ EXCEPT | INTERSECT }",
# opens with "Returns distinct rows by comparing the results of two queries",
# and does not contain the word ALL anywhere on the page.
#
# ADR 0039 section 7 makes the hook a static class fact and then asks a driver
# whose gap is version-BOUNDED to choose between refusing unconditionally and a
# class-level opt-in. Neither choice arises here, and that is worth stating
# rather than leaving as an unexplained pick: this gap is not version-bounded.
# The grammar reads the same at both ends of what Microsoft documents -- the
# archived SQL Server 2008 R2 reference and the current one -- and EXCEPT /
# INTERSECT have never had an ALL form to lose. So the refusal is unconditional
# because the fact is, not as the price of deciding without a connection, and
# the ODBC / DBD::Sybase rebless split this repo already has (section 7's
# option (b)) has nothing to distinguish: both transports reach the same
# engine.
sub _set_operation_keyword {
  my ($self, $op) = @_;

  # let the base throw for an undefined operation (ADR 0039)
  return $self->next::method($op) unless defined $op;

  if ($op eq 'except_all' or $op eq 'intersect_all') {
    (my $distinct_form = $op) =~ s/_all\z//;

    $self->throw_exception(
      "SQL Server has no $op: Transact-SQL spells set difference and set "
    . 'intersection EXCEPT and INTERSECT, both of which always return '
    . 'distinct rows, and has no ALL variant of either. This refusal is '
    . 'unconditional and is not a version compromise -- the grammar reads '
    . '"{ EXCEPT | INTERSECT }" in every version Microsoft documents '
    . '(checked at both ends: the SQL Server 2008 R2 reference and the '
    . 'current one), while UNION on the same engine is documented as '
    . '"UNION [ ALL ]". The nearest available operation is '
    . "->$distinct_form(), but it is not a substitute: it collapses "
    . 'duplicate rows, so it answers a different question.'
    );
  }

  return $self->next::method($op);
}


sub _mask_error_values {
  my ($self, $text, $values, $statement) = @_;

  $text = DBIO::MSSQL::Util::mask_error_details($text, $values, $statement)
    if defined $text and !ref $text;

  return $self->next::method($text, $values, $statement);
}

sub _ping {
  my $self = shift;

  my $dbh = $self->_dbh or return 0;

  local $dbh->{RaiseError} = 1;
  local $dbh->{PrintError} = 0;

  return try {
    $dbh->do('select 1');
    1;
  } catch {
    0;
  };
}

sub with_deferred_fk_checks {
    my ( $self, $sub ) = @_;

    my $txn_scope_guard = $self->txn_scope_guard;

    $self->_do_query(
        'EXEC sp_msforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT ALL"');

    my $sg = Scope::Guard->new(
        sub {
            $self->_do_query(
                'EXEC sp_msforeachtable "ALTER TABLE ? CHECK CONSTRAINT ALL"'
            );
        } );

    return preserve_context { $sub->() } after => sub {
        # explicitly check constraints because MSSQL does not check when
        # re-enabling them
        $self->_do_query(
            'EXEC sp_msforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL"'
        );
        $txn_scope_guard->commit;
        $sg->dismiss;
    };
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Storage - Base Class for Microsoft SQL Server support in DBIO

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Storage driver for Microsoft SQL Server databases. Handles identity column
(autoincrement) retrieval via C<SCOPE_IDENTITY()>, proper C<MONEY> column
casting on insert/update, ordered subselect safety checks, savepoint support,
deferred foreign key checks via C<sp_msforeachtable>, and datetime parsing.

Limited queries always use the C<ROW_NUMBER() OVER()> dialect via
L<DBIO::MSSQL::SQLMaker>; there is no version-dependent C<TOP> path.

This is the class a schema declares -- the L<DBIO::MSSQL> component and the
C<-ms> shortcut pin it -- and it is transport-neutral: everything here holds
whichever DBD carries the connection. A connected storage is one of its two
subclasses, L<DBIO::MSSQL::Storage::ODBC> or L<DBIO::MSSQL::Storage::Sybase>;
a declared storage moves there itself at its first use
(L</_adapt_to_access_path>).

=head1 METHODS

=head2 _dbh_execute_for_fetch

The executing half of core's void-context C<populate>. The rows are executed
with C<execute_for_fetch>, which DBI runs to the end of the data whatever
became of the tuple before. SQL Server rolls the whole transaction back on
some statement errors (Msg 8114, a bound value that cannot be converted), so
the tuples after the failing one ran in autocommit and stayed, while the ones
before it were gone: C<populate> threw and left part of its data.
Core is given a handle that stops at the first failing tuple
(L<DBIO::MSSQL::Storage::StopAtFirstError>); nothing of the data set stays.

=head2 last_insert_id

Returns the last identity value inserted, as retrieved by C<SCOPE_IDENTITY()>
or the fallback C<_identity_method>.

=head2 sqlt_type

Returns C<SQLServer>, identifying this storage to L<SQL::Translator>.

=head2 _connect_params_dsn

The DSN seam of L<DBIO::Storage::DBI/_connect_params_dsn> (ADR 0057),
overridden because core's default form puts the name the storage class is
registered for into the DSN, and this class is registered for C<MSSQL> -- a
registry name, there is no C<DBD::MSSQL>. The DSN built here names
L<DBD::Sybase>, whatever name the seam is handed: of the two DBDs that reach
SQL Server it is the one whose DSN keys C<dbname>, C<host> and C<port> can
fill. L<DBD::ODBC> needs a data source name or the name of an ODBC driver,
which connection parameters do not carry.

  dbi:Sybase:host=<host>;port=<port>;database=<dbname>

C<host> and C<port> go in as a pair, C<dbname> as C<database=> (C<dbname=> is
no DBD::Sybase key), and a part not given is left out -- nothing is put into
the DSN that the parameters do not say:

=over

=item * without C<dbname> there is no C<database=>, and the server puts the
session into the login's default database;

=item * without C<host> and C<port> the DSN names no server, and DBD::Sybase
connects to its default one: C<$DSQUERY>, else the server called C<SYBASE> in
F<freetds.conf> or the interfaces file.

=back

Two combinations refuse, each error naming the ways out:

=over

=item * C<host> without C<port>. DBD::Sybase documents the two only as a pair
and uses them only when both are set; a lone C<host> is ignored and the
connection goes to the default server, silently. No port is assumed: 1433 is
where a default instance usually listens, a named instance listens elsewhere,
and neither DBD::Sybase nor its documentation supplies one.

=item * C<port> without C<host>. Ignored the same way; the port given would be
dropped.

=back

Anything these three parts cannot say goes in as the whole DSN: as C<dsn>, or
as a C<dbname> that starts with C<dbi:> (L<DBIO::AccessBroker::Static> passes
it on), which core takes as the DSN before this seam is asked. That is the
only way in for DBD::ODBC -- L<DBIO::MSSQL::Storage::ODBC> inherits
L<DBIO::Storage::DBI::ODBC> ahead of this class and so keeps core's refusal,
deliberately: an ODBC storage must not reconnect through another DBD -- and
for a named server over DBD::Sybase (C<dbi:Sybase:server=E<lt>nameE<gt>;...>).

Three things this DSN does not do:

=over

=item * B<It names no server.> Over FreeTDS a second statement active at the
same time makes DBD::Sybase open a second connection. With
C<host=...;port=...> that connection is made, but the client library leaves
its message 44 ("Server name not found in configuration files") on the handle,
and the statement fails with it; a named C<[server]> block in
F<freetds.conf> has a name to resolve. Use the C<server=> form for that.

=item * B<It decides the DBD, and it is asked before the storage has adapted
to one.> The seam is asked when the schema connects, on this class; the
storage becomes the class for its access path only at the first use
(L</_adapt_to_access_path>), and by then the DSN built here names
DBD::Sybase. So connection parameters always lead to
L<DBIO::MSSQL::Storage::Sybase>, never to the ODBC class -- which would
refuse them. Every later connection asks the seam of the class the storage
became: the same form over DBD::Sybase, a refusal over DBD::ODBC
(F<t/62-adapt-access-path.t>).

=item * B<It is not verified beyond one client library.> The three forms were
run through this seam against SQL Server 2022 with DBD::Sybase 1.27 over
FreeTDS 1.3.17 (F<t/60-connect-params-live.t>):
C<host=...;port=...;database=...> connects into the database named,
C<host=...;port=...> into the login's default database, and C<database=...>
alone connects once C<$DSQUERY> names a server FreeTDS can resolve. Sybase's
own client library was not tried.

=back

=head2 _bind_host_into_dsn

The HostBound seam of L<DBIO::Storage::DBI/_bind_host_into_dsn>: how a
L<DBIO::AccessBroker::HostBound> view -- a host of its own per replicant, one
set of credentials -- puts its host (and port) into a DSN. It stands on this
base class, so it is reached on the declared class (asked before the storage
has adapted to an access path), on L<DBIO::MSSQL::Storage::ODBC> and on
L<DBIO::MSSQL::Storage::Sybase> alike, and answers by the DBD the DSN names.

B<DBD::ODBC> (C<dbi:ODBC:>) names the server in a C<Server> key:

=over

=item * C<Server=host,port> (the Microsoft form): the host and the port are
replaced where they stand.

=item * C<Server=host;Port=n> (the FreeTDS form): C<Server> and C<Port> are
replaced where they stand.

=back

A view without a port keeps the port the answer had. Every other part of the
DSN, the case of the keys, braces such as C<Driver={ODBC Driver 18 for SQL
Server}> and the C<dbi:ODBC(attr):> prefix stay as they are.

It is B<declined> -- the view refuses the connection, naming the form and
never a value of the DSN -- for a DSN that holds no host to replace or names
the server so that replacing it would change the meaning: a data source
(C<DSN=>, C<FILEDSN=>, a bare name), C<Servername=> (an entry of
F<freetds.conf>), C<Address=>/C<Addr=>, a C<Server> with an instance
(C<host\instance>), a protocol or IPv6 colon (C<tcp:host>), or a braced
value, both a comma port and a C<Port> key, a key given twice, no C<Server>
at all, and a view port where the DSN shows no port form to put it in
(C<Server=host> alone): which of the two forms the driver reads is the DSN's
to say, and the seam does not guess.

B<DBD::Sybase> (C<dbi:Sybase:>): core's default -- C<host=> and C<port=> are
bound -- and the refusal of C<server=NAME>, a named server of
F<freetds.conf>/F<interfaces> that holds no host. Any other DBD gets core's
answer too.

=head2 _adapt_to_access_path

The hook of L<DBIO::Storage::DBI/_adapt_to_access_path> (ADR 0059).
A schema declares this driver by loading the L<DBIO::MSSQL> component or by
the C<-ms> shortcut, and both pin this class -- the transport-neutral base
(ADR 0035), which fits neither DBD that reaches SQL Server as it stands. Core
calls the hook at the first use that needs the driver, with the name of the
DBD the connect info leads through, and the storage moves into this driver's
class for it:

=over

=item * C<ODBC> -- L<DBIO::MSSQL::Storage::ODBC>. Decided from the DSN, without
a connection.

=item * C<Sybase> -- L<DBIO::MSSQL::Storage::Sybase>, which then decides
whether the connection takes placeholders and, if it does not, moves on to
L<DBIO::MSSQL::Storage::Sybase::NoBindVars>. It asks the client library
through the handle: on this access path the first use connects.
L<DBIO::Sybase::Storage> then mixes its FreeTDS class in.

DBIO::Sybase is an optional dependency of this distribution. Without it a
C<dbi:Sybase:> DSN throws here, naming it, and the storage stays undetermined;
no other class of this driver works on a DBD::Sybase handle.

=back

Any other DBD leaves the storage as it is. If that DBD belongs to another
driver, core reports it (L<DBIO::Storage::DBI/_driver_mismatch>); a DBD nothing
is registered for is not judged.

A connection coderef names no DBD until it has run, so core hands the hook
none. The hook then runs it -- one connection, the one the storage goes on
using -- and reads the DBD off the handle. Connect info without a DSN, as on a
schema that only generates SQL, is left alone.

Three things the hook does not do:

=over

=item * B<It does not ask the server what it is.> A schema that declared this
driver has answered that question. A declared storage never leaves this
driver. Nothing this driver reads anyway tells it the product, so a server
that is not SQL Server is not reported by it.

=item * B<It does not move a class that is not this one.> A subclass of this
class pinned by hand through L<DBIO::Schema/storage_type> stays what it is --
core requires the storage to remain an instance of the class that was
declared, and neither access-path class inherits a private one. Over
DBD::ODBC core then reports the DBD as not belonging to that class, which is
true: derive from L<DBIO::MSSQL::Storage::ODBC> instead. A storage pinned to
one of the two access-path classes is already on its access path.

=item * B<It refuses a private subclass over DBD::Sybase.> On a
L<DBD::Sybase> handle such a subclass throws at the first use, naming
L<DBIO::MSSQL::Storage::Sybase> as the class to derive from and DBD::ODBC as
the other way (ADR 0008) -- whatever C<driver_strict> and
C<driver_warnings> say. A storage pinned to L<DBIO::MSSQL::Storage::ODBC>
(or a class derived from it) over DBD::Sybase is refused with a message of
its own: the class and the DSN contradict each other. The base is transport-neutral and has none of what
the Sybase class does for this DBD: the transaction statements (COMMIT and
ROLLBACK are refused by the client library with results pending, and
C<txn_do> runs its body a second time on a new connection; an empty
transaction can be neither committed nor rolled back), the 4000 byte limit of
bind values (the server cuts a longer one without an error,
L<DBIO::MSSQL::Storage::Sybase/VALUES OF MORE THAN 4000 BYTES>), and binary
values in both directions. This departs from ADR 0059 of core, where a driver
mismatch warns and only C<driver_strict> makes it an error: here it is an
error for this one pairing. A layer class core composes over the declared base
is not a private subclass.

=item * B<It does not choose the DBD.> Connection parameters without a DSN
have been turned into one by L</_connect_params_dsn> when the schema
connected -- on this class, before the hook runs -- and that DSN names
DBD::Sybase. The hook follows it.

=back

What the DBD::Sybase class brings includes the FreeTDS adaptations. One of them
is to be known: over
FreeTDS C<SET TEXTSIZE> is set to C<LongReadLen> at connect
(L<DBIO::Sybase::Storage::FreeTDS/set_textsize>, 32768 unless the connect info
says otherwise), so a longer value of a LOB column is not delivered cut: a
column of a result source that is a C<(N)VARCHAR(MAX)>, an C<NTEXT> or a
binary type is read behind a check the server runs, and a value over
C<TEXTSIZE> bytes B<fails the read> naming the column (the handle
itself, literal SQL and expressions are not covered and still cut without an
error). Raise C<LongReadLen> in the connect info for longer ones; an
C<NVARCHAR(MAX)>, which is what a C<text> column is, holds two bytes per
character. See L<DBIO::MSSQL::Storage::Sybase/VALUES LONGER THAN TEXTSIZE>.

=head2 _mask_error_values

  my $text = $storage->_mask_error_values($text, \@values, $statement);

The seam of core (ADR 0075) through which the text of an engine passes before
it is thrown. SQL Server writes the offending value into its own sentences
(C<Conversion failed when converting the varchar value 'x' to data type int.>,
C<The duplicate key value is (x).>, C<Truncated value: 'x'.>, C<Incorrect
syntax near 'x'.>), also when the value was a bind, and a short one (C<7>,
C<ab>) is not found by looking for the bound values alone. So the sentences
are masked first, by L<DBIO::MSSQL::Util/mask_error_details> with the bound
values, then core's implementation (C<next::method>) masks the values the
handle quotes. The base class carries it, so L<DBIO::MSSQL::Storage::ODBC> and
L<DBIO::MSSQL::Storage::Sybase> (and the NoBindVars classes, whose statement
holds the values) have it too. Only a defined text that is no reference is
looked at; C<< $dbh->errstr >> stays as the DBD has it.

=head2 with_deferred_fk_checks

    $storage->with_deferred_fk_checks(sub { ... });

Runs the supplied coderef with all foreign key constraints disabled via
C<sp_msforeachtable>. Constraints are re-enabled and explicitly verified
afterwards, and the transaction is committed.

=head1 ORDERED SUBSELECTS

SQL Server rejects C<ORDER BY> in a subquery unless it carries a C<TOP>, and
C<TOP 100 PERCENT> does not help. An ordered subselect therefore throws an
exception unless the C<unsafe_subselect_ok> attribute is set; with it, the
subquery is rewritten to C<(SELECT TOP E<lt>max_intE<gt> ...>, where max_int is
C<0x7FFFFFFF>.

=head1 EXISTS QUERIES

This storage declares the C<supports_exists_query> capability (ADR 0037), so
L<DBIO::ResultSet/results_exist>, L<DBIO::ResultSet/results_exist_async> and
L<DBIO::ResultSet/results_exist_as_query> are available on SQL Server. It does
B<not> override L<DBIO::Storage::DBI/_exists_value_sql>: core's base rendering,
C<SELECT CASE WHEN EXISTS E<lt>innerE<gt> THEN 1 ELSE 0 END>, is grammatical
Transact-SQL as written -- a C<FROM>-less C<SELECT> is legal here, and
C<CASE WHEN EXISTS (...)> is Microsoft's own documented idiom. What T-SQL does
not have is C<EXISTS> as a bare value expression, which is what core emitted
before ADR 0037.

One SQL Server restriction reaches this call: an existence check on a
resultset carrying an C<order_by> is refused by this driver's ordered-subselect
guard before any C<EXISTS> SQL is built, because Transact-SQL forbids
C<ORDER BY> inside a subquery without C<TOP> / C<OFFSET> / C<FOR XML>. An
ordering has no meaning for an existence check anyway -- drop it, or ask on the
unordered resultset.

=head1 SET OPERATIONS

Of L<DBIO::ResultSet>'s six set operations, SQL Server has four:
L<union|DBIO::ResultSet/union>, L<union_all|DBIO::ResultSet/union_all>,
L<intersect|DBIO::ResultSet/intersect> and L<except|DBIO::ResultSet/except>,
all spelled the ANSI way and inherited from core unchanged.

L<intersect_all|DBIO::ResultSet/intersect_all> and
L<except_all|DBIO::ResultSet/except_all> B<throw> (ADR 0039). Transact-SQL has
no C<INTERSECT ALL> and no C<EXCEPT ALL>: C<EXCEPT> and C<INTERSECT> always
return distinct rows, and unlike C<UNION> they take no C<ALL>. The refusal is
unconditional and version-independent, because the gap is -- the grammar has
read C<{ EXCEPT | INTERSECT }> in every version Microsoft documents.

The keyword is resolved before any operand SQL is assembled, so a refused
operation throws while the query is being built and never yields a fragment
that could be embedded in a larger query. C<< $rs->except >> and
C<< $rs->intersect >> are the nearest available operations, but they are not
substitutes: they collapse duplicate rows, which is a different question.

=head1 QUERY PLANS

L<DBIO::ResultSet/explain> asks the storage for the B<whole operation> of
obtaining a query plan, through L<DBIO::Storage::DBI/_explain_query> (ADR 0040,
which replaced the string-valued C<_explain_sql>). SQL Server is one of the two
engines that argument was made for, and this class overrides the hook because
core's inherited operation cannot work here at all: it is
C<EXPLAIN E<lt>queryE<gt>>, and Transact-SQL has no C<EXPLAIN> statement. There
is nothing for the server to parse.

What SQL Server has instead is a B<session setting>, which is why no rewriting
of a single statement string could have expressed this. Obtaining a plan is
three round-trips with session state left behind between them:

  SET SHOWPLAN_ALL ON     -- must be the only statement in its batch
  <the query>             -- NOT executed: it answers with the plan
  SET SHOWPLAN_ALL OFF

The middle statement is the explained query itself, unchanged and carrying its
own bind values -- it is still parsed, so its placeholders are still its own.
While the setting is on the server "returns execution information for each
statement without executing it", so what comes back is the plan rather than the
query's result.

All three statements go through L<DBIO::Storage::DBI/_execute_rendered>, which
the contract requires without engine-named exceptions. That is what keeps
tracing and therefore L<DBIO::Storage::DBI/redact_bind_value> (ADR 0025) over
the explained query's own bind values, C<dbh_do> retry over a dropped
connection, L<DBIO::Storage::DBI::NoBindVars> interpolation, and -- on a
L<DBIO::Replicated::Storage> -- the read handler rather than the master's.
Because core delegates the whole operation rather than the statements inside
it, all three land on the same connection, which a session setting requires.

=head2 Turning it back off is guarded, not merely last

C<SET SHOWPLAN_ALL OFF> runs from a L<Scope::Guard>, so it also runs when the
explained query throws. This is the failure that matters here: an unguarded OFF
is skipped on an exception and the B<session stays poisoned>. C<SHOWPLAN_ALL>
remains on for the life of that connection, and every subsequent query on it
returns a plan instead of its rows -- well-formed rowsets, no error anywhere,
outliving the call for as long as the handle is pooled. That is a worse defect
than the missing C<EXPLAIN> this override exists to fix, and it is silent where
the original is loud. The guard does not touch the exception in flight: the
error from the explained query is what propagates.

The guard is created B<after> the C<ON> succeeded, deliberately. A C<SET> that
failed was never applied, and turning off a setting the session never got would
replace the real error with a second one.

The plan is fetched B<before> the guard fires, which is also deliberate: the
C<OFF> is a statement, and issuing one with an unfetched rowset still pending
is exactly what desynchronises a L<DBD::Sybase> connection.

=head2 Why SHOWPLAN_ALL and not SHOWPLAN_XML

Both settings suppress execution and return a plan, and either would be legal
in this hook, so the choice is argued rather than inherited from core naming
C<SHOWPLAN_ALL> in its POD.

C<SET SHOWPLAN_ALL ON> answers with a B<rowset>: a hierarchical tree of plan
rows over eighteen named columns (C<StmtText>, C<PhysicalOp>, C<LogicalOp>,
C<Argument>, C<EstimateRows>, C<TotalSubtreeCost>, ...), documented as
"intended to be used by applications written to handle its output" -- which is
what a driver is. That shape maps onto C<_explain_query>'s arrayref of row
arrayrefs as it stands, with nothing invented and nothing flattened.

C<SET SHOWPLAN_XML ON> answers with B<one XML document per batch>, so through
this hook it would arrive as a single row of a single column holding one opaque
string. ADR 0040 section 6 permits that shape -- it is what Firebird's plan
does -- but here it would be a wrapping chosen over a fit that already exists.
Its advantages are real and do not apply to this call: it is the form the
tooling ecosystem consumes, and it reaches platforms C<SHOWPLAN_ALL> is not
documented for (Azure Synapse dedicated SQL pools, Fabric warehouses). A
caller who wants the XML wants to feed it to a plan viewer, which is
native escape hatch territory (core ADR 0017) rather than
C<< $rs->explain >>.

C<SET SHOWPLAN_TEXT> is not a candidate: Microsoft describes it as the readable
form for command-prompt tools such as B<osql>, and it carries one column where
C<SHOWPLAN_ALL> carries eighteen.

=head2 What of this is verified

The B<seam> is verified against core's source (DBIO 0.900004 as installed):
the hook name and signature, that C<_explain_sql> is gone rather than
deprecated, and that L<DBIO::ResultSet/explain> strips C<as_query>'s
parentheses before the hook sees the statement.

The B<Transact-SQL facts> come from Microsoft's own C<SET SHOWPLAN_ALL> and
C<SET SHOWPLAN_XML> reference pages: that the statements are not executed while
the setting is on, that the setting must be the only statement in its batch and
cannot appear inside a stored procedure, and the column list above.

B<Over DBD::ODBC explain is refused.> Run live on 2026-10-19 (SQL Server 2022,
L<DBD::ODBC> 1.61 over the FreeTDS ODBC driver), the three round-trips below do
not give a plan there: the prepared C<SET SHOWPLAN_ALL ON> does not outlive its
prepare, so the explained query B<runs>, and its own rows would come back
looking like a plan -- well formed, no error, wrong.
L<DBIO::MSSQL::Storage::ODBC> overrides C<_explain_query> and throws ("explain
is refused ... no plan over ODBC") before sending anything; the way to a plan
is L<DBD::Sybase> (L<DBIO::MSSQL::Storage::Sybase>), where a query B<without>
placeholders returns the 18-column plan and one with placeholders dies in
execute. F<t/56-explain-query.t> pins the refusal and, offline, what the
Sybase path puts on the wire, in what order, that every statement goes through
the storage's statement path, and that the C<OFF> is issued even when the
explained query throws. Its live half (the ODBC refusal, the Sybase plan of 18
columns) is written and has not been run yet.

Two things in the Sybase path are not measured beyond that:

=over

=item *

B<the batch rule versus how the DBD prepares.> Each call to
C<_execute_rendered> is its own prepare/execute, so each statement is its own
batch -- unless the driver wraps it, as L<DBD::ODBC> evidently does for the
prepared C<SET> above.

=item *

B<how many result sets come back.> Because the query does not execute, the plan
should be the first and only rowset, which is why this method fetches once and
does not loop over C<< $sth->more_results >>. That follows from the documented
semantics rather than from an observation, and it is transport-sensitive:
L<DBD::Sybase> in particular treats a left-over result set as a desynchronised
connection.

=back

=head1 SEE ALSO

=over

=item * L<DBIO::MSSQL> - MSSQL schema component

=item * L<DBIO::MSSQL::SQLMaker> - MSSQL SQL dialect

=item * L<DBIO::MSSQL::Storage::ODBC> - MSSQL via L<DBD::ODBC>

=item * L<DBIO::MSSQL::Storage::Sybase> - MSSQL via L<DBD::Sybase>

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
