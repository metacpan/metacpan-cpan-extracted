use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Warn;

use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::MySQL::SQLMaker;

# ADR 0036, atomic upsert -- the MySQL half.
#
# Everything asserted here is decidable without a server: the SQL shapes are
# pure rendering, and both the conflict-target rule (section 1) and the
# row-identity rule (section 4) are driven by static schema metadata
# (unique_constraints + is_auto_increment), which is precisely why the ADR
# insists they surface on the first call in development rather than
# data-dependently in production. Live round-trips live in t/25-upsert-live.t.

# --- the server the fake storage pretends to be --------------------------

my %server = ( dbms_version => '8.0.19', normalized_dbms_version => '8.000019' );
{
  no warnings 'redefine';
  # DBIO::Test::Storage overrides _server_info, so that is what has to be
  # mocked -- the hybrid puts it ahead of the driver in the MRO.
  *DBIO::Test::Storage::_server_info = sub { \%server };
}

sub set_server {
  my ($raw, $normalized) = @_;
  %server = ( dbms_version => $raw, normalized_dbms_version => $normalized );
}

sub mysql_schema {
  my $storage_type = shift || 'DBIO::MySQL::Storage';
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => $storage_type,
  );
  $schema->storage->reset_captured;
  return $schema;
}

sub captured_sql {
  my $schema = shift;
  my @q = $schema->storage->captured_queries;
  return map { $_->{sql} } @q;
}

sub upsert_sql {
  my ($schema, $source, @args) = @_;
  $schema->storage->reset_captured;
  $schema->resultset($source)->upsert(@args);
  my @sql = captured_sql($schema);
  return $sql[0];
}

# =========================================================================
# 1. The renderer on its own -- DBIO::MySQL::SQLMaker::_insert_on_conflict
# =========================================================================

sub maker {
  my $alias = shift;
  my $sm = DBIO::MySQL::SQLMaker->new(
    bindtype   => 'columns',
    quote_char => '`',
    name_sep   => '.',
  );
  $sm->{_upsert_row_alias} = $alias;
  return $sm;
}

# The contract with core: a driver override consumes $options->{on_conflict}.
# Leaving it in place makes the generic DBIO::SQLMaker::ClassicExtensions
# insert throw, on purpose -- a clause that cannot be placed must never be
# dropped silently.
{
  my $options = {
    on_conflict => {
      target => 'any',
      action => 'update',
      set    => { name => { -attempted => 'name' } }
    }
  };

  my ($sql) = maker()->insert('artist', { name => 'x' }, $options);

  ok ! exists $options->{on_conflict},
    'the SQLMaker consumes on_conflict before delegating upwards';
  like $sql, qr/ON DUPLICATE KEY UPDATE/, 'and renders the clause itself';
}

# <= 8.0.19: the attempted values are read back with VALUES(col)
{
  my ($sql, @bind) = maker()->insert(
    'artist',
    { name => 'x', rank => 3 },
    { on_conflict => {
        target => 'any',
        action => 'update',
        set    => { name => { -attempted => 'name' }, rank => { -attempted => 'rank' } }
    } }
  );

  is $sql,
    'INSERT INTO `artist` (`name`, `rank`) VALUES (?, ?) '
  . 'ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `rank` = VALUES(`rank`)',
    'VALUES(col) form';
  is scalar @bind, 2, 'the conflict set adds no binds of its own';
}

# >= 8.0.20: VALUES() is deprecated in favour of a row alias, which has to be
# introduced in the statement itself
{
  my ($sql) = maker('new')->insert(
    'artist',
    { name => 'x', rank => 3 },
    { on_conflict => {
        target => 'any',
        action => 'update',
        set    => { name => { -attempted => 'name' }, rank => { -attempted => 'rank' } }
    } }
  );

  is $sql,
    'INSERT INTO `artist` (`name`, `rank`) VALUES (?, ?) AS `new` '
  . 'ON DUPLICATE KEY UPDATE `name` = `new`.`name`, `rank` = `new`.`rank`',
    'row-alias form';
}

# The alias is only introduced when something actually references it
{
  my ($sql) = maker('new')->insert(
    'artist',
    { name => 'x' },
    { on_conflict => {
        target => 'any',
        action => 'update',
        set    => { rank => \'rank + 1' }
    } }
  );

  unlike $sql, qr/ AS /, 'no row alias when no attempted value is referenced';
  like $sql, qr/ON DUPLICATE KEY UPDATE `rank` = rank \+ 1$/,
    'a caller-supplied literal passes through verbatim';
}

# literal with bind, and a plain scalar -- both keep their bind order after
# the values of the INSERT itself
{
  my ($sql, @bind) = maker()->insert(
    'artist',
    { name => 'x' },
    { on_conflict => {
        target => 'any',
        action => 'update',
        set    => { rank => \[ 'rank + ?', 7 ], charfield => 'zz' }
    } }
  );

  is $sql,
    'INSERT INTO `artist` (`name`) VALUES (?) '
  . 'ON DUPLICATE KEY UPDATE `charfield` = ?, `rank` = rank + ?',
    'literal-with-bind and plain scalar render as expected';
  is_deeply \@bind, [ [ name => 'x' ], [ charfield => 'zz' ], 7 ],
    'binds come out in statement order';
}

# MySQL has no DO NOTHING; the documented emulation is a no-op assignment
{
  my ($sql) = maker()->insert(
    'twokeys',
    { artist => 1, cd => 2 },
    { on_conflict => { target => [qw/artist cd/], action => 'nothing', noop_column => 'artist' } }
  );

  is $sql,
    'INSERT INTO `twokeys` (`artist`, `cd`) VALUES (?, ?) '
  . 'ON DUPLICATE KEY UPDATE `artist` = `artist`',
    'DO NOTHING is emulated with a no-op set';
}

# ... and the renderer can still find a column when nobody named one
{
  my ($sql) = maker()->insert(
    'twokeys',
    { artist => 1, cd => 2 },
    { on_conflict => { target => [qw/cd artist/], action => 'nothing' } }
  );

  like $sql, qr/ON DUPLICATE KEY UPDATE `cd` = `cd`$/,
    'the no-op column falls back to the first target column';
}

# the identity idiom is a rendering job here, a decision one layer up
{
  my ($sql) = maker()->insert(
    'artist',
    { name => 'x' },
    { on_conflict => {
        target          => 'any',
        action          => 'update',
        set             => { name => { -attempted => 'name' } },
        identity_column => 'artistid'
    } }
  );

  is $sql,
    'INSERT INTO `artist` (`name`) VALUES (?) ON DUPLICATE KEY UPDATE '
  . '`name` = VALUES(`name`), `artistid` = LAST_INSERT_ID(`artistid`)',
    'LAST_INSERT_ID(pk) is appended to the conflict set';
}

# ON DUPLICATE KEY UPDATE has no empty form
{
  throws_ok {
    maker()->insert('artist', { name => 'x' },
      { on_conflict => { target => 'any', action => 'update', set => {} } });
  } qr/requires at least one assignment/,
    'an empty conflict set is refused rather than emitted';
}

# =========================================================================
# 2. Picking the form by server version, never by driver name (this dist's ADR 0001)
# =========================================================================

{
  set_server('5.7.44', '5.007044');
  my $schema = mysql_schema();
  like upsert_sql($schema, 'Artist', { name => 'a' }, { conflict_target => 'any', result => 'void' }),
    qr/`name` = VALUES\(`name`\)/, 'MySQL 5.7: VALUES(col)';
}

{
  set_server('8.0.19', '8.000019');
  my $schema = mysql_schema();
  like upsert_sql($schema, 'Artist', { name => 'a' }, { conflict_target => 'any', result => 'void' }),
    qr/`name` = VALUES\(`name`\)/, 'MySQL 8.0.19: still VALUES(col)';
}

{
  set_server('8.0.20', '8.000020');
  my $schema = mysql_schema();
  my $sql = upsert_sql($schema, 'Artist', { name => 'a' }, { conflict_target => 'any', result => 'void' });
  like $sql, qr/ AS `new` /, 'MySQL 8.0.20: the row alias is introduced';
  like $sql, qr/`name` = `new`\.`name`/, 'MySQL 8.0.20: and referenced';
}

# MariaDB's version numbers sail straight past a numeric >= 8.0.20 gate, and
# MariaDB never grew the row alias. The discriminator is the server product,
# not the DBD driver name -- DBD::mysql talks to MariaDB servers too, which
# is exactly the case below.
{
  set_server('10.11.2-MariaDB-1:10.11.2+maria~ubu2204', '10.011002');
  my $schema = mysql_schema();
  like upsert_sql($schema, 'Artist', { name => 'a' }, { conflict_target => 'any', result => 'void' }),
    qr/`name` = VALUES\(`name`\)/,
    'a MariaDB server reached through the MySQL storage keeps VALUES(col)';
}

{
  set_server('11.4.2-MariaDB', '11.004002');
  my $schema = mysql_schema('DBIO::MySQL::Storage::MariaDB');
  like upsert_sql($schema, 'Artist', { name => 'a' }, { conflict_target => 'any', result => 'void' }),
    qr/`name` = VALUES\(`name`\)/,
    'and so does a MariaDB server under the MariaDB storage';
}

# ... but the storage class is the DBD binding, not the engine: DBD::MariaDB
# talks to MySQL servers too, and that server does have the row alias. Deciding
# it at class level got this one wrong (karr #28); the product check in the
# parent gets all four DBD/engine combinations right. See t/26-server-version.t.
{
  set_server('8.0.46', '8.000046');
  my $schema = mysql_schema('DBIO::MySQL::Storage::MariaDB');
  like upsert_sql($schema, 'Artist', { name => 'a' }, { conflict_target => 'any', result => 'void' }),
    qr/ AS `new` /,
    'a MySQL server reached through DBD::MariaDB still gets the row alias';
}

# back to a plain, recent MySQL for everything below
set_server('8.0.19', '8.000019');

# =========================================================================
# 3. Conflict target -- ADR 0036 section 1, three cases
# =========================================================================

is DBIO::MySQL::Storage->_use_supports_upsert, 1,
  'the MySQL storage declares supports_upsert';
is DBIO::MySQL::Storage::MariaDB->_use_supports_upsert, 1,
  'and MariaDB inherits the declaration';

# Case 1: a real target on a table with further unique keys. Artist has three
# distinct unique indexes (artistid, name, (charfield, rank)), so a statement
# aimed at the primary key can collide on either of the others and rewrite a
# row the caller never named. PostgreSQL raises a unique violation for the
# same call; silently doing something else here is not an option.
{
  my $schema = mysql_schema();

  throws_ok {
    $schema->resultset('Artist')->upsert({ artistid => 5, name => 'a' }, { result => 'void' });
  } qr/MySQL cannot honour the requested conflict target/,
    'the PK default counts as a demanded target and is refused on a multi-unique table';

  my $err = $@;
  like $err, qr/conflict_target => 'any'/,
    "and the message names conflict_target => 'any' as the deliberate way out";
  like $err, qr/artist_name \(name\)/,
    'and names the unique key that makes the target undeliverable';
  like $err, qr/PostgreSQL/,
    'and says what the same call does on an engine that has a conflict target';

  is scalar(captured_sql($schema)), 0, 'nothing was sent to the server';
}

{
  my $schema = mysql_schema();
  throws_ok {
    $schema->resultset('Artist')->upsert(
      { artistid => 5, name => 'a' }, { conflict_target => ['artistid'], result => 'void' });
  } qr/MySQL cannot honour the requested conflict target/,
    'an explicit column target is refused the same way';

  throws_ok {
    $schema->resultset('Artist')->upsert(
      { name => 'a', rank => 1 }, { key => 'artist_name', result => 'void' });
  } qr/MySQL cannot honour the requested conflict target/,
    'and so is a named constraint';

  # the ADR's own worked example: a natural key on a table that also has a
  # surrogate primary key. The primary key IS a further unique key.
  throws_ok {
    $schema->resultset('CD')->upsert(
      { artist => 1, title => 'Bad', year => 1987 },
      { conflict_target => [qw/artist title/], result => 'void' });
  } qr/MySQL cannot honour the requested conflict target/,
    'the primary key itself counts as a further unique key';
}

# Case 2: a real target that is the table's only unique key. FourKeys has a
# four-column primary key and nothing else -- the semantics provably
# coincide, so this is allowed silently.
{
  my $schema = mysql_schema();
  my $sql;
  lives_ok {
    $sql = upsert_sql($schema, 'FourKeys',
      { foo => 1, bar => 2, hello => 3, goodbye => 4, sensors => 'y' },
      { result => 'void' });
  } 'a target that is the only unique key of the table is allowed';

  like $sql, qr/^INSERT INTO `fourkeys`/, 'and produces an ordinary upsert';
}

# Case 3: 'any' is the engine-native shape and always allowed
{
  my $schema = mysql_schema();
  lives_ok {
    upsert_sql($schema, 'Artist', { name => 'a' }, { conflict_target => 'any', result => 'void' });
  } "conflict_target => 'any' is what ON DUPLICATE KEY UPDATE already means";
}

# =========================================================================
# 4. Row identity -- ADR 0036 section 4, three cases
# =========================================================================

# Case 1: AUTO_INCREMENT primary key. The LAST_INSERT_ID(pk) idiom makes the
# server report the primary key of the row it actually touched, whichever
# unique index collided, and core's ordinary last_insert_id retrieval then
# names the row.
{
  my $schema = mysql_schema();
  $schema->storage->reset_captured;

  my $row = $schema->resultset('Artist')->upsert(
    { name => 'aphex', rank => 3 }, { conflict_target => 'any' });

  my ($sql) = captured_sql($schema);
  like $sql, qr/`artistid` = LAST_INSERT_ID\(`artistid`\)$/,
    'the identity idiom is appended for an AUTO_INCREMENT primary key';

  isa_ok $row, 'DBIO::Row', 'the written row is named';
  is $row->artistid, 1, 'and carries the primary key the server reported';
  is $row->name, 'aphex', 'and the attempted values';
}

# Case 1 does not apply when the caller supplies the AUTO_INCREMENT value
# itself: LAST_INSERT_ID() then says nothing about an inserted row, and with
# 'any' the collision may have happened on another key entirely. Handing back
# the supplied id would be a confidently wrong row.
{
  my $schema = mysql_schema();
  $schema->storage->reset_captured;

  my $row;
  warnings_like {
    $row = $schema->resultset('Artist')->upsert(
      { artistid => 7, name => 'aphex' }, { conflict_target => 'any' });
  } [
    qr/ON DUPLICATE KEY UPDATE does not report which key collided/,
    qr/could not name the row it wrote/,
  ], 'the driver explains the reason, core states the contract';

  is $row, undef, 'and no row is handed back';

  my ($sql) = captured_sql($schema);
  unlike $sql, qr/LAST_INSERT_ID/,
    'no identity idiom is emitted where it could not work';

  throws_ok {
    $schema->resultset('Artist')->upsert(
      { artistid => 7, name => 'aphex' },
      { conflict_target => 'any', result => 'row_or_die' });
  } qr/did not name it/, 'row_or_die throws on the same shape';
}

# Case 2: no AUTO_INCREMENT, but the effective target is the table's only
# unique key and the caller supplied it -- the collision can only have been
# on the primary key, so the row is named without asking the server.
{
  my $schema = mysql_schema();
  $schema->storage->reset_captured;

  my $row = $schema->resultset('FourKeys')->upsert(
    { foo => 1, bar => 2, hello => 3, goodbye => 4, sensors => 'y' });

  my ($sql) = captured_sql($schema);
  unlike $sql, qr/LAST_INSERT_ID/, 'no identity idiom needed';

  isa_ok $row, 'DBIO::Row', 'the written row is named from the target values';
  is $row->foo, 1, 'and carries the primary key the caller supplied';
  is $row->sensors, 'y', 'and the attempted values';
}

# Case 2 again, on an AUTO_INCREMENT table: a supplied primary key is not a
# problem when the target provably IS the primary key -- Collection has no
# other unique key, so the collision cannot have happened anywhere else.
# This is the distinction between "the id was supplied" (irrelevant on its
# own) and "the id was supplied AND another key could have collided".
{
  my $schema = mysql_schema();
  $schema->storage->reset_captured;

  my $row;
  warnings_are {
    $row = $schema->resultset('Collection')->upsert({ collectionid => 3, name => 'c' });
  } [], 'a supplied AUTO_INCREMENT key on a single-unique table is resolvable';

  isa_ok $row, 'DBIO::Row', 'the row is named';
  is $row->collectionid, 3, 'from the primary key the caller supplied';

  my ($sql) = captured_sql($schema);
  unlike $sql, qr/LAST_INSERT_ID/,
    'and the identity idiom is not needed for it';
}

# Case 3: no AUTO_INCREMENT primary key and two unique keys. Reachable only
# via conflict_target => 'any' (a real target throws, see above), and then
# genuinely unresolvable: the statement does not report which key collided.
{
  my $schema = mysql_schema();
  $schema->storage->reset_captured;

  my $row;
  warnings_like {
    $row = $schema->resultset('TwoKeyTreeLike')->upsert(
      { id1 => 1, id2 => 2, name => 'root' }, { conflict_target => 'any' });
  } [
    qr/TwoKeyTreeLike cannot name the row it wrote/,
    qr/could not name the row it wrote/,
  ], 'the unresolvable shape warns, naming the table and the reason';

  is $row, undef, 'row_or_undef is undef, not a guess';

  # carp_once means once: the second call through the same shape is silent
  warnings_are {
    $schema->resultset('TwoKeyTreeLike')->upsert(
      { id1 => 3, id2 => 4, name => 'other' },
      { conflict_target => 'any', result => 'row_or_undef' });
  } [], 'the warning is emitted once per process, not per call';

  throws_ok {
    $schema->resultset('TwoKeyTreeLike')->upsert(
      { id1 => 1, id2 => 2, name => 'root' },
      { conflict_target => 'any', result => 'row_or_die' });
  } qr/did not name it/, 'row_or_die throws rather than hand back nothing';
}

# result => 'count' / 'void' ask for one round-trip and nothing spent on
# naming the row, so the identity work is skipped entirely -- and the
# unresolvable shape has nothing to complain about.
{
  my $schema = mysql_schema();
  $schema->storage->reset_captured;

  my $count;
  warnings_are {
    $count = $schema->resultset('TwoKeyTreeLike')->upsert(
      { id1 => 5, id2 => 6, name => 'quiet' },
      { conflict_target => 'any', result => 'count' });
  } [], 'result => count does not warn about an identity nobody asked for';

  is $count, 1, 'and returns the affected-row count';
  is scalar(captured_sql($schema)), 1, 'in exactly one statement';
}

{
  my $schema = mysql_schema();
  $schema->storage->reset_captured;

  $schema->resultset('Artist')->upsert(
    { name => 'quiet' }, { conflict_target => 'any', result => 'void' });

  my ($sql) = captured_sql($schema);
  unlike $sql, qr/LAST_INSERT_ID/,
    'result => void spends nothing on the identity channel either';
}

# =========================================================================
# 5. DO NOTHING through the full stack
# =========================================================================

{
  my $schema = mysql_schema();

  my $sql = upsert_sql($schema, 'Artist',
    { name => 'a' }, { conflict_target => 'any', on_conflict => 'nothing', result => 'void' });

  is $sql,
    'INSERT INTO `artist` (`name`) VALUES (?) '
  . 'ON DUPLICATE KEY UPDATE `artistid` = `artistid`',
    'DO NOTHING with nothing to retrieve is a plain no-op set';

  $sql = upsert_sql($schema, 'Artist',
    { name => 'a' }, { conflict_target => 'any', on_conflict => 'nothing' });

  is $sql,
    'INSERT INTO `artist` (`name`) VALUES (?) '
  . 'ON DUPLICATE KEY UPDATE `artistid` = LAST_INSERT_ID(`artistid`)',
    'and doubles as the identity channel when a row is wanted back';
}

# =========================================================================
# 6. MariaDB returns the written row -- ADR 0036 section 4, rule 1 (karr #29)
# =========================================================================
#
# ADR 0036 assumed MariaDB could not combine RETURNING with ON DUPLICATE KEY
# UPDATE and built section 4 around that. Measured on MariaDB 11.8.8 on
# 2026-07-25, it can, and it returns the right row on both branches. So the
# engine names the row itself and none of the machinery above is needed there.
# The round-trip is the live half (t/25-upsert-live.t); what is decidable here
# is the capability gate and the statement it produces.

# --- the gate: a server fact, checked per server version -----------------

{
  set_server('8.0.46', '8.000046');
  is mysql_schema()->storage->_use_insert_returning, 0,
    'MySQL has no RETURNING at any version';
}

{
  set_server('10.4.34-MariaDB', '10.004034');
  is mysql_schema()->storage->_use_insert_returning, 0,
    'MariaDB below 10.5 has no RETURNING either';
}

{
  set_server('10.5.0-MariaDB', '10.005000');
  is mysql_schema()->storage->_use_insert_returning, 1,
    'MariaDB 10.5 is where INSERT ... RETURNING arrived';
}

{
  set_server('11.8.8-MariaDB-ubu2404', '11.008008');
  is mysql_schema()->storage->_use_insert_returning, 1,
    'and every MariaDB since';

  # ... and the DBD the connection happens to use has no say in it: the same
  # server through the DBD::MariaDB storage class answers the same, and a
  # MySQL server through that class answers no (see t/26-server-version.t).
  is mysql_schema('DBIO::MySQL::Storage::MariaDB')->storage->_use_insert_returning, 1,
    'the capability follows the server, not the storage class';
}

{
  set_server('8.0.46', '8.000046');
  is mysql_schema('DBIO::MySQL::Storage::MariaDB')->storage->_use_insert_returning, 0,
    'a MySQL server reached through DBD::MariaDB is not promised RETURNING';
}

# --- the statement ---------------------------------------------------------

set_server('11.8.8-MariaDB-ubu2404', '11.008008');

{
  my $schema = mysql_schema();
  $schema->storage->mock(qr/RETURNING/, [ [ 42 ] ]);
  $schema->storage->reset_captured;

  my $row = $schema->resultset('Artist')->upsert(
    { name => 'aphex' }, { conflict_target => 'any' });

  my ($sql) = captured_sql($schema);

  is $sql,
    'INSERT INTO `artist` (`name`) VALUES (?) '
  . 'ON DUPLICATE KEY UPDATE `name` = VALUES(`name`) '
  . 'RETURNING `artistid`',
    'the conflict clause is rendered before RETURNING, in grammar order';

  unlike $sql, qr/LAST_INSERT_ID/,
    'and the identity idiom is gone -- the engine hands the row back itself';

  isa_ok $row, 'DBIO::Row', 'the written row';
  is $row->artistid, 42, 'carries the primary key RETURNING reported';
  is $row->name, 'aphex', 'and the attempted values';

  is scalar(captured_sql($schema)), 1, 'in exactly one statement';
}

# The capability is not upsert-only. Declaring it changes every insert on a
# MariaDB server: the generated key arrives with the statement instead of
# through last_insert_id plus, where more columns are wanted, a follow-up
# SELECT.
{
  my $schema = mysql_schema();
  $schema->storage->mock(qr/RETURNING/, [ [ 99 ] ]);
  $schema->storage->reset_captured;

  my $row = $schema->resultset('Artist')->create({ name => 'plain' });

  is +(captured_sql($schema))[0],
    'INSERT INTO `artist` (`name`) VALUES (?) RETURNING `artistid`',
    'a plain create goes through RETURNING as well';
  is $row->artistid, 99, 'and takes its key from the row the server returned';
}

# DO NOTHING still needs an assignment; without the identity idiom the no-op
# column is what provides it.
{
  my $schema = mysql_schema();
  $schema->storage->mock(qr/RETURNING/, [ [ 7 ] ]);

  is upsert_sql($schema, 'Artist',
      { name => 'a' }, { conflict_target => 'any', on_conflict => 'nothing' }),
    'INSERT INTO `artist` (`name`) VALUES (?) '
  . 'ON DUPLICATE KEY UPDATE `artistid` = `artistid` '
  . 'RETURNING `artistid`',
    'DO NOTHING is a plain no-op set again, not the LAST_INSERT_ID form';
}

# result => 'void' asks for one round-trip and no identity work, so there is
# no RETURNING tail to fetch either.
{
  my $schema = mysql_schema();

  my $sql = upsert_sql($schema, 'Artist',
    { name => 'a' }, { conflict_target => 'any', result => 'void' });

  unlike $sql, qr/RETURNING/, 'result => void asks the server for nothing back';
}

# What RETURNING does NOT fix: core only asks for the columns it does not
# already have, so a caller-supplied primary key produces no RETURNING column
# and the value in hand is still the caller's own, not evidence of which row a
# targetless statement touched. The unresolvable path stays reachable on
# MariaDB -- fewer shapes than on MySQL, but not none.
{
  my $schema = mysql_schema();
  $schema->storage->reset_captured;

  my $row = $schema->resultset('Artist')->upsert(
    { artistid => 7, name => 'aphex' },
    { conflict_target => 'any', result => 'row_or_undef' });

  my ($sql) = captured_sql($schema);
  unlike $sql, qr/RETURNING/,
    'a supplied primary key leaves core nothing to ask RETURNING for';
  unlike $sql, qr/LAST_INSERT_ID/,
    'and the idiom could not name the row either';

  is $row, undef, 'so the row is still not named on MariaDB';
}

{
  my $schema = mysql_schema();
  $schema->storage->reset_captured;

  my $row = $schema->resultset('TwoKeyTreeLike')->upsert(
    { id1 => 1, id2 => 2, name => 'root' },
    { conflict_target => 'any', result => 'row_or_undef' });

  is $row, undef,
    'and neither is a supplied composite key on a multi-unique table';
}

# --- the two traps of ADR 0036 section 2, at the renderer ------------------

{
  my $options = {
    returning   => ['artistid'],
    on_conflict => {
      target => 'any',
      action => 'update',
      set    => { name => { -attempted => 'name' } }
    }
  };

  my ($sql) = maker()->insert('artist', { name => 'x' }, $options);

  is $sql,
    'INSERT INTO `artist` (`name`) VALUES (?) '
  . 'ON DUPLICATE KEY UPDATE `name` = VALUES(`name`) '
  . 'RETURNING `artistid`',
    'trap 1: the conflict clause is placed before RETURNING, not appended after';

  ok ! exists $options->{on_conflict}, 'on_conflict is still consumed';
  is_deeply $options->{returning}, ['artistid'],
    'trap 2: returning is put back -- core reads it again after _execute to '
  . 'decide whether to fetch the row';
}

# Plain inserts go through the same assembly, so they have to come out
# unchanged -- with and without a RETURNING tail.
{
  my ($sql, @bind) = maker()->insert('artist', { name => 'x' });
  is $sql, 'INSERT INTO `artist` (`name`) VALUES (?)',
    'a plain insert is untouched';
  is scalar @bind, 1, 'with its bind';

  ($sql) = maker()->insert('artist', { name => 'x' }, { returning => ['artistid'] });
  is $sql, 'INSERT INTO `artist` (`name`) VALUES (?) RETURNING `artistid`',
    'a plain insert with RETURNING renders the tail once';

  ($sql) = maker()->insert('artist', {}, { returning => ['artistid'] });
  is $sql, 'INSERT INTO `artist` () VALUES () RETURNING `artistid`',
    "and MySQL's no-column form carries it too, instead of dropping it";
}

# =========================================================================
# 7. The conditional conflict branch -- supports_upsert_where (core #105)
# =========================================================================
#
# Core grew a conditional DO UPDATE, reachable as upsert's update_where
# option and gated by the supports_upsert_where capability. MySQL has no
# equivalent: ON DUPLICATE KEY UPDATE takes no WHERE, and the nearest thing
# -- an IF() expression per column in the set -- is a different shape that
# still writes the row. So this driver declares nothing and renders nothing,
# and the whole of its correctness here consists of NOT acting. Which is
# precisely why it is pinned: correctness that lives in an absence is the
# kind that disappears the day somebody sets capability flags in bulk.
#
# The reason the option has a capability of its own, instead of core trusting
# each driver to throw: every other dialect difference announces itself -- a
# dropped conflict target is invalid SQL on PostgreSQL, an ignored
# action => 'nothing' leaves no set to write. A dropped WHERE renders a
# perfectly valid UNCONDITIONAL update, i.e. exactly the last-write-wins
# overwrite the condition was written to prevent, with no symptom at all.

set_server('8.0.19', '8.000019');

{
  my $schema = mysql_schema();

  is $schema->storage->_use_supports_upsert_where, 0,
    'MySQL does not declare supports_upsert_where';
  is $schema->storage->_use_supports_upsert, 1,
    'while still declaring the unconditional upsert it does have';
}

# MariaDB is where a bulk flag-flip would land first -- it is the half of this
# driver that did gain a capability the other half lacks (insert_returning,
# section 6). It has no conditional conflict branch either.
{
  set_server('11.8.8-MariaDB-ubu2404', '11.008008');
  is mysql_schema('DBIO::MySQL::Storage::MariaDB')->storage->_use_supports_upsert_where, 0,
    'and neither does MariaDB, at any version';
  set_server('8.0.19', '8.000019');
}

# So the option is refused in core, before a statement exists.
# conflict_target => 'any' leaves the missing capability as the only thing
# that can throw here.
{
  my $schema = mysql_schema();

  throws_ok {
    $schema->resultset('Artist')->upsert(
      { name => 'a', rank => 3 },
      { conflict_target => 'any',
        update_where    => { rank => { '<' => { -attempted => 'rank' } } },
        result          => 'void' });
  } qr/does not declare the supports_upsert_where capability/,
    'update_where is refused rather than turned into an unconditional write';

  # The prefix pins the core namespace, not the method: core has moved this
  # throw (upsert() -> _upsert_prepare(), core karr #134) and may move it
  # again. What is being asserted is that the refusal is core's, not this
  # driver's -- a method name would re-break on the next move.
  like $@, qr/^DBIO::ResultSet::/,
    'and the refusal is core\'s, not something this driver has to remember';

  is scalar(captured_sql($schema)), 0, 'nothing reached the server';
}

# The same refusal one layer down, for anything that assembles the on_conflict
# structure itself instead of going through upsert(): core gates it a second
# time in DBIO::Storage::DBI::insert, so the condition cannot reach this
# driver's SQLMaker whoever built it.
{
  my $schema = mysql_schema();

  throws_ok {
    $schema->storage->insert(
      $schema->source('Artist'),
      { name => 'a' },
      { no_retrieve => 1,
        on_conflict => {
          target => 'any',
          action => 'update',
          set    => { name => { -attempted => 'name' } },
          where  => { rank => { '<' => 3 } }
        } });
  } qr/^DBIO::Storage::DBI::insert\(\).+does not declare the supports_upsert_where/s,
    'and again at the storage, before the structure reaches the SQLMaker';

  is scalar(captured_sql($schema)), 0, 'still nothing sent';
}

# ... which is what those two gates stand between. Handed a condition anyway,
# the renderer drops it and produces a valid statement that overwrites
# unconditionally -- no error, no warning, nothing in the SQL to notice. If a
# conditional form is ever added here, the capability has to be declared in
# the same change that renders it, and this assertion is what says so.
{
  my ($sql) = maker()->insert(
    'artist',
    { name => 'x' },
    { on_conflict => {
        target => 'any',
        action => 'update',
        set    => { name => { -attempted => 'name' } },
        where  => { rank => { '<' => 3 } }
    } }
  );

  is $sql,
    'INSERT INTO `artist` (`name`) VALUES (?) '
  . 'ON DUPLICATE KEY UPDATE `name` = VALUES(`name`)',
    'the renderer drops a where it cannot place, and says nothing about it';
}

done_testing;
