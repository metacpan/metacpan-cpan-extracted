use strict;
use warnings;
use Test::More;

use DBIO::Optional::Dependencies ();
use DBIO::Test::Schema;
use DBIO::Storage::DBI;
use DBIO::Oracle::Storage;

# ADR 0039 -- one storage hook, _set_operation_keyword($op), spells all six of
# DBIO::ResultSet's set operations or refuses them. It replaced ADR 0037's
# single-operation _except_operator, and the replacement is why this file was
# rewritten rather than extended: core removed the old name, so the override
# that used to live here was not failing loudly, it was simply never asked
# again, and $rs->except quietly emitted the ANSI EXCEPT on an engine that
# wants MINUS.
#
# Two engine facts are pinned here, both from the SQL Language Reference
# section "The Set Operators":
#
#   * Oracle spells set difference MINUS, and has since 8i. EXCEPT was only
#     added as a synonym in 21c, so core's inherited answer is a syntax error
#     on every release before that. This is the driver the keyword hook was
#     invented for.
#   * Before 21c the engine has exactly UNION, UNION ALL, INTERSECT and MINUS.
#     21c added EXCEPT, EXCEPT ALL, INTERSECT ALL and MINUS ALL (checked
#     against the 19c and 21c references, which enumerate exactly those two
#     lists). So except_all and intersect_all have no operator at all on the
#     releases this driver mostly meets, and used to reach the server as
#     EXCEPT ALL / INTERSECT ALL and come back as a syntax error.
#
# The second fact is version-bounded and the hook may not ask which version it
# is talking to -- ResultSet::_set_operation bakes the keyword into a literal
# from clause at construction time, so a probe would open a connection during
# query build purely in order to throw (ADR 0039 section 7). The refusal is
# therefore decided by a class fact, _use_set_operator_all_family, declared 0
# here and lifted by a deployment that knows it runs 21c or newer.
#
# Everything below is offline: the schema declares this driver, and both
# the spelling and the refusal are static class facts, so nothing here opens a
# connection. That is the point of the seam, not an accident of the test.

# DBIO::Test::Schema is shared by the driver suites and declares no driver; a
# schema always has one (core ADR 0067). Each connect here declares Oracle's
# storage on a clone, so the shared class stays without one.
sub oracle_schema {
  my $schema = DBIO::Test::Schema->clone;
  $schema->storage_type('+DBIO::Oracle::Storage');
  return $schema->connect(@_);
}

my $schema  = oracle_schema('dbi:Oracle:orcl');
my $storage = $schema->storage;

# -------------------------------------------------------------------- the hook

is (
  $storage->_set_operation_keyword('except'),
  'MINUS',
  'Oracle spells set difference MINUS -- and has since 8i, which is why the '
. 'override carries no version gate: EXCEPT was only added alongside it in '
. '21c, so the inherited answer is a syntax error on every earlier release',
);

is (
  ref $storage,
  'DBIO::Oracle::Storage',
  '... answered by the storage the schema declared, still that class after '
. 'the hook ran driver determination on the dbi:Oracle: DSN: the declared '
. 'driver stands',
);

isnt (
  DBIO::Oracle::Storage->can('_set_operation_keyword'),
  DBIO::Storage::DBI->can('_set_operation_keyword'),
  '... and it is a real override rather than the inherited EXCEPT, checked by '
. 'coderef identity and not by the returned string',
);

# The three operations Oracle has had all along are ANSI-spelled here, so the
# override has to hand them on instead of answering them. next::method
# composition is the half of the contract a driver can silently get wrong: an
# override that returned undef for what it does not recognise would put a bare
# token into the SQL.
is (
  $storage->_set_operation_keyword('union'),
  'UNION',
  'union falls through to core\'s base map',
);

is (
  $storage->_set_operation_keyword('union_all'),
  'UNION ALL',
  '... as does union_all, which Oracle has had as long as UNION',
);

is (
  $storage->_set_operation_keyword('intersect'),
  'INTERSECT',
  '... and intersect, the third of the four operators every Oracle has',
);

{
  my $keyword = eval { $storage->_set_operation_keyword('exept') };
  my $err     = $@;

  is ($keyword, undef, 'a misspelled operation produces no keyword');
  like (
    $err,
    qr/Unknown set operation 'exept'/,
    '... it reaches core\'s throw through next::method: an unknown operation '
  . 'name is a core programming error, not an Oracle fact, so this driver '
  . 'does not invent an answer for it',
  );
}

# ------------------------------------------------- what ResultSet::except builds

{
  my $rs    = $schema->resultset('Artist')->search({ name => 'foo' });
  my $other = $schema->resultset('Artist')->search({ rank => 13 });

  my ($sql, @bind) = @{ ${ $rs->except($other)->as_query } };

  like (
    $sql,
    qr/WHERE \( "name" = \? \)\s+MINUS\s+SELECT\b/,
    'except joins its two operands with the keyword the storage named',
  );

  unlike (
    $sql,
    qr/\bEXCEPT\b/,
    '... and nowhere with the ANSI spelling core answers with by default',
  );

  is_deeply (
    [ map { $_->[1] } @bind ],
    [ 'foo', 13 ],
    '... with both operands\' binds in left-to-right order, so the right-hand '
  . 'query really is the subtrahend and not a dropped clause',
  );
}

# ----------------------------------------------------- the "... ALL" refusals

for my $op (qw/except_all intersect_all/) {

  my $keyword = eval { $storage->_set_operation_keyword($op) };
  my $err     = $@;

  is ($keyword, undef, "$op produces no keyword by default");

  like (
    $err,
    qr/\b21c\b/,
    "... the refusal of $op names the version boundary: Oracle grew MINUS ALL "
  . 'and INTERSECT ALL in 21c and had neither before',
  );

  like (
    $err,
    qr/_use_set_operator_all_family/,
    '... and names the class-level switch that lifts it, which is the whole '
  . 'reason the refusal is a default rather than an absolute: a 21c+ '
  . 'deployment does have the operation',
  );

  like (
    $err,
    qr/every version/,
    '... while saying plainly that it holds on 21c too until someone sets '
  . 'that switch -- the hook is resolved without a connection and cannot ask '
  . 'which server it is talking to',
  );
}

{
  my $rs    = $schema->resultset('Artist')->search({ name => 'foo' });
  my $other = $schema->resultset('Artist')->search({ rank => 13 });

  my $result = eval { $rs->except_all($other) };
  my $err    = $@;

  is ($result, undef, 'ResultSet::except_all refuses through the same hook');

  like (
    $err,
    qr/refuses \$rs->except_all/,
    '... with this driver\'s message rather than a syntax error raised by the '
  . 'server several layers below the method the caller called',
  );

  ok (
    ! $storage->connected,
    '... at query-build time and without a connection: the keyword is '
  . 'resolved before a single operand is rendered, so a refused operation '
  . 'never hands back a fragment that could end up embedded in a larger query',
  );
}

# ------------------------------------------------------------- the 21c+ opt-in

{
  # The class-level form first, because that is the one a deployment can use
  # at load time: it names the class, so it does not depend on any storage
  # having been built yet.
  my $schema21  = oracle_schema('dbi:Oracle:orcl');
  my $storage21 = $schema21->storage;

  DBIO::Oracle::Storage->_use_set_operator_all_family (1);

  is (
    $storage21->_set_operation_keyword('except_all'),
    'MINUS ALL',
    'opted in, except_all is MINUS ALL -- the same dialect as except, and '
  . 'equivalent to the EXCEPT ALL 21c also accepts',
  );

  is (
    $storage21->_set_operation_keyword('intersect_all'),
    'INTERSECT ALL',
    '... and intersect_all takes core\'s ANSI spelling, which is Oracle\'s '
  . 'own word for it too',
  );

  my $rs    = $schema21->resultset('Artist')->search({ name => 'foo' });
  my $other = $schema21->resultset('Artist')->search({ rank => 13 });

  my ($sql) = @{ ${ $rs->except_all($other)->as_query } };

  like (
    $sql,
    qr/WHERE \( "name" = \? \)\s+MINUS ALL\s+SELECT\b/,
    '... and the word reaches the SQL, so the opt-in buys the operation back '
  . 'rather than merely silencing the exception',
  );

  ok (
    ! $storage21->connected,
    '... still without opening a connection: the opt-in is a class fact, '
  . 'which is the only kind of fact this hook is allowed to read',
  );

  DBIO::Oracle::Storage->_use_set_operator_all_family (0);

  my $again = eval { $storage21->_set_operation_keyword('except_all') };
  is (
    $again,
    undef,
    '... and putting the class switch back restores the refusal, so the '
  . 'operation really is gated on it and not on something the first call '
  . 'cached',
  );
}

{
  # The per-storage form, for a deployment that mixes servers. It is set on
  # the storage the refusal came from, which is deliberate: the accessor lives
  # on this driver class, and a storage of a schema that declared this driver
  # is of that class from the start -- which is exactly the state any storage
  # that has already refused an operation is in.
  my $schema21  = oracle_schema('dbi:Oracle:orcl');
  my $storage21 = $schema21->storage;

  is (
    eval { $storage21->_set_operation_keyword('except_all') },
    undef,
    'a fresh storage of the declared driver refuses',
  );

  $storage21->_use_set_operator_all_family (1);

  is (
    $storage21->_set_operation_keyword('except_all'),
    'MINUS ALL',
    '... and the same switch set on that one storage lifts the refusal there',
  );

  is (
    DBIO::Oracle::Storage->_use_set_operator_all_family,
    0,
    '... without touching the class default, so an untouched deployment still '
  . 'gets the conservative answer',
  );

  my $still = eval { $storage->_set_operation_keyword('except_all') };
  is (
    $still,
    undef,
    '... and a second storage that never opted in still refuses',
  );

  ok (
    ! $storage21->connected && ! $storage->connected,
    '... with no connection opened anywhere in this file',
  );
}

# ------------------------------------------------------------ live round-trip

SKIP: {
  my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_ORA_${_}" } qw/DSN USER PASS/};

  skip 'Set $ENV{DBIO_TEST_ORA_DSN}, _USER and _PASS to run the live half', 2
    unless $dsn && $user && $pass;

  skip 'Test needs '
     . DBIO::Optional::Dependencies->req_missing_for('rdbms_oracle'), 2
    unless DBIO::Optional::Dependencies->req_ok_for('rdbms_oracle');

  # The pin above proves the word reaches the SQL, not that this Oracle takes
  # it. Executed with no fixture: DUAL supplies both operands.
  my $live = oracle_schema($dsn, $user, $pass);
  my $dbh  = $live->storage->dbh;
  my $op   = $storage->_set_operation_keyword('except');

  my ($kept) = $dbh->selectrow_array(
    "SELECT 1 FROM DUAL $op SELECT 2 FROM DUAL"
  );
  is ($kept, 1, "Oracle executes $op and keeps a left-hand row the right-hand "
              . 'query does not have');

  my @removed = $dbh->selectrow_array(
    "SELECT 1 FROM DUAL $op SELECT 1 FROM DUAL"
  );
  is (scalar @removed, 0, '... and removes one it does have');
}

# An undefined operation is core's programming error. The override must pass it
# down rather than compare it: `$op eq 'except'` on undef warns first.
{
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };

  my $keyword = eval { $storage->_set_operation_keyword(undef) };
  my $err     = $@;

  is ($keyword, undef, 'an undefined operation produces no keyword');
  like ($err, qr/Unknown set operation '\(undef\)'/,
    '... core throws for it, through next::method');
  is_deeply (\@warnings, [], '... and the override warns about nothing on the way');
}

done_testing;
