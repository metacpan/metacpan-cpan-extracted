use strict;
use warnings;

use Test::More;
use Test::Exception;

# ADR 0036, atomic upsert -- the live half. Everything metadata-driven (SQL
# shapes, conflict-target refusals, the identity case distinction) is covered
# offline in t/24-upsert-mysql.t; what needs a server is the round-trip: that
# the statement is accepted by this server version, and that the row handed
# back is the row that was actually written.
#
# RESOURCE DISCIPLINE: run this SERIALLY, never with prove -j, and prefix the
# run with `nice -n 19 ionice -c3`. One database pod at a time, with
# resources.limits, deleted when done.

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $ENV{DBIO_TEST_MYSQL_DSN};

{
  # AUTO_INCREMENT primary key plus a natural unique key: the shape where the
  # LAST_INSERT_ID(pk) idiom is the only identity channel (section 4, rule 3).
  package UPS::Result::Auto;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbio_upsert_auto');
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1 },
    name    => { data_type => 'varchar', size => 64 },
    payload => { data_type => 'varchar', size => 64, is_nullable => 1 },
    hits    => { data_type => 'integer', default_value => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(auto_name => ['name']);

  # A natural primary key and nothing else: the target is provably the only
  # unique key, so the row is named from the values the caller supplied.
  package UPS::Result::Single;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbio_upsert_single');
  __PACKAGE__->add_columns(
    k1      => { data_type => 'integer' },
    k2      => { data_type => 'integer' },
    payload => { data_type => 'varchar', size => 64, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key(qw/k1 k2/);

  # No AUTO_INCREMENT and two unique keys: the row cannot be named.
  package UPS::Result::Multi;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbio_upsert_multi');
  __PACKAGE__->add_columns(
    k1      => { data_type => 'integer' },
    k2      => { data_type => 'integer' },
    name    => { data_type => 'varchar', size => 64 },
    payload => { data_type => 'varchar', size => 64, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key(qw/k1 k2/);
  __PACKAGE__->add_unique_constraint(multi_name => ['name']);

  package UPS::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Auto   => 'UPS::Result::Auto');
  __PACKAGE__->register_class(Single => 'UPS::Result::Single');
  __PACKAGE__->register_class(Multi  => 'UPS::Result::Multi');
}

# A schema always declares its driver (core ADR 0067): the component of the
# storage class the DSN's DBD is registered for -- MySQL::MariaDB for a
# dbi:MariaDB: DSN.
UPS::Schema->load_components(
  $ENV{DBIO_TEST_MYSQL_DSN} =~ /\Adbi:MariaDB:/i ? 'MySQL::MariaDB' : 'MySQL'
);

my $schema = UPS::Schema->connect(
  $ENV{DBIO_TEST_MYSQL_DSN},
  $ENV{DBIO_TEST_MYSQL_USER},
  $ENV{DBIO_TEST_MYSQL_PASS},
);

diag 'server: ' . ($schema->storage->_server_info->{dbms_version} // '?')
   . ' / row alias: ' . ($schema->storage->_upsert_row_alias // 'none')
   . ' / MariaDB: ' . ($schema->storage->_is_mariadb ? 'yes' : 'no');

# --- the version the driver believes in (karr #28) -----------------------
#
# The decision logic is pinned offline in t/26-server-version.t, on both of
# the strings a real server produced. What only a server can say is which of
# them this connection gets: DBD::MariaDB reports get_info(SQL_DBMS_VER) in a
# packed form (08.00.4600 for MySQL 8.0.46), which core's normaliser truncates
# to 8.0.0 -- so every gate below the minor version silently read a server
# that does not exist. Nothing here may be derived from the storage's own
# answer; the reference is the string the server states.

{
  my $storage = $schema->storage;
  my ($reported) = $storage->_get_dbh->selectrow_array('SELECT VERSION()');

  is $storage->_server_info->{dbms_version}, $reported,
    'the storage reports the version the server states about itself';

  my ($maj, $min, $patch) = $reported =~ /^(\d+)\.(\d+)\.(\d+)/;
  is $storage->_server_info->{normalized_dbms_version},
     sprintf('%d.%03d%03d', $maj, $min, $patch),
     'and normalizes every component of it, patch level included';

  is $storage->_is_mariadb, ($reported =~ /mariadb/i ? 1 : 0),
    'the product is read off that same string';

  # ... and the row-alias form follows, computed here from the parsed string
  # rather than from anything the storage decided.
  if ($reported =~ /mariadb/i) {
    is $storage->_upsert_row_alias, undef,
      'MariaDB never grew the row alias, so VALUES(col) it is';
  }
  elsif ($maj > 8 or ($maj == 8 and ($min > 0 or $patch >= 20))) {
    is $storage->_upsert_row_alias, 'new',
      'a MySQL >= 8.0.20 uses the row alias, not the form it deprecated there';
  }
  else {
    is $storage->_upsert_row_alias, undef,
      'a MySQL < 8.0.20 has no row alias yet';
  }
}

$schema->storage->dbh_do(sub {
  my ($storage, $dbh) = @_;
  $dbh->do('DROP TABLE IF EXISTS dbio_upsert_auto');
  $dbh->do('DROP TABLE IF EXISTS dbio_upsert_single');
  $dbh->do('DROP TABLE IF EXISTS dbio_upsert_multi');
  $dbh->do(q{
    CREATE TABLE dbio_upsert_auto (
      id      BIGINT      NOT NULL AUTO_INCREMENT,
      name    VARCHAR(64) NOT NULL,
      payload VARCHAR(64)     NULL,
      hits    INT         NOT NULL DEFAULT 0,
      PRIMARY KEY (id),
      UNIQUE KEY auto_name (name)
    )
  });
  $dbh->do(q{
    CREATE TABLE dbio_upsert_single (
      k1      INT         NOT NULL,
      k2      INT         NOT NULL,
      payload VARCHAR(64)     NULL,
      PRIMARY KEY (k1, k2)
    )
  });
  $dbh->do(q{
    CREATE TABLE dbio_upsert_multi (
      k1      INT         NOT NULL,
      k2      INT         NOT NULL,
      name    VARCHAR(64) NOT NULL,
      payload VARCHAR(64)     NULL,
      PRIMARY KEY (k1, k2),
      UNIQUE KEY multi_name (name)
    )
  });
});

is $schema->storage->_use_supports_upsert, 1, 'the live storage declares supports_upsert';

# --- identity case 1: AUTO_INCREMENT primary key -------------------------

my $auto = $schema->resultset('Auto');

{
  my $row = $auto->upsert({ name => 'a', payload => 'first' }, { conflict_target => 'any' });
  isa_ok $row, 'DBIO::Row', 'insert branch returns the written row';
  ok $row->id, 'with the generated primary key';
  is $row->payload, 'first', 'and the written payload';

  my $id = $row->id;

  # the update branch: same natural key, different payload. LAST_INSERT_ID(pk)
  # has to report the id of the row that was updated, not a new one.
  my $again = $auto->upsert({ name => 'a', payload => 'second' }, { conflict_target => 'any' });
  isa_ok $again, 'DBIO::Row', 'update branch returns a row too';
  is $again->id, $id, 'and it is the row that already existed';
  is $auto->find($id)->payload, 'second', 'which really was updated';
  is $auto->count, 1, 'no second row was created';

  # THE assertion ADR 0036 makes without proof: an update branch that changes
  # no value at all reports 0 affected rows on MySQL. If LAST_INSERT_ID(pk)
  # goes stale there, the whole AUTO_INCREMENT identity path is wrong and
  # DBIO::MySQL::Storage::_mysql_upsert_plan case 1 has to fall back to the
  # unresolvable path.
  my $unchanged = $auto->upsert({ name => 'a', payload => 'second' }, { conflict_target => 'any' });
  isa_ok $unchanged, 'DBIO::Row', 'an update that changes nothing still names a row';
  is $unchanged->id, $id, 'and it is still the right one (ADR 0036 assertion (i))';
}

# count is the engine's own figure: 1 inserted, 2 updated
{
  is $auto->upsert({ name => 'b', payload => 'x' }, { conflict_target => 'any', result => 'count' }),
    1, 'affected rows on the insert branch is 1';
  is $auto->upsert({ name => 'b', payload => 'y' }, { conflict_target => 'any', result => 'count' }),
    2, 'affected rows on the update branch is 2';
}

# a restricted update set, and a literal expression over the existing row
{
  $auto->upsert({ name => 'c', payload => 'p', hits => 1 }, { conflict_target => 'any' });
  $auto->upsert(
    { name => 'c', payload => 'ignored', hits => 1 },
    { conflict_target => 'any', update => { hits => \'hits + 1' } },
  );

  my $row = $auto->find({ name => 'c' });
  is $row->hits, 2, 'a literal conflict expression is evaluated by the server';
  is $row->payload, 'p', 'and a restricted update set leaves the rest alone';
}

# DO NOTHING, emulated with a no-op set
{
  $auto->upsert({ name => 'd', payload => 'keep' }, { conflict_target => 'any' });
  $auto->upsert(
    { name => 'd', payload => 'discard' },
    { conflict_target => 'any', on_conflict => 'nothing' },
  );
  is $auto->find({ name => 'd' })->payload, 'keep',
    'DO NOTHING leaves the existing row untouched';
}

# --- MariaDB hands the written row back itself (karr #29) ----------------
#
# ADR 0036 assumed MariaDB could not combine RETURNING with ON DUPLICATE KEY
# UPDATE and built its whole MySQL identity story on that. Measured on 11.8.8
# on 2026-07-25 it can, and returns the right row on both branches. Everything
# above already runs through that path on such a server -- an unaccepted
# combination would fail every upsert in this file -- so what is pinned here is
# that the driver really takes it: one statement, RETURNING after the conflict
# clause, and no LAST_INSERT_ID no-op carried along for nobody.

{
  my $storage  = $schema->storage;
  my ($server) = $storage->_get_dbh->selectrow_array('SELECT VERSION()');
  my ($maj, $min) = $server =~ /^(\d+)\.(\d+)/;

  my $expected =
    ( $server =~ /mariadb/i and ($maj > 10 or ($maj == 10 and $min >= 5)) )
      ? 1 : 0;

  is $storage->_use_insert_returning, $expected,
    'insert_returning is declared exactly for MariaDB 10.5 and up';

  SKIP: {
    skip 'INSERT ... RETURNING needs a MariaDB 10.5 or newer', 6
      unless $expected;

    my @sql;
    my $prev_debug = $storage->debug;
    my $prev_cb    = $storage->debugcb;
    $storage->debugcb(sub { push @sql, $_[1] });
    $storage->debug(1);

    my $row = $auto->upsert(
      { name => 'ret', payload => 'first' }, { conflict_target => 'any' });

    my $again = $auto->upsert(
      { name => 'ret', payload => 'second' }, { conflict_target => 'any' });

    $storage->debug($prev_debug);
    $storage->debugcb($prev_cb);

    is scalar @sql, 2,
      'one statement per upsert -- no follow-up SELECT to name the row';
    like $sql[0], qr/ON DUPLICATE KEY UPDATE .+ RETURNING /,
      'the conflict clause is placed before RETURNING';
    unlike $sql[0], qr/LAST_INSERT_ID/,
      'and the identity idiom is left out where the engine returns the row';

    ok $row->id, 'the insert branch returns the generated key';
    is $again->id, $row->id,
      'the update branch returns the row that already existed';
    is $again->payload, 'second',
      'carrying the values it was just given (ADR 0036 section 4, rule 1)';

    # Open on this server: whether a conflict set that writes nothing back --
    # the DO NOTHING emulation -- still yields a RETURNING row here. Both
    # answers are legitimate (ADR 0036 records MySQL returning the existing row
    # and PostgreSQL returning none); this only records which one MariaDB gives.
    $auto->upsert({ name => 'nop', payload => 'keep' }, { conflict_target => 'any' });
    my $nothing = $auto->upsert(
      { name => 'nop', payload => 'discard' },
      { conflict_target => 'any', on_conflict => 'nothing', result => 'row_or_undef' },
    );
    diag 'MariaDB DO NOTHING on an existing row returned: '
       . (defined $nothing ? 'the row (id ' . $nothing->id . ')' : 'undef');
  }
}

# --- identity case 2: the target is the only unique key ------------------

{
  my $single = $schema->resultset('Single');

  my $row = $single->upsert({ k1 => 1, k2 => 2, payload => 'first' });
  isa_ok $row, 'DBIO::Row', 'a natural-key upsert returns the row';
  is $row->k1, 1, 'named from the target values';

  $single->upsert({ k1 => 1, k2 => 2, payload => 'second' });
  is $single->find(1, 2)->payload, 'second', 'and the second call updated it';
  is $single->count, 1, 'in place';
}

# --- identity case 3: nothing can name the row ---------------------------

{
  my $multi = $schema->resultset('Multi');

  my $row;
  {
    local $SIG{__WARN__} = sub { };   # the carp_once is asserted offline
    $row = $multi->upsert(
      { k1 => 1, k2 => 2, name => 'n', payload => 'first' },
      { conflict_target => 'any' },
    );
  }
  is $row, undef, 'the unresolvable shape returns undef rather than a guess';
  is $multi->count, 1, 'even though the row was written';

  throws_ok {
    $multi->upsert(
      { k1 => 1, k2 => 2, name => 'n', payload => 'second' },
      { conflict_target => 'any', result => 'row_or_die' },
    );
  } qr/did not name it/, 'and row_or_die throws';

  is $multi->find(1, 2)->payload, 'second',
    'the write itself happened all the same';
}

# --- conflict target refusals, against a real server ---------------------

{
  throws_ok {
    $auto->upsert({ id => 1, name => 'z' });
  } qr/MySQL cannot honour the requested conflict target/,
    'a demanded target is still refused with a server in reach';
}

$schema->storage->dbh_do(sub {
  my ($storage, $dbh) = @_;
  $dbh->do('DROP TABLE IF EXISTS dbio_upsert_auto');
  $dbh->do('DROP TABLE IF EXISTS dbio_upsert_single');
  $dbh->do('DROP TABLE IF EXISTS dbio_upsert_multi');
});

done_testing;
