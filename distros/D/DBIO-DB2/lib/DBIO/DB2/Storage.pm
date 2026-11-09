package DBIO::DB2::Storage;
# ABSTRACT: IBM DB2 support for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

use base qw/DBIO::Storage::DBI/;
use mro 'c3';

use Carp ();
use Scalar::Util ();
use DBIO::Exception ();
use DBIO::DB2::Storage::Cursor ();

__PACKAGE__->register_driver('DB2' => __PACKAGE__);

__PACKAGE__->datetime_parser_type('DateTime::Format::DB2');
__PACKAGE__->sql_quote_char ('"');
__PACKAGE__->sql_maker_class('DBIO::DB2::SQLMaker');
__PACKAGE__->cursor_class('DBIO::DB2::Storage::Cursor');

sub sqlt_type { 'DB2' }


# lazy-default kind of thing
sub sql_name_sep {
  my $self = shift;

  my $v = $self->next::method(@_);

  if (! defined $v and ! @_) {
    $v = $self->next::method($self->_dbh_get_info('SQL_QUALIFIER_NAME_SEPARATOR') || '.');
  }

  return $v;
}



sub _connect_params_dsn {
  my ($self, $driver, $params) = @_;

  my ($dbname, $host, $port) = @{$params}{qw(dbname host port)};

  my $forms = 'DBD::DB2 connects to a cataloged database alias '
    . "(dbi:$driver:<dbname>) or, uncataloged, to a database on a server "
    . "(dbi:$driver:DATABASE=<dbname>;HOSTNAME=<host>;PORT=<port>;PROTOCOL=TCPIP)";

  $self->throw_exception(
    'Cannot build a DBD::DB2 DSN from connection parameters without a '
  . "dbname: $forms, and both need it. Give dbname, or supply a dsn instead."
  ) unless defined $dbname;

  if (defined $host) {
    $self->throw_exception(
      'Cannot build a DBD::DB2 DSN from the connection parameters dbname and '
    . "host without a port: $forms, and the uncataloged form has no implied "
    . 'port. Give port as well, leave host out to connect through the '
    . 'cataloged alias, or supply a dsn instead.'
    ) unless defined $port;

    return "dbi:$driver:DATABASE=$dbname;HOSTNAME=$host;PORT=$port;PROTOCOL=TCPIP";
  }

  $self->throw_exception(
    'Cannot build a DBD::DB2 DSN from the connection parameters dbname and '
  . "port without a host: $forms, and beside a cataloged alias the port would "
  . 'be ignored -- the catalog decides where the connection goes. Give host '
  . 'as well, leave port out, or supply a dsn instead.'
  ) if defined $port;

  return "dbi:$driver:$dbname";
}


sub _bind_host_into_dsn {
  my ($self, $driver, $dsn, $host, $port) = @_;

  return (undef, 'a DSN without a dbi:Driver: prefix')
    unless defined $dsn and $dsn =~ /^(dbi:[^:]*:)(.*)\z/is;
  my ($prefix, $rest) = ($1, $2);

  return (undef, 'a cataloged database alias; the server is not named in '
    . 'the DSN')
    if $rest =~ /^[^=;]+;*\z/;

  my @parts = split /;/, $rest, -1;
  my ($has_host, $has_port);
  for my $part (@parts) {
    next unless length $part;
    return (undef, 'a part without key=value form')
      unless $part =~ /^(\w+)=/;
    my $key = lc $1;
    $has_host = 1 if $key eq 'hostname';
    $has_port = 1 if $key eq 'port';
  }

  return (undef, 'a DSN without HOSTNAME=; the server is not named in the DSN')
    unless $has_host;

  my @out;
  for my $part (@parts) {
    if ($part =~ /^(hostname)=/i) {
      push @out, "$1=$host";
      push @out, "PORT=$port" if defined $port and not $has_port;
    }
    elsif (defined $port and $part =~ /^(port)=/i) {
      push @out, "$1=$port";
    }
    else {
      push @out, $part;
    }
  }

  return $prefix . join ';', @out;
}


# the class core blesses its HandleError into, to tell it from a foreign one
my $CORE_ERROR_HANDLER_CLASS = '__DBIO__DBH__ERROR__HANDLER__';

sub _connect {
  my $self = shift;

  my $dbh = $self->next::method(@_);

  return $dbh if $self->unsafe;

  my $core_handler = $dbh->{HandleError};

  # core installs its handler anew on every _connect, so this never wraps a
  # wrapper; anything else on the handle is not ours to touch
  if (ref $core_handler eq $CORE_ERROR_HANDLER_CLASS) {
    # DBD::DB2 leaves Statement empty on a handle for do(), and the SQL0605W
    # message names the index that is already there, not the one refused: keep
    # the text of the last do() for the warning (karr k47)
    my $last_do;
    my $user_do = $dbh->{Callbacks} && $dbh->{Callbacks}{do};
    $dbh->{Callbacks} = {
      %{ $dbh->{Callbacks} || {} },
      do => sub { $last_do = $_[1]; return $user_do ? $user_do->(@_) : () },
    };

    $dbh->{HandleError} = bless sub {
      # true = handled: DBI raises nothing and returns the method's value
      return 1 if ($_[1]->state // '') =~ /^01/;
      # SQL0605W is a warning with an error state (42S11): no index made, as
      # one is already there (karr k47, ADR 0010)
      return _index_exists_warning($_[1], $last_do) if ($_[1]->state // '') eq '42S11'
        && ($_[1]->err // 0) == 605;
      return $core_handler->(@_);
    }, $CORE_ERROR_HANDLER_CLASS;
  }

  return $dbh;
}

# CREATE INDEX over columns an index already covers: SQL0605W, err 605, state
# 42S11 (not class 01, so the wrapper above does not take it), rv undef, no
# index made. It is no failure of the statement's purpose -- the columns are
# indexed -- so it is a warning naming index and table, and handled (true).
sub _index_exists_warning {
  my ($h, $last_do) = @_;
  my $id = qr/"(?:[^"]|"")+"|[^\s("]+/;
  my ($index, $table) = ($h->{Statement} // $last_do // '')
    =~ /\bINDEX\s+($id)\s+ON\s+($id)/i;
  Carp::carp(sprintf 'DBIO::DB2: index %s on table %s was not created: %s',
    $index // '(unknown)', $table // '(unknown)', $h->errstr // 'SQL0605W');
  return 1;
}

sub dbio_deploy_class { 'DBIO::DB2::Deploy' };

# F02 / F10 -- transactional DDL. This 0 is NOT the MySQL/Oracle kind, and the
# comment exists because judged by the engine alone it looks like one.
#
# Db2 LUW HAS transactional DDL. The COMMIT statement is the primary source and
# it says so by listing what a commit is FOR: "All changes made by the
# following statements executed during the unit of work are committed: ALTER,
# COMMENT, CREATE, DROP, GRANT, LOCK TABLE, REVOKE, SET INTEGRITY, and the data
# change statements (INSERT, DELETE, MERGE, UPDATE), including those nested in
# a query" (Db2 for Linux, UNIX and Windows SQL Reference, COMMIT statement,
# unchanged in 11.5.x and 12.1.x). A statement whose changes a COMMIT commits
# was uncommitted before it -- CREATE and DROP are in that list by name. The
# same topic names the rollback direction in passing: "The statement might be
# implicitly prepared again, as a result of DDL operations that are rolled back
# within the unit of work." ROLLBACK closes it: "All changes made to the
# database during the unit of work are backed out", with an exception list that
# holds only SET statements, sequence/identity values and global variables and
# no DDL at all, and -- for the savepoint form -- "Data and schema changes made
# since the savepoint was set are undone" (same Reference, ROLLBACK statement,
# both versions).
#
# It is an ENGINE fact, not a deployment fact. CLI/ODBC ships autocommit on
# ("AutoCommit = 1 | 0 ... Specifies whether the application commits each
# statement by default ... 1 = SQL_ATTR_AUTOCOMMIT_ON (default)", AutoCommit
# CLI/ODBC configuration keyword), but that is a DEFAULT for applications that
# never say otherwise -- the same topic warns about "overriding this default
# during runtime", which is precisely what txn_do does when it sets DBI's
# AutoCommit to 0 on the connection. No db2cli.ini or db2dsdriver.cfg setting
# can make the answer below true or false.
#
# Nor is there a per-statement exception to declare. The COMMIT topic singles
# out the statements that "behave differently than other data definition
# language (DDL) and data control language (DCL) statements ... only one of
# these statements is allowed within any one unit of work", and the list is
# CREATE/ALTER/DROP of SERVICE CLASS, THRESHOLD, WORK ACTION, WORK CLASS and
# WORKLOAD plus GRANT/REVOKE of workload privileges. This driver emits none of
# them, so _ddl_statement_is_transactional stays core's default.
#
# WHAT THE 0 IS FOR, then, is this driver's own deploy path. DB2 needs an
# existing database, so only a SCHEMA can be throwaway, and
# DBIO::DB2::Deploy::_build_target_model therefore deploys the compare schema
# through $self->_dbh -- the handle the storage itself owns. Every other
# transactional engine in this family (PostgreSQL, SQL Server, Firebird) builds
# its target model through DBIO::Deploy::Base::TempDatabase, which opens its
# own connection, and core deliberately never brackets a handle the storage
# does not own (_storage_owns_dbh). Oracle and Informix build on the live
# handle as this driver does, but their engines commit DDL implicitly, so DB2
# is the only driver in the family where a transactional engine and a
# throwaway build on the bracketable handle meet.
#
# That matters because the capability is read in two places, not one.
# DBIO::Deploy::Base::_execute_ddl would bracket only the migration DDL, which
# is exactly what a 1 is for -- but DBIO::DeploymentHandler::upgrade wraps its
# WHOLE body in txn_do, and that body is deploy_method->upgrade, i.e. diff THEN
# apply. So a 1 here does not merely make the migration atomic: it pulls
# CREATE SCHEMA DBIO_TEST_<pid>, the entire install DDL re-emitted into it, the
# SYSCAT introspection of it and the teardown DROPs into the same live unit of
# work as the migration -- a long transaction holding catalog locks open for
# throwaway work whose atomicity buys nothing.
#
# And none of it has been measured. No live Db2 was available when this was
# written, so two things behind a 1 are reasoned only. First, the diff's FK
# change is a drop-then-add PAIR on one name (DBIO::DB2::Diff::ForeignKey:
# ALTER TABLE t DROP FOREIGN KEY fk, then ALTER TABLE t ADD CONSTRAINT fk),
# which under a bracket lands in one unit of work; Db2 for z/OS has a code for
# exactly that shape -- "-679 THE OBJECT name CANNOT BE CREATED BECAUSE A DROP
# IS PENDING ON THE OBJECT" -- and no equivalent could be found in the LUW
# message set, which is not the same as knowing there is none. Second, the
# compare schema is created and dropped again inside what would become one unit
# of work. Both are cheap to settle against a server and impossible to settle
# without one.
#
# So: capable engine, deliberate no -- the SQLite entry in
# DBIO::Deploy::Base's TRANSACTIONAL DDL section, not the MySQL one. That
# section still lists DB2 beside MySQL and Oracle under "Implicit COMMIT on
# DDL"; the COMMIT and ROLLBACK topics quoted above say that grouping is wrong,
# and correcting it is core's to do. The price of the 0 is core's one-time
# "non-transactional DDL" notice, and what it says about RECOVERY is true here:
# an apply that fails part way leaves the earlier statements applied, and the
# way back is re-running the upgrade, whose diff is recomputed against live
# state. Value and declaredness are pinned by t/42-deploy-transactional-ddl.t.
__PACKAGE__->_use_transactional_ddl(0);

# The one-row catalog view DB2 offers "for SQL statements in which a table
# reference is required, but the contents of the table are not important" (SQL
# Reference, SYSIBM.SYSDUMMY1). The name lives here once and is read twice:
# _dbh_last_insert_id selects IDENTITY_VAL_LOCAL() from it (ADR 0002), and
# _exists_value_sql needs it to give core's FROM-less EXISTS rendering a FROM
# clause (ADR 0037).
#
# $name_sep is the qualifier separator the *server* reported, and only the
# identity path can pass it: it is called with a $dbh in hand, so sql_name_sep
# may probe. _exists_value_sql must not -- it is a static class fact (ADR 0037
# section 2, ADR 0039 section 7: DBIO::ResultSet bakes the answer into the
# query while it is being built, so a probe there would open a connection
# during query build), and it takes the default '.', which is the separator
# every IBM SQL Reference spells this table with.
sub _dummy_table {
  my ($self, $name_sep) = @_;

  $name_sep = '.' unless defined $name_sep;

  return "SYSIBM${name_sep}SYSDUMMY1";
}

sub _dbh_last_insert_id {
  my ($self, $dbh, $source, $col) = @_;

  my $name_sep = $self->sql_name_sep;

  my $sth = $dbh->prepare_cached(
    # An older equivalent of 'VALUES(IDENTITY_VAL_LOCAL())', for compat
    # with ancient DB2 versions. Should work on modern DB2's as well:
    # http://publib.boulder.ibm.com/infocenter/db2luw/v8/topic/com.ibm.db2.udb.doc/admin/r0002369.htm?resultof=%22%73%79%73%64%75%6d%6d%79%31%22%20
    'SELECT IDENTITY_VAL_LOCAL() FROM ' . $self->_dummy_table($name_sep),
    {},
    3
  );
  $sth->execute();

  my @res = $sth->fetchrow_array();

  return @res ? $res[0] : undef;
}

# ADR 0037 -- the complete 1/0 statement behind DBIO::ResultSet::results_exist
# and its two siblings. Core's base rendering has no FROM clause at all and
# DB2's subselect has no FROM-less form, so the statement gets the one-row
# catalog view above. Only the dummy table is ours -- the CASE spelling stays
# core's, so there is one copy of it.
sub _exists_value_sql {
  my $self = shift;

  return $self->next::method(@_) . ' FROM ' . $self->_dummy_table;
}

# ... and the capability that lets core call the above at all. Not vacuous
# next to the override: it is this driver asserting that somebody checked the
# rendering against DB2, which is why the default is 0 and why declaring is a
# separate act from overriding.
__PACKAGE__->_use_supports_exists_query (1);

# ADR 0039 -- _set_operation_keyword is deliberately NOT overridden. DB2 has
# all six set operations and spells each one the way core's base map already
# answers, so there is nothing for this driver to say. The reasoning, the IBM
# sources and the Db2-for-i caveat are in the DESCRIPTION above;
# t/51-set-operations.t pins all six so the claim can fail.

# karr k22 -- the function DBIO::ResultSet::rand drops into an order_by
# literal. Core answers RANDOM(), which PostgreSQL and SQLite have and the Db2
# LUW SQL Reference documents nowhere: the name resolves to no routine at all
# and the server says so (SQL0440N, SQLSTATE 42884). RAND (SYSFUN schema) is
# the one it does document.
#
# WITH parentheses, unlike Oracle's DBMS_RANDOM.VALUE -- this is a scalar
# function, and its zero-argument form is still an invocation. Without a seed
# on purpose: a seed makes the sequence repeat per query, which is a
# repeatable order rather than a shuffle. A static class fact like the base
# hook -- no $dbh, no version probe.
sub _random_function { 'RAND()' }

# The schema the SECOND statement of _explain_query reads its rows from,
# because DB2 has two documented places to put the explain tables and the
# driver cannot tell which one is in use without asking. SYSTOOLS is the
# default because SYSPROC.SYSINSTALLOBJECTS -- IBM's preferred route -- creates
# them there, and because the Explain facility falls back to SYSTOOLS when the
# session's own schema has none. A session whose own schema DOES carry explain
# tables is written to there and must set this, or the read-back looks in the
# wrong place. Details and the failure modes: DESCRIPTION above.
#
# Qualified with a plain ".", for the same reason _dummy_table defaults to one:
# the separator every IBM SQL Reference spells a catalog name with, and reading
# the server-reported sql_name_sep instead would mean probing to build a
# statement string.
__PACKAGE__->mk_group_accessors('inherited' => qw/explain_table_schema/);
__PACKAGE__->explain_table_schema('SYSTOOLS');

# karr k22 / ADR 0040 -- the WHOLE operation of obtaining a query plan, which
# on DB2 is two statements and is one of the shapes core widened this seam from
# the string-valued _explain_sql for.
#
# Core's inherited operation is "EXPLAIN <query>", which is not this engine's
# statement: DB2's is EXPLAIN PLAN SELECTION FOR (the bare PLAN is documented
# only as syntax toleration for z/OS, "there is no PLAN table"). And the
# spelling is the smaller half -- the statement ANSWERS WITH NOTHING. It writes
# the access plan into the EXPLAIN_* tables and does not execute the statement
# it explains, so the plan has to be read back by a second statement of this
# driver's own. There is no in-SQL formatter to call: db2exfmt and db2expln are
# OS commands outside DBI, and IBM's own documentation points at querying the
# explain tables instead.
#
# BOTH statements go through _execute_rendered, which ADR 0040 section 3 makes
# a requirement of the contract with no engine-named exceptions -- including
# the second one, which carries no user data but everything else: tracing and
# therefore redact_bind_value (ADR 0025) over the query's own WHERE-clause
# values, dbh_do retry over a dropped connection, NoBindVars interpolation, and
# the read handler rather than the master's on a replicated storage.
sub _explain_query {
  my ($self, $sql, $bind) = @_;

  # An identifier (core k391, ADR 0077): through the driver's quoting, as
  # stored in the catalog, never joined raw into the statement.
  my $maker = $self->sql_maker;
  my $operators = $maker->_quote($self->explain_table_schema)
                . '.' . $maker->_quote('EXPLAIN_OPERATOR');

  # Not a micro-optimisation dodge: the explain tables are populated when the
  # EXPLAIN statement is COMPILED, and executing it "will perform no
  # processing" (SQL Reference). DBI's prepare_cached returns a cached handle
  # without preparing again, so a repeated explain of the same query would
  # write no new plan -- and the read-back below, which can only ask for the
  # newest one, would hand back whatever was explained last instead. Same
  # statement, plausible rows, no error: silent. local, so it survives an
  # exception out of either statement.
  local $self->{disable_sth_caching} = 1;

  # Writes the plan and returns no rows. The query's binds travel with it:
  # EXPLAIN parses the statement, so its parameter markers are the statement's
  # own and have to be supplied.
  $self->_execute_rendered("EXPLAIN PLAN SELECTION FOR $sql", $bind);

  # ... so the plan comes from here: one row per plan operator, in operator
  # order, with the optimizer's cost columns. Keyed on the newest explain of
  # this authorization ID because the explain tables are ordinary persistent
  # tables with no session column -- the narrowest key DB2 offers, and the
  # race it leaves is named in the DESCRIPTION rather than papered over.
  my (undef, $sth) = $self->_execute_rendered (
    'SELECT OPERATOR_ID, OPERATOR_TYPE, TOTAL_COST, IO_COST, CPU_COST'
  . " FROM $operators"
  . ' WHERE EXPLAIN_REQUESTER = SESSION_USER'
  . " AND EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM $operators"
  . ' WHERE EXPLAIN_REQUESTER = SESSION_USER)'
  . ' ORDER BY OPERATOR_ID',
    [],
  );

  return $sth->fetchall_arrayref;
}



sub deploy_setup { }



sub insert {
  my ($self, $source, $to_insert, $opts) = @_;

  return $self->next::method($source, $to_insert, $opts)
    if $to_insert and %$to_insert;

  my $infos = $source->columns_info;
  my ($col) = grep { $infos->{$_}{is_auto_increment} } $source->columns;
  ($col) = $source->columns unless defined $col;
  return $self->next::method($source, $to_insert, $opts) unless defined $col;

  my $returned = $self->next::method($source, { $col => \'DEFAULT' }, $opts);
  delete $returned->{$col}
    if ref $returned->{$col} eq 'SCALAR' and ${ $returned->{$col} } eq 'DEFAULT';
  return $returned;
}


sub bind_attribute_by_data_type {
  my ($self, $data_type) = @_;
  return { TYPE => -99 }
    if defined $data_type && $data_type =~ /\A\s*(?:clob|dbclob|(?:tiny|medium|long)?text)\s*\z/i;
  return $self->next::method($data_type);
}


sub select_single {
  my $self = shift;
  my ($rv, $sth, @bind) = $self->_select(@_);
  my @row = $sth->fetchrow_array;
  my @nextrow = $sth->fetchrow_array if @row;
  if (@row && @nextrow) {
    Carp::carp('Query returned more than one row.  SQL that returns multiple rows is DEPRECATED for ->find and ->single');
  }
  DBIO::DB2::Storage::Cursor->decode_rows($self, $sth, \@row);
  $sth->finish();
  return @row;
}


sub _utf8_database {
  my ($self) = @_;
  return $self->{_db2_utf8_database} //= do {
    my ($set) = eval {
      $self->dbh_do(sub { $_[1]->selectrow_array(
        q{SELECT value FROM sysibmadm.dbcfg WHERE name = 'codeset'}) });
    };
    (defined $set && $set =~ /utf-?8/i) ? 1 : 0;
  };
}

# The table a bind list is about, for a message: the name of the source of an
# insert, update or delete, or the first table of the FROM of a select.
sub _ident_table_name {
  my ($self, $ident) = @_;
  if (Scalar::Util::blessed($ident) && $ident->can('name')) {
    my $name = $ident->name;
    return ref $name eq 'SCALAR' ? $$name : $name;
  }
  if (ref $ident eq 'ARRAY' && ref $ident->[0] eq 'HASH') {
    # the FROM of a select: [ { -alias => 'me', -rsrc => $source }, ... ]
    return $self->_ident_table_name($ident->[0]{'-rsrc'}) if $ident->[0]{'-rsrc'};
  }
  return defined $ident && !ref $ident ? $ident : 'the table';
}


my $CLOB_COMPARE_MAX = 32672;

sub _prep_for_execute {
  my ($self, $op, $ident, $args) = @_;
  my ($sql, $bind) = $self->next::method($op, $ident, $args);

  for my $b (@{ $bind || [] }) {
    my ($meta, $value) = @$b;
    next unless ref $meta eq 'HASH' && defined $value && !length ref $value;
    my $type = lc($meta->{sqlt_datatype} // '');
    my $column = $meta->{dbic_colname} // '?';

    DBIO::Exception->throw(sprintf
      'DBIO::DB2::Storage: %s on table "%s" is refused: column "%s" gets an empty string, which '
      . 'DBD::DB2 reads back as NULL from a BLOB column; the value would not survive',
      $op, $self->_ident_table_name($ident), $column)
      if $type eq 'blob' && $value eq '' && ($op eq 'insert' || $op eq 'update');

    if (($op eq 'select' || $op eq 'delete') && $self->bind_attribute_by_data_type($type)) {
      utf8::encode(my $bytes = $value);
      DBIO::Exception->throw(sprintf
        'DBIO::DB2::Storage: %s on table "%s" is refused: column "%s" is compared with a value of '
        . '%d bytes, and Db2 cannot compare a CLOB with more than %d bytes (SQL0433N)',
        $op, $self->_ident_table_name($ident), $column, length $bytes, $CLOB_COMPARE_MAX)
        if length $bytes > $CLOB_COMPARE_MAX;
    }
  }

  return ($sql, $bind);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::Storage - IBM DB2 support for DBIO

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Storage driver for IBM DB2 databases. Handles autoincrement column retrieval
via C<IDENTITY_VAL_LOCAL()>, queries the server name separator from L<DBI>,
and sets the datetime parser to L<DateTime::Format::DB2>.

Uses L<DBIO::DB2::SQLMaker> for SQL generation with DB2-specific LIMIT/OFFSET
support (C<ROW_NUMBER() OVER()> for OFFSET, C<FETCH FIRST n ROWS ONLY> otherwise).

=head2 Existence queries

L<DBIO::ResultSet/results_exist> and its two siblings work here because this
class declares the C<supports_exists_query> capability (ADR 0037). Core
defaults that capability to C<0> and throws on all three methods without it,
rather than degrading silently to L<DBIO::ResultSet/has_rows> -- which stays
the portable alternative for callers that must also run against a driver which
has not declared it.

Declaring it alone would not be enough: core's base rendering of
L<DBIO::Storage::DBI/_exists_value_sql> is
C<SELECT CASE WHEN EXISTS E<lt>innerE<gt> THEN 1 ELSE 0 END>, a C<SELECT> with
no C<FROM> clause, and DB2's C<subselect> has no C<FROM>-less form. The
override appends C<FROM SYSIBM.SYSDUMMY1> -- the one-row catalog view IBM
provides for exactly this, "for SQL statements in which a table reference is
required, but the contents of the table are not important" (SQL Reference,
I<SYSIBM.SYSDUMMY1>) -- and leaves the C<CASE> spelling to core, so there is
one copy of it. It is the same table C<_dbh_last_insert_id> already selects
C<IDENTITY_VAL_LOCAL()> from (ADR 0002), and both now read the name from
L</_dummy_table> rather than spelling it twice.

The C<CASE> half needs nothing from this driver: a searched C<CASE>'s C<WHEN>
takes a I<search-condition>, and C<EXISTS> is a predicate, so core's base
spelling is already the DB2 one -- only the missing C<FROM> was ever the gap.

=head2 Set operations: all six, and no keyword to declare

This driver overrides B<nothing> in
L<DBIO::Storage::DBI/_set_operation_keyword>: DB2 has all six set operations
and spells each of them the ANSI way core's base map already answers with, so
all of L<union|DBIO::ResultSet/union>,
L<union_all|DBIO::ResultSet/union_all>,
L<intersect|DBIO::ResultSet/intersect>,
L<intersect_all|DBIO::ResultSet/intersect_all>,
L<except|DBIO::ResultSet/except> and
L<except_all|DBIO::ResultSet/except_all> are inherited (ADR 0039). That is a
finding, not an omission, and F<t/51-set-operations.t> pins all six so it can
fail if it ever stops being true.

Sourced rather than assumed: the C<fullselect> production in the Db2 for
Linux, UNIX and Windows SQL Reference offers
C<UNION | UNION ALL | EXCEPT | EXCEPT ALL | INTERSECT | INTERSECT ALL>, and
does so unchanged from 9.7 (2009) through 12.1. Db2 for z/OS 12 documents the
same six.

DB2 also I<accepts> C<MINUS>: "For compatibility with other SQL
implementations, MINUS can be specified as a synonym for EXCEPT" (same
section, both platforms). That widens what the parser takes; it does not
change what the engine is spelled. C<EXCEPT> is the primary spelling of the
syntax diagram in every documented version and there is no mode in which it
stops being one, so there is no second per-engine spelling here for
C<_set_operation_keyword> to carry.

B<Db2 for i is the one Db2 that does not have all six> -- its C<fullselect>
offers C<UNION [DISTINCT|ALL]> but only C<EXCEPT [DISTINCT]> and
C<INTERSECT [DISTINCT]>, with no C<ALL> form of either and no C<MINUS>
synonym (IBM i 7.5 SQL Reference, I<fullselect>). It is not refused here
because it is not a platform this distribution supports at all: every
introspection and deployment query in L<DBIO::DB2::Introspect> and
L<DBIO::DB2::Deploy> reads the C<SYSCAT> catalog views, which exist on Db2
LUW and on neither Db2 for i nor Db2 for z/OS. Refusing C<except_all> and
C<intersect_all> outright -- the only shape ADR 0039 section 7 would allow,
since the platform is no more askable without a connection than a version is
-- would withdraw two working operations from every server this driver can
actually be used against, to protect one it cannot.

=head2 Random ordering

L<DBIO::ResultSet/rand> asks the storage which function this engine spells
"give me a random number" with (L<DBIO::Storage::DBI/_random_function>) and
drops the answer into an C<order_by> literal. Core answers C<RANDOM()>, which
is right on PostgreSQL and SQLite and which the Db2 for Linux, UNIX and
Windows SQL Reference does not document at all -- there is no such routine for
the name to resolve to, and the server says so (SQL0440N, SQLSTATE 42884: no
authorized routine of that name was found). This class overrides the hook with
C<RAND()>, the SYSFUN scalar function that Reference I<does> document.

The parentheses stay, unlike Oracle's argument-less C<DBMS_RANDOM.VALUE>:
C<RAND> is an ordinary scalar function and its zero-argument form is still an
invocation. No seed is passed, and that is deliberate rather than an omission:
"A specific seed value produces the same sequence of random numbers for a
specific instance of a RAND function in a query each time the query is
executed" (SQL Reference, I<RAND (SYSFUN schema) scalar function>), so a
seeded C<ORDER BY> is a I<repeatable> order -- the one thing
L<DBIO::ResultSet/rand> must not be.

Db2 for z/OS is the one platform of the family where core's inherited answer
would have worked: it documents C<RANDOM> as a synonym of C<RAND>. LUW is the
platform this distribution supports (its whole introspection path reads
C<SYSCAT>, see above), so the LUW spelling is the one that counts here.

C<RAND()> is evaluated B<per row>. The Reference calls it "a non-deterministic
function" and says the seed "is used only for the first invocation of an
instance of the RAND function within a statement", which describes a function
invoked repeatedly within one statement, but no documented sentence says
outright that C<ORDER BY RAND()> shuffles -- so it is measured instead: the
live half of F<t/52-explain-query.t> saw four runs come back in different
orders on Db2 12.1.5. The failure mode this guards against is B<silent>, not
loud: an engine that evaluated its random function once per statement would
sort every row by the same number and C<< $rs->rand >> would quietly return an
unshuffled prefix.

=head2 Query plans

L<DBIO::ResultSet/explain> asks the storage for the B<whole operation> of
obtaining a query plan through L<DBIO::Storage::DBI/_explain_query> (ADR 0040,
which replaced the string-valued C<_explain_sql>). DB2 is one of the engines
that argument was made for: obtaining a plan here is B<two> statements, and
this class overrides the hook with both of them.

The first is C<EXPLAIN PLAN SELECTION FOR E<lt>queryE<gt>>, carrying the
query's own bind values -- "if EXPLAIN is being dynamically prepared, the
explainable-sql-statement can contain parameter markers" (SQL Reference,
I<EXPLAIN statement>). C<PLAN SELECTION> rather than the bare C<PLAN> Oracle
uses: on LUW the Reference marks C<PLAN> as supported "only for syntax
toleration of existing Db2 for z/OS EXPLAIN statements. There is no PLAN
table", equivalent to C<PLAN SELECTION>, which is the native spelling and the
one this driver emits.

That statement B<answers with nothing>. It writes the access plan into the
C<EXPLAIN_*> tables, and the statement it explains "is not executed" (same
topic), so the plan comes from a B<second> statement of this driver's own,
which core never rendered and knows nothing about:

  SELECT OPERATOR_ID, OPERATOR_TYPE, TOTAL_COST, IO_COST, CPU_COST
    FROM SYSTOOLS.EXPLAIN_OPERATOR
   WHERE EXPLAIN_REQUESTER = SESSION_USER
     AND EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM SYSTOOLS.EXPLAIN_OPERATOR
                          WHERE EXPLAIN_REQUESTER = SESSION_USER)
   ORDER BY OPERATOR_ID

one row per plan operator, in operator order, with the optimizer's cost
columns (C<EXPLAIN_OPERATOR> table, SQL Reference). DB2 has no in-SQL
formatter to hand the way Oracle has C<DBMS_XPLAN.DISPLAY>: its formatters,
C<db2exfmt> and C<db2expln>, are OS commands outside DBI entirely, and IBM's
own documentation points at writing a query against the explain tables
instead. The plan I<tree> -- which operator feeds which -- lives in
C<EXPLAIN_STREAM> and is not folded in here; ADR 0040 section 2 already says
the contents of these rows are engine-specific and that nothing in DBIO
normalises them.

Both statements go through L<DBIO::Storage::DBI/_execute_rendered>, which the
contract requires without engine-named exceptions. That is what keeps tracing
and therefore L<DBIO::Storage::DBI/redact_bind_value> (ADR 0025) over the
query's own bind values, C<dbh_do> retry over a dropped connection,
L<DBIO::Storage::DBI::NoBindVars> interpolation, and -- on a
L<DBIO::Replicated::Storage> -- the read handler instead of the master's.

=head3 What the session needs, and what happens when it does not have it

The explain tables must already exist; nothing here creates them. IBM's
preferred route is

  CALL SYSPROC.SYSINSTALLOBJECTS('EXPLAIN', 'C',
          CAST (NULL AS VARCHAR(128)), CAST (NULL AS VARCHAR(128)))

which creates them under C<SYSTOOLS>; F<EXPLAIN.DDL> from the instance's
F<sqllib/misc> creates them under the current schema instead. Without them the
B<first> statement fails (SQLSTATE 42704 -- the Reference's own Example 4 is
this case) and the exception propagates out of C<< $rs->explain >>: there is
no degraded mode answering an empty plan.

Which schema the second statement reads is L</explain_table_schema>, C<SYSTOOLS>
by default, because that is where C<SYSINSTALLOBJECTS> puts them and where the
Explain facility looks when the session's own schema has none. B<A session
whose own schema carries explain tables must set it>, since the facility then
writes I<there>: reading the wrong set is the one failure here that can be
quiet rather than loud -- loud (SQLSTATE 42704) if the configured schema has no
explain tables at all, quiet if it has some, holding somebody else's plan.

=head3 The plan is written at compile time, which is why caching is off

"For dynamic EXPLAIN statements, the explain tables are populated at the time
the EXPLAIN statement is submitted for compilation. An EXPLAIN statement can
be prepared with the PREPARE statement but, if executed, will perform no
processing" (SQL Reference, I<EXPLAIN statement>). The B<prepare> does the
work; the execute is a successful no-op. So C<_explain_query> turns
L<DBIO::Storage::DBI/disable_sth_caching> on for the duration of the pair:
C<DBI>'s C<prepare_cached> hands back a cached handle B<without preparing
again>, which on this engine means no new plan is written -- and the
read-back, which can only ask for the newest plan, would then answer with
whatever was explained last. Identical statement, identical plan, no error:
exactly the silent wrong answer that is worth a line of code to avoid.

=head3 What is verified, and what is not

The B<seam> is verified against core's source: the hook's name and signature,
that C<_explain_sql> is gone rather than deprecated, that
L<DBIO::ResultSet/explain> strips C<as_query>'s parentheses before handing the
statement over, and that F<t/52-explain-query.t> sees both statements reach
the storage layer.

B<DB2's half is not.> No live server was available; every spelling above comes
from the Db2 11.5 SQL Reference topics named beside it, and none of it has been
executed against a server from this driver. Two things in particular are
reasoned rather than observed: that C<EXPLAIN_OPERATOR> is the closest
in-SQL answer to what C<explain> promises, and that keying the read-back on
C<< MAX(EXPLAIN_TIME) >> per C<SESSION_USER> selects the plan just written --
the explain tables are ordinary persistent tables with no session column, so a
concurrent explain by the B<same> authorization ID in another session, landing
between the two statements, would win that C<MAX>. There is no narrower key to
use: C<QUERYNO> and C<QUERYTAG> tag the row in C<EXPLAIN_STATEMENT> but are
neither unique nor carried on C<EXPLAIN_OPERATOR>, so they would buy an
eight-column join and no additional certainty.

=head1 METHODS

=head2 sql_name_sep

Returns the name separator character used by this DB2 server (e.g. C<.>),
queried from the server via C<SQL_QUALIFIER_NAME_SEPARATOR> on first access.

=head2 _connect_params_dsn

The DSN seam of L<DBIO::Storage::DBI/_connect_params_dsn> (ADR 0057),
overridden because L<DBD::DB2> takes nothing of core's default form
C<dbi:DB2:dbname=...;host=...;port=...>. It connects in one of two ways, and
which one the connection parameters mean is decided by C<host>:

=over

=item * B<cataloged> -- C<dbname> alone

  dbi:DB2:<dbname>

C<dbname> is a database alias the client's database directory resolves; where
the server is, the catalog knows.

=item * B<uncataloged> -- C<dbname>, C<host> and C<port>

  dbi:DB2:DATABASE=<dbname>;HOSTNAME=<host>;PORT=<port>;PROTOCOL=TCPIP

a CLI connection string naming the server itself. User and password are not
put into it as C<UID=>/C<PWD=>: they stay the arguments of
C<< DBI->connect >>, as with every other connect form.

=back

Everything else refuses rather than guess, each error naming what is missing
and the ways out:

=over

=item * C<host> without C<port>. DB2 has no implied port -- an instance
listens on whatever its C<SVCENAME> says -- so there is none to default to.

=item * C<port> without C<host>. Beside a cataloged alias a port means
nothing: the catalog's node entry holds it. Dropping the one given would
connect to wherever the catalog says, silently.

=item * no C<dbname>. Both forms need it; there is no default database.

=back

Anything these three parts cannot say -- C<SECURITY=SSL>, any further CLI
keyword -- goes in as the whole DSN: as C<dsn>, or as a C<dbname> that starts
with C<dbi:DB2:> (L<DBIO::AccessBroker::Static> passes it on), which core
takes as the DSN before this seam is asked.

B<Verified against a server> (Db2 12.1.5, L<DBD::DB2> 1.92 on the IBM CLI
driver; F<t/54-connect-params-dsn-live.t>): the driver accepts both strings
exactly as built here -- the uncataloged form without the spaces and the
trailing C<;> its own example carries, the cataloged form with the alias
resolved from a F<db2dsdriver.cfg>. An alias out of a full client's database
directory (C<db2 catalog database>) was not seen; the CLI driver has no such
directory.

=head2 _bind_host_into_dsn

The HostBound seam of L<DBIO::Storage::DBI/_bind_host_into_dsn> (core ADR 0013
addendum), overridden because core's default knows C<host=>/C<port=>
and declines DB2's C<HOSTNAME=>.

  dbi:DB2:DATABASE=d;HOSTNAME=h;PORT=50000;PROTOCOL=TCPIP

The rule: the parts after C<dbi:DB2:> must all be C<key=value>, and one of them
must be C<HOSTNAME> (keys are case-insensitive; their spelling is kept).
C<HOSTNAME=> takes the view's host where it stands. C<PORT=> takes the view's
port where it stands; when the view has a port and the DSN has no C<PORT=>, one
is put right after C<HOSTNAME=>, and when the view has no port the DSN's
C<PORT=> stays. Nothing else is touched -- C<PROTOCOL=> is not invented.

It declines, naming the form and never a value of the DSN:

=over

=item * a DSN without a C<dbi:Driver:> prefix;

=item * a part that is not C<key=value>;

=item * a DSN without C<HOSTNAME=> -- a cataloged alias (C<dbi:DB2:testdb>)
leaves the server to the client's catalog, so there is nothing to rebind.

=back

=head2 _connect

Wraps the C<HandleError> that L<DBIO::Storage::DBI> installs on every handle,
so that B<a server warning is not an exception> (ADR 0007).

L<DBD::DB2> reports C<SQL_SUCCESS_WITH_INFO> the way it reports an error: it
sets C<err> to a true value, where the L<DBI> contract has C<"0"> or C<""> for
a warning. With C<RaiseError> and core's handler the statement that just ran
then throws. The case that was measured (Db2 12.1.5, L<DBD::DB2> 1.92) is a
C<DELETE> or C<UPDATE> without a C<WHERE> clause:

  DELETE FROM "t"    -- rv 3, err 513, SQLSTATE 01504,
                     -- SQL0513W The SQL statement will modify an entire
                     -- table or view

The rows are deleted, C<< $rs->delete >> on an unrestricted resultset threw
all the same, and inside a C<txn_do> the exception rolled the delete back.

SQLSTATE says which of the two a message is. Class C<01> is "completed, with a
warning", so the wrapper answers a message of that class as handled and hands
every other one to core's handler, which throws C<DBI Exception: ...> as
before. Three things follow, and they are meant:

=over

=item * B<The warning is silent.> Nothing is printed and nothing is thrown.
It is not lost: C<err>, C<state> and C<errstr> stay on the handle until its
next call, for a caller who wants to know.

  my $rows = $storage->dbh_do(sub {
    my ($storage, $dbh) = @_;
    my $rv = $dbh->do('DELETE FROM "t"');
    warn $dbh->errstr if $dbh->state =~ /^01/;
    $rv;
  });

=item * B<It is the class, not the one state.> Every C<01xxx> message passes,
not only C<01504>; that one is the only member of the class seen so far.

=item * B<The return value is not looked at.> A class C<01> message beside an
C<undef> return value is passed on as well: C<undef> is what a C<NULL> looks
like to C<selectrow_array>, and the state is the server's word on the outcome.
Where DBIO itself needs a true value -- after C<execute> -- core still throws
on a false one, with the handle's C<errstr>.

=back

The seam is C<_connect> because every handle of this storage is made there: a
DSN connect, a connection coderef, an L<DBIO::AccessBroker>, and each
reconnect. Statements run on the raw handle are covered too --
L<DBIO::Storage::DBI/dbh_do>, and the C<do> calls of L<DBIO::DB2::Deploy>. The
wrapper keeps the blessing core tells its own handler by, so a handle that
comes back through a connection coderef a second time is not refused as
carrying a foreign C<HandleError>.

B<SQL0605W is a warning too, and it is reported.> C<CREATE INDEX> over a column
sequence that an index, a C<UNIQUE> constraint or the primary key already has
answers err C<605>, SQLSTATE C<42S11> -- an error class although the message is
a warning -- and creates nothing. The wrapper handles it (no exception) and
C<carp>s a message with the index and table of the statement; the DDL emitters
normally leave such an index out beforehand (ADR 0010).

B<With C<unsafe> nothing is installed.> Core installs no handler there and
this method adds none: under L<DBIO::Storage::DBI/unsafe> the error handling
is the caller's, and with C<RaiseError> on a C<DELETE> without C<WHERE> dies
there as it does in plain L<DBI>.

=head2 explain_table_schema

    DBIO::DB2::Storage->explain_table_schema('MYSCHEMA');
    $storage->explain_table_schema('MYSCHEMA');

The schema holding the C<EXPLAIN_*> tables that C<< $rs->explain >> reads its
plan back from. Defaults to C<SYSTOOLS>, where C<SYSPROC.SYSINSTALLOBJECTS>
creates them and where the Explain facility looks when the session's own schema
has none; set it when the tables were created under a schema of their own (the
F<EXPLAIN.DDL> route).

The name is an identifier (ADR 0077): it reaches the SQL through the
driver's identifier quoting, written exactly as the catalog stores it, so
upper and lower case count (C<SYSTOOLS>, not C<systools>) and a C<"> in it is
doubled. See L</Query plans>.

=head2 _dummy_table

    my $table = $storage->_dummy_table;          # SYSIBM.SYSDUMMY1
    my $table = $storage->_dummy_table($sep);    # server's qualifier separator

The one-row catalog view this driver selects scalar expressions from, since
DB2 has no C<FROM>-less C<SELECT>. Written once and read by both
C<_dbh_last_insert_id> (ADR 0002) and C<_exists_value_sql> (ADR 0037, the
override of L<DBIO::Storage::DBI/_exists_value_sql>).

The optional argument is the qualifier separator; it defaults to C<.>.
Only a caller that already holds a C<$dbh> may pass the server-reported
L</sql_name_sep>, because resolving it probes the server.

=head2 deploy_setup

No-op stub for DB2. Present for API compatibility with other drivers
that need to allocate resources before a deploy operation.

=head2 insert

An insert of no values, C<< $rs->create({}) >>, cannot be written as core's
C<INSERT INTO t DEFAULT VALUES>: Db2 does not know it (SQL0104N). It is sent as
C<< INSERT INTO t (col) VALUES (DEFAULT) >> for one column -- the first
auto-increment column, else the first column of the source -- which leaves every
column at its default, the named one too (an identity gets its value). That
column is not a value of the row: it is not in what the insert hands back,
unless the server returned it (the identity, read as for any insert).

=head2 bind_attribute_by_data_type

    my $attr = $storage->bind_attribute_by_data_type('text');   # { TYPE => -99 }

A column of a character LOB type (C<clob>, C<dbclob>, C<text>, C<mediumtext>,
C<longtext>, C<tinytext>) is bound with the type C<SQL_CLOB> of L<DBD::DB2>
(C<-99> in its CLI), so its value is a LOB parameter and not a C<VARCHAR> one.
Every other type is bound as core does.

=head2 select_single

L<DBIO::Storage::DBI/select_single> (what C<find> and C<single> read through),
with the character columns of the row decoded as the cursor does
(L<DBIO::DB2::Storage::Cursor/decode_rows>).

=head2 _utf8_database

True when the code set of the database is UTF-8 (C<SYSIBMADM.DBCFG>, name
C<codeset>); asked once per storage. L<DBIO::DB2::Storage::Cursor> decodes the
text of a result only then. A server that does not answer is not taken for UTF-8.

=head2 _prep_for_execute

L<DBIO::Storage::DBI/_prep_for_execute>, with two refusals made before the
server is asked, both DBIO exceptions naming table and column:

=over 4

=item * An empty string for a C<blob> column. L<DBD::DB2> reads an empty BLOB
as C<NULL>, so the value would not come back as it went in; it is not stored
as something else. (An empty C<CLOB> is stored and read back as C<''>.)

=item * A select or delete that compares a C<clob>/C<text> column with a value
of more than 32672 bytes. Db2 compares a CLOB with a C<VARCHAR> and cannot
(SQL0433N); the statement would fail on the server.

=back

=head1 SEE ALSO

=over

=item * L<DBIO::DB2> - DB2 schema component

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
