use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Test::Schema;
use DBIO::Storage::DBI;
use DBIO::Storage::DBI::ODBC;
use DBIO::Firebird::Storage;
use DBIO::Firebird::Storage::InterBase;
use DBIO::Firebird::Storage::ODBC;

# karr #20 -- the third transport. Firebird speaks to three DBDs, and until now
# this distribution had a storage class for two of them: DBD::Firebird and
# DBD::InterBase. A dbi:ODBC:Driver=Firebird DSN -- the one the ODBC leg of
# t/10-firebird.t, t/20-firebird-core.t and t/30-datetime-firebird.t connects
# with, through DBIO_TEST_FIREBIRD_ODBC_DSN -- had nowhere to land: core
# determined it to the generic DBIO::Storage::DBI::ODBC, which knows nothing
# about this engine. What that costs is not subtle:
#
#   * sql_maker_class stays core's, so ->rows / ->page render LIMIT/OFFSET.
#     Firebird has neither; the dialect is FIRST/SKIP. Every paged query over
#     ODBC was a syntax error.
#   * _exists_value_sql renders a FROM-less SELECT (karr #16) and
#     supports_exists_query is not declared, so results_exist* throws pointing
#     at a capability that is in fact correct for this engine.
#   * _set_operation_keyword still spells EXCEPT and INTERSECT (karr #19),
#     which are not tokens of this engine at all.
#   * quoting, sqlt_type, GEN_ID sequences, savepoints, the server-version
#     query: all core defaults.
#
# The fix is the shape ADR 0035 / dbio-mssql ADR 0007 settled on for the same
# question there: a thin transport class over the engine-neutral base, here
# DBIO::Storage::DBI::ODBC + DBIO::Firebird::Storage::Common. This file is what
# holds the two halves of that to account -- that a schema declaring the class
# gets it over an ODBC DSN, and that the class actually inherits the engine
# seams rather than merely being named after them.
#
# All of it is offline; nothing here opens a connection.

# ---------------------------------------------------------------------------
# 1. a schema declaring this transport, over dbi:ODBC:Driver=Firebird
# ---------------------------------------------------------------------------
#
# A schema always has a driver (core ADR 0067), and the declared storage class
# stands (ADR 0059). An ODBC DSN says nothing about the engine behind it --
# every ODBC engine shares the DBD name ODBC -- so this transport is reached by
# declaring it: storage_type '+DBIO::Firebird::Storage::ODBC', here on a clone
# of the shared test schema, which keeps no driver in its class.
#
# Cores before ADR 0067 also routed a schema that declared nothing here, by
# asking the handle for SQL_DBMS_NAME and looking the answer up in a connector
# registry. That detection is retired, and this file no longer drives it. The
# declaring schema of the Firebird component (-fb) gets DBIO::Firebird::Storage
# over an ODBC DSN, not this class; that is open on karr k40.

our @INFO_ASKED;

my $ODBC_DSN = 'dbi:ODBC:Driver=Firebird;Dbname=/nonexistent.fdb';

{
  no warnings 'redefine';
  local *DBIO::Storage::DBI::_dbh_get_info = sub {
    my ($self, $info) = @_;
    push @INFO_ASKED, $info;
    return $info eq 'SQL_DBMS_NAME' ? 'Firebird' : undef;
  };

  @INFO_ASKED = ();
  my $storage = DBIO::Test::Schema
    ->clone(storage_type => '+DBIO::Firebird::Storage::ODBC')
    ->connect($ODBC_DSN)
    ->storage;

  # Resolution is lazy: it runs on the first dbh access, not on connect. Run it
  # here, so what is asserted below is the storage after it.
  $storage->_determine_driver;

  is (
    ref $storage,
    'DBIO::Firebird::Storage::ODBC',
    'a schema declaring the Firebird ODBC storage gets exactly that class over '
  . 'dbi:ODBC:Driver=Firebird, after driver resolution. Before this class '
  . 'existed there was no Firebird storage for this DBD at all',
  );

  is_deeply (
    \@INFO_ASKED,
    [],
    '... and resolution asked the connector nothing: the class is declared, '
  . 'not found from the engine name the ODBC driver reports',
  );

  ok (
    ! $storage->connected,
    '... nor opened a connection: the declaration and the DSN are all it reads',
  );

  is (
    DBIO::Test::Schema->storage_type,
    '::DBI',
    '... and the declaration stayed on the clone: the shared test schema '
  . 'still keeps no driver in its class, so no other test inherits this one',
  );

  ok (
    $storage->isa('DBIO::Storage::DBI::ODBC'),
    'the storage is an ODBC storage -- the transport helpers are inherited, '
  . 'not reimplemented',
  );

  ok (
    $storage->isa('DBIO::Firebird::Storage::Common'),
    '... and a Firebird storage, which is the whole point: everything karr '
  . '#16, #17 and #19 put on Storage::Common reaches this transport by '
  . 'inheritance',
  );

  ok (
    ! $storage->isa('DBIO::Firebird::Storage::InterBase'),
    '... but NOT an InterBase storage. That class speaks the ib_* API of '
  . 'DBD::InterBase -- ib_dialect, ib_softcommit, ib_time_all, '
  . 'func(ib_plan) -- and a DBD::ODBC handle has none of it',
  );

  unlike (
    $storage->_dbi_connect_info->[0],
    qr/ib_dialect/,
    '... so the connect string came through resolution untouched: '
  . 'ib_dialect is a DBD::InterBase DSN parameter, and _init on the native '
  . 'storages appends it to the connect string before anything connects',
  );
}

SKIP: {
  skip 'core before ADR 0067 still detects a driver from the DSN for a schema '
     . 'that declares none (DBIO->driver_for is the marker of the new rule)', 3
    unless DBIO->can('driver_for');

  @INFO_ASKED = ();
  no warnings 'redefine';
  local *DBIO::Storage::DBI::_dbh_get_info = sub {
    push @INFO_ASKED, $_[1];
    return;
  };

  throws_ok {
    DBIO::Test::Schema->connect($ODBC_DSN)
  } qr/declares no driver/,
    'a schema declaring nothing is refused over the same DSN: there is no '
  . 'route from an ODBC DSN to this class other than declaring it';

  is_deeply (
    \@INFO_ASKED,
    [],
    '... before anything was asked of a connector',
  );

  throws_ok {
    DBIO->driver_for($ODBC_DSN)
  } qr/ODBC/,
    '... and the function that names the driver of a DSN refuses it as well: '
  . 'DBD::ODBC names no driver';
}

# ---------------------------------------------------------------------------
# 2. the class tree, by identity rather than by name
# ---------------------------------------------------------------------------
#
# The ISA order is ADR 0010's: the transport base first, the engine-neutral
# Storage::Common after it. The order is the ADR 0010 cut: where the
# transport and the engine both answer a question, the transport's answer
# wins. Changing it is an architecture change (an ADR, not a fix), which is
# what this pin makes visible.

is_deeply (
  [ @DBIO::Firebird::Storage::ODBC::ISA ],
  [ 'DBIO::Storage::DBI::ODBC', 'DBIO::Firebird::Storage::Common' ],
  'the transport base comes first in the ISA, Storage::Common after it: '
. 'a slot both define answers with the transport\'s value (ADR 0010)',
);

ok (
  ! DBIO::Firebird::Storage::ODBC->can('connect_call_use_softcommit'),
  'connect_call_use_softcommit is not reachable here. It sets '
. '$dbh->{ib_softcommit}, and offering it on a DBD::ODBC handle would be a '
. 'connect-call that writes an attribute the driver has never heard of',
);

ok (
  ! DBIO::Firebird::Storage::ODBC->can('_set_sql_dialect'),
  '... and neither is the ib_dialect DSN rewrite',
);

isnt (
  DBIO::Firebird::Storage::ODBC->can('_ping'),
  DBIO::Firebird::Storage::InterBase->can('_ping'),
  '... nor the InterBase _ping, which issues a select against RDB$DATABASE '
. 'where DBD::ODBC has a real ping of its own',
);

is (
  DBIO::Firebird::Storage::ODBC->datetime_parser_type,
  'DBIO::Firebird::DateTime::Format',
  'the datetime parser is declared on this class. Storage::Common does not '
. 'carry one -- the two native drivers each declare it -- and core\'s default '
. 'is the historic DateTime::Format::MySQL, which parses no fractional '
. 'seconds and would have silently mangled every TIMESTAMP over ODBC',
);

ok (
  DBIO::Firebird::Storage::ODBC->can('connect_call_datetime_setup'),
  'connect_call_datetime_setup exists here as a noop. Connect-calls are '
. 'resolved by name against the storage class, so on_connect_call => '
. '\'datetime_setup\' -- which t/30-datetime-firebird.t passes for all three '
. 'transports alike -- would otherwise die looking for the method',
);

isnt (
  DBIO::Firebird::Storage::ODBC->can('connect_call_datetime_setup'),
  DBIO::Firebird::Storage::InterBase->can('connect_call_datetime_setup'),
  '... its own, not the InterBase one: that sets $dbh->{ib_time_all}, and the '
. 'ODBC driver already answers in the canonical form',
);

# ---------------------------------------------------------------------------
# 3. the engine seams, through the storage rather than through isa
# ---------------------------------------------------------------------------
#
# Section 2 says the classes are in the ISA. This section asks the storage the
# questions the ORM asks it, because inheritance across TWO parents is exactly
# where an answer can come from the wrong one: DBIO::Storage::DBI::ODBC sits
# BEFORE Storage::Common in the C3 linearisation, and everything below is a
# slot core's base class also has a value for.

{
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::Firebird::Storage::ODBC',
  );
  my $storage = $schema->storage;

  # Asked of the class, not of the storage: DBIO::Test::Storage sits first in
  # the hybrid mock's linearisation and answers NULL for sqlt_type, which is
  # the mock's business rather than this transport's.
  is (
    DBIO::Firebird::Storage::ODBC->sqlt_type,
    'Firebird',
    'sqlt_type is Firebird',
  );

  is (
    $storage->sql_quote_char,
    '"',
    '... the quote char is the double quote',
  );

  # karr #16 / ADR 0037 -- both halves, and the capability is the half that
  # could plausibly have gone missing here: it is stored in an inherited slot
  # and core's base class holds a 0 in the same slot, one step further down
  # the same linearisation.
  ok (
    $storage->_use_supports_exists_query,
    'supports_exists_query is declared -- the capability travels across the '
  . 'two-parent inheritance, and core\'s default 0 does not shadow it',
  );

  is (
    $storage->_exists_value_sql('(SELECT 42 FROM "artist" "me")'),
    'SELECT CASE WHEN EXISTS (SELECT 42 FROM "artist" "me") THEN 1 ELSE 0 END'
  . ' FROM RDB$DATABASE',
    '... and the rendering carries Firebird\'s one-row system table. Core\'s '
  . 'base rendering is a FROM-less SELECT, which this engine cannot parse at '
  . 'all',
  );

  my ($exists_sql) = @{ ${
    $schema->resultset('Artist')->search({ name => 'foo' })->results_exist_as_query
  } };

  like (
    $exists_sql,
    qr/FROM RDB\$DATABASE \)$/,
    '... all the way out through results_exist_as_query, so the caller-facing '
  . 'method is the one inheriting it',
  );

  # karr #19 / ADR 0039
  throws_ok {
    $storage->_set_operation_keyword('except')
  } qr/\QFirebird cannot express the set operation 'except'\E/,
    'the four set operations Firebird has no operator for are refused here '
  . 'too. Over ODBC they used to render EXCEPT and INTERSECT, which are not '
  . 'tokens of this engine, and the caller found out from a syntax error '
  . 'several layers below the method they called';

  is (
    $storage->_set_operation_keyword('union_all'),
    'UNION ALL',
    '... while the two it does have still fall through to core\'s map',
  );

  # karr #17 / ADR 0011 -- the hook the previous ticket deliberately put on
  # Storage::Common so that a future ODBC transport would inherit it. This is
  # that future.
  is (
    $storage->_random_function,
    'RAND()',
    '$rs->rand orders by RAND(). Core answers RANDOM(), which Firebird cannot '
  . 'resolve at all',
  );

  # The worst of the inherited-from-nothing defaults, and the only one that is
  # a whole dialect rather than a single string: Firebird has no LIMIT/OFFSET.
  my ($paged_sql, @paged_bind) = @{ ${
    $schema->resultset('Artist')->search({}, {
      rows => 3, offset => 4, order_by => 'artistid',
    })->as_query
  } };

  like (
    $paged_sql,
    qr/SELECT FIRST \? SKIP \?/,
    'a paged query renders FIRST/SKIP -- DBIO::Firebird::SQLMaker is inherited '
  . 'through Storage::Common. Without it every ->rows and ->page over ODBC was '
  . 'core\'s LIMIT/OFFSET, which this engine has no keyword for',
  );

  unlike (
    $paged_sql,
    qr/\bLIMIT\b/i,
    '... and no LIMIT anywhere in it',
  );

  is_deeply (
    [ map { ref $_ eq 'ARRAY' ? $_->[1] : $_ } @paged_bind ],
    [ 3, 4 ],
    '... with the row count and offset bound in the order the clause names '
  . 'them, ahead of the rest of the statement',
  );
}

# ---------------------------------------------------------------------------
# 4. the one seam this transport must NOT inherit from the InterBase driver
# ---------------------------------------------------------------------------
#
# karr #17 put _explain_query on Storage::InterBase rather than on
# Storage::Common on the grounds that it reads the plan with
# $sth->func('ib_plan') -- a private XSUB of DBD::Firebird and DBD::InterBase.
# DBD::ODBC has no such function, and the ODBC API has no vendor-neutral
# spelling for isc_info_sql_get_plan either, so this transport can obtain no
# plan at all. Both ways of being quiet about that are wrong: inheriting the
# InterBase override calls a function that is not there, and inheriting core's
# EXPLAIN <query> is a Token unknown parse error from the server.

isnt (
  DBIO::Firebird::Storage::ODBC->can('_explain_query'),
  DBIO::Firebird::Storage::InterBase->can('_explain_query'),
  'the ib_plan override is not inherited here -- it is the InterBase class\'s, '
. 'and it reaches for a DBD function this handle does not have',
);

isnt (
  DBIO::Firebird::Storage::ODBC->can('_explain_query'),
  DBIO::Storage::DBI->can('_explain_query'),
  '... and core\'s EXPLAIN prefix is not inherited either, which is the '
. 'failure that would have looked like the engine\'s fault',
);

{
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::Firebird::Storage::ODBC',
  );
  my $storage = $schema->storage;
  $storage->reset_captured;

  throws_ok {
    $schema->resultset('Artist')->search({ name => 'foo' })->explain
  } qr/query plan over ODBC/,
    '$rs->explain refuses, naming the transport. The caller learns it from '
  . 'the method they called instead of from a parse error, and the message '
  . 'names the two DBDs that can answer';

  is (
    scalar( $storage->captured_queries ),
    0,
    '... having issued no statement at all: there is nothing to issue, which '
  . 'is the reason for the refusal rather than an implementation detail of it',
  );
}

done_testing;
