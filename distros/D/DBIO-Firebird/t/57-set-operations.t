use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Optional::Dependencies ();
use DBIO::Test::Schema;
use DBIO::Storage::DBI;
use DBIO::Firebird::Storage;
use DBIO::Firebird::Storage::InterBase;

# ADR 0039 -- one seam for all six set operations. _set_operation_keyword($op)
# either spells the operation for this engine or refuses it, and Firebird is
# the family's largest gap: it has UNION and UNION ALL and nothing else.
#
# Sourced, not assumed -- the question ADR 0037 section 5 left open and ADR
# 0039 deliberately asserted nothing about:
#
#   * the <query-expression> production in the Firebird 5.0 Language Reference
#     is "<query-term> | <query-expression> UNION [{ DISTINCT | ALL }]
#     <query-term>". One set operator, no alternatives.
#   * Appendix C lists every Firebird 5.0 keyword, reserved and non-reserved.
#     UNION is there; EXCEPT, INTERSECT and MINUS are not. The tokens are not
#     in the grammar at all.
#   * FirebirdSQL/firebird#1194 (tracker CORE808) has requested INTERSECT and
#     EXCEPT since 2004 and is still open, unmilestoned, with no linked PR.
#   * the InterBase 2020 Language Reference documents "[UNION [ALL]
#     select_expr]" and nothing else -- which matters because both DBDs share
#     DBIO::Firebird::Storage::Common.
#
# So four of the six operations are refused, and the refusal is unconditional
# rather than version-gated: ADR 0039 section 7 forbids probing the server (the
# keyword is baked into a literal from clause at construction time) and allows
# either an unconditional refusal or a class-level opt-in. Unconditional costs
# nothing here, unlike Oracle's version-bounded MINUS ALL gap -- no released
# Firebird or InterBase has ever had these operators, so there is no version
# being withheld from.
#
# Before this, $rs->except emitted EXCEPT here and the caller found out from a
# syntax error several layers below the method they called.
#
# Offline: the driver is declared and the keyword is a static class fact.
#
# A schema always has a driver (core ADR 0067). DBIO::Test::Schema is shared
# by the driver suites and keeps none in its class, so every connect below
# declares the storage of the DBD it names on a clone.

my $schema  = DBIO::Test::Schema->clone(storage_type => '+DBIO::Firebird::Storage')
  ->connect('dbi:Firebird:db=/nonexistent.fdb');
my $storage = $schema->storage;

my @REFUSED = qw(intersect intersect_all except except_all);

# ------------------------------------------------ what Firebird does have

is (
  $storage->_set_operation_keyword('union'),
  'UNION',
  'union falls through to core\'s base map: the driver only names the '
. 'operations it has an opinion about',
);

is (
  $storage->_set_operation_keyword('union_all'),
  'UNION ALL',
  '... and so does union_all -- the two operations Firebird actually has',
);

is (
  ref $storage,
  'DBIO::Firebird::Storage',
  '... answered by the declared storage, which stands as declared, so the '
. 'keyword is this driver\'s answer',
);

isnt (
  DBIO::Firebird::Storage->can('_set_operation_keyword'),
  DBIO::Storage::DBI->can('_set_operation_keyword'),
  '... through a real override rather than the inherited base map, checked by '
. 'coderef identity and not by the returned strings',
);

# ------------------------------------------------ what it does not have

for my $op (@REFUSED) {
  throws_ok
    { $storage->_set_operation_keyword($op) }
    qr/\QFirebird cannot express the set operation '$op'\E/,
    "$op is refused by name, with a message that names the engine";

  my $err = $@;

  isa_ok (
    $err,
    'DBIO::Exception',
    "the refusal for $op",
  );

  like (
    "$err",
    qr/unconditional/,
    "... and says it is unconditional: the refusal for $op is not a version "
  . 'gate, and a message that hid that would send the reader looking for a '
  . 'newer server',
  );
}

# ------------------------------- refusal happens before any SQL is assembled

{
  my $rs    = $schema->resultset('Artist')->search({ name => 'foo' });
  my $other = $schema->resultset('Artist')->search({ rank => 13 });

  for my $op (@REFUSED) {
    throws_ok
      { $rs->$op($other) }
      qr/\QFirebird cannot express the set operation '$op'\E/,
      "\$rs->$op throws from the method itself, not from a later as_query -- "
    . 'ADR 0039 section 4: the keyword is resolved before a single operand is '
    . 'rendered, so a refusing engine never hands back a fragment that could '
    . 'be embedded in a larger query';
  }
}

# --------------------------------- and the two it has still build normally

{
  my $rs    = $schema->resultset('Artist')->search({ name => 'foo' });
  my $other = $schema->resultset('Artist')->search({ rank => 13 });

  for my $pair (['union', 'UNION'], ['union_all', 'UNION ALL']) {
    my ($method, $keyword) = @$pair;

    my ($sql, @bind) = @{ ${ $rs->$method($other)->as_query } };

    like (
      $sql,
      qr/WHERE \( "name" = \? \)\s+\Q$keyword\E\s+SELECT\b/,
      "$method still joins its two operands with $keyword: the refusal is "
    . 'per-operation and does not cost this engine what it does have',
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
  'none of it opened a connection: the keyword -- and the refusal with it -- '
. 'is a static class fact, which it has to be, since _set_operation bakes it '
. 'into a literal from clause at construction time',
);

# ------------------------------------------- the same answer via DBD::InterBase

{
  my $ib = DBIO::Test::Schema
    ->clone(storage_type => '+DBIO::Firebird::Storage::InterBase')
    ->connect('dbi:InterBase:db=/nonexistent.fdb')
    ->storage;

  is ($ib->_set_operation_keyword('union_all'), 'UNION ALL',
    'the InterBase driver inherits the same map -- hook on the shared '
  . 'Storage::Common, and InterBase 2020 documents UNION [ALL] and nothing '
  . 'else either');

  throws_ok
    { $ib->_set_operation_keyword('except') }
    qr/\QFirebird cannot express the set operation 'except'\E/,
    '... and the same refusal, so neither DBD can be left behind by an edit '
  . 'to the other';

  ok (! $ib->connected, '... without connecting either');
}

# ------------------------------------------------------------ live round-trip

SKIP: {
  my ($dsn, $user, $pass)
    = @ENV{map { "DBIO_TEST_FIREBIRD_${_}" } qw/DSN USER PASS/};

  skip 'Set $ENV{DBIO_TEST_FIREBIRD_DSN}, _USER and _PASS to run the live half', 2
    unless $dsn && $user && $pass;

  skip 'Test needs '
     . DBIO::Optional::Dependencies->req_missing_for('rdbms_firebird'), 2
    unless DBIO::Optional::Dependencies->req_ok_for('rdbms_firebird');

  # The pins above are documentation turned into code. This is the engine
  # itself answering, and it is the only assertion here that could falsify the
  # refusal: if a future Firebird ever executes EXCEPT, this goes red and the
  # gap has become version-bounded -- at which point ADR 0039 section 7's
  # class-level opt-in becomes the right shape instead.
  my $live = DBIO::Test::Schema->clone(storage_type => '+DBIO::Firebird::Storage')
    ->connect($dsn, $user, $pass);
  my $dbh  = $live->storage->dbh;

  my ($union) = $dbh->selectrow_array(
    'SELECT 1 FROM RDB$DATABASE UNION SELECT 1 FROM RDB$DATABASE'
  );
  is ($union, 1, 'Firebird executes UNION, so the two operations this driver '
                . 'does hand through really are there');

  ok (
    ! eval {
      $dbh->do('SELECT 1 FROM RDB$DATABASE EXCEPT SELECT 1 FROM RDB$DATABASE');
      1;
    },
    '... and rejects EXCEPT, which is what the refusal above spares the '
  . 'caller from discovering this way',
  );
}

done_testing;
