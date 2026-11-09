use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Optional::Dependencies ();
use DBIO::Test::Schema;
use DBIO::Storage::DBI;
use DBIO::DB2::Storage;

# ADR 0039 -- one seam for all six set operations. _set_operation_keyword($op)
# either spells the operation for this engine or refuses it, and DB2 is the
# case where it does neither: the engine has all six and spells every one of
# them the ANSI way core's base map already answers with, so this driver
# overrides nothing and inherits the lot.
#
# "Nothing to declare" is exactly the claim that rots silently, which is why
# this file exists. It is also the counter-check core asked for on the other
# side of core k135: if the routing of all six through one hook changed a
# single byte for a complete engine, it changes it here.
#
# Sourced, not assumed:
#
#   * the <fullselect> production in the Db2 for Linux, UNIX and Windows SQL
#     Reference offers UNION | UNION ALL | EXCEPT | EXCEPT ALL | INTERSECT |
#     INTERSECT ALL, unchanged from 9.7 (2009) through 12.1 (topic
#     "fullselect", last updated 2026-04-01). Db2 for z/OS 12 documents the
#     same six.
#   * the same section, both platforms: "For compatibility with other SQL
#     implementations, MINUS can be specified as a synonym for EXCEPT." That
#     widens what the parser accepts; it does not change what the engine is
#     spelled. EXCEPT is the primary spelling of the syntax diagram in every
#     documented version and there is no mode in which it stops being one, so
#     ADR 0037 section 3's predicted "second spelling" still has not appeared.
#   * Db2 for i is the one Db2 that does NOT have all six -- IBM i 7.5 SQL
#     Reference, "fullselect": UNION [DISTINCT|ALL], EXCEPT [DISTINCT],
#     INTERSECT [DISTINCT], with no ALL form of the latter two and no MINUS.
#     It is not refused here because this distribution cannot be used against
#     it at all: every introspect and deploy query reads the SYSCAT catalog
#     views, which are Db2 LUW's. Refusing except_all and intersect_all -- the
#     only shape ADR 0039 section 7 allows, the platform being no more
#     askable without a connection than a version is -- would withdraw two
#     working operations from every server this driver does support.
#
# Offline: the schema declares the driver and the keyword is a static class
# fact. DBIO::Test::Schema is shared by every driver's suite and keeps no
# driver in its class (core ADR 0067), so this file declares DB2 on a clone.

sub db2_schema {
  my $schema = DBIO::Test::Schema->clone;
  $schema->storage_type('+DBIO::DB2::Storage');
  return $schema->connection(@_);
}

my $schema  = db2_schema('dbi:DB2:DATABASE=nonexistent');
my $storage = $schema->storage;

# ------------------------------------------------- nothing to declare

is (
  DBIO::DB2::Storage->can('_set_operation_keyword'),
  DBIO::Storage::DBI->can('_set_operation_keyword'),
  'this driver does not override the hook at all -- by coderef identity, so '
. 'a future override that merely reproduced the base answers would still be '
. 'caught here and have to justify itself',
);

# ------------------------------------------------- all six, spelled out

my %KEYWORD = (
  union         => 'UNION',
  union_all     => 'UNION ALL',
  intersect     => 'INTERSECT',
  intersect_all => 'INTERSECT ALL',
  except        => 'EXCEPT',
  except_all    => 'EXCEPT ALL',
);

for my $op (sort keys %KEYWORD) {
  is (
    $storage->_set_operation_keyword($op),
    $KEYWORD{$op},
    "$op resolves to $KEYWORD{$op} on DB2",
  );
}

is (
  ref $storage,
  'DBIO::DB2::Storage',
  '... and the storage that answered is this driver, not the generic base: '
. 'the DB2 storage the schema declared (core ADR 0067). Inheriting is what '
. 'makes the answers right, but they are still DB2\'s answers and not the '
. 'base map reached without a driver',
);

is (
  $storage->_set_operation_keyword('except'),
  'EXCEPT',
  'set difference is EXCEPT, not MINUS: DB2 accepts MINUS as a documented '
. 'synonym but has never spelled the operation that way by default, so there '
. 'is no per-engine spelling for the hook to carry (contrast Oracle, where '
. 'MINUS is the only spelling before 21c)',
);

# ----------------------------------- an unknown op is still core's error

throws_ok
  { $storage->_set_operation_keyword('symmetric_difference') }
  qr/\QUnknown set operation 'symmetric_difference'\E/,
  'an operation name core does not know still lands on core\'s throw: '
. 'inheriting the map means inheriting the guard, so a bare token cannot '
. 'reach the SQL through this driver either';

# --------------------------------- and what DBIO::ResultSet actually builds

{
  my $rs    = $schema->resultset('Artist')->search({ name => 'foo' });
  my $other = $schema->resultset('Artist')->search({ rank => 13 });

  for my $op (sort keys %KEYWORD) {
    my ($sql, @bind) = @{ ${ $rs->$op($other)->as_query } };

    like (
      $sql,
      qr/WHERE \( "name" = \? \)\s+\Q$KEYWORD{$op}\E\s+SELECT\b/,
      "\$rs->$op joins its two operands with $KEYWORD{$op} -- the keyword "
    . 'reaches the SQL, not just the hook',
    );

    is_deeply (
      [ map { $_->[1] } @bind ],
      [ 'foo', 13 ],
      '... with both operands\' binds in left-to-right order',
    );
  }
}

ok (
  ! $storage->connected,
  'none of it opened a connection: the keyword is a static class fact, which '
. 'it has to be, since _set_operation bakes it into a literal from clause at '
. 'construction time -- the connection-at-query-build-time ADR 0037 removed',
);

# ------------------------------------------------------------ live round-trip

SKIP: {
  my ($dsn, $user, $pass)
    = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

  skip 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run the live half',
    scalar keys %KEYWORD
    unless $dsn && $user;

  skip 'Test needs '
     . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_db2'),
    scalar keys %KEYWORD
    unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_db2');

  # The pins above are IBM's documentation turned into code. This is the
  # engine itself answering, and it is the only assertion here that could
  # falsify "all six": run with no fixture at all, each operation against the
  # one-row catalog view, so a missing operator surfaces as a parse error and
  # nothing else can.
  my $live = db2_schema($dsn, $user, $pass);
  my $dbh  = $live->storage->dbh;

  for my $op (sort keys %KEYWORD) {
    my $keyword = $KEYWORD{$op};

    lives_ok {
      $dbh->selectrow_array(
        "SELECT 1 FROM SYSIBM.SYSDUMMY1 $keyword SELECT 1 FROM SYSIBM.SYSDUMMY1"
      );
    } "DB2 parses $keyword, so inheriting core's base map for $op is right";
  }
}

done_testing;
