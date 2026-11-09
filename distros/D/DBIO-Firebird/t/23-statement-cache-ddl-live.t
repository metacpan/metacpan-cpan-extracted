use strict;
use warnings;
use Test::More;

# LIVE (karr k37): a process that reads and writes through the ORM, changes the
# schema over the same connection, and goes on reading and writing.
#
# DBD::Firebird destroys every statement of a connection when it commits after
# DDL -- any DDL, on any table -- and on every hard rollback inside a
# transaction. The Perl handles stay in DBI's statement cache, and the storage
# prepares through that cache. A destroyed handle does not fail:
#
#   * a SELECT executes, the fetch warns `no statement executing` and the ORM
#     gets no row;
#   * an INSERT or UPDATE executes, answers 0E0 and writes nothing.
#
# Both without an exception, and for every later use of that SQL until the
# storage reconnects. DBIO::Firebird::Deploy runs its DDL over the storage's
# connection, so "read, upgrade, read" was enough to get there.
#
# What this file claims, on ONE connection with statement caching on (the
# default), without ib_softcommit and with it:
#
#   1. the same SQL gets the same statement handle while nothing destroys it --
#      so nothing below is green because the cache was switched off;
#   2. a row read before Deploy->upgrade is read again after it, with the same
#      SQL;
#   3. the same after plain DDL on ANOTHER table, run on the handle directly;
#   4. an UPDATE and an INSERT that ran before DDL write again after it -- seen
#      from a second connection, because the storage itself notices nothing;
#   5. the same after a rolled-back txn_do;
#   6. a table the statements prepared since read from can be dropped over that
#      connection: they are on the DBD's list of statements, which is what lets
#      it destroy them before the commit that drops the table.
#
# And the assumption all of it rests on, said where a DBD release that breaks
# it turns red by name: asked through the storage's _sth_is_alive, a prepared
# handle answers true, and the same handle answers false once the DBD has
# destroyed it.
#
# The result class is the shared one from core (not redefined here).
#
# Skipped unless a DSN is provided (as t/15, t/19):
#
#   DBIO_TEST_FIREBIRD_DSN
#   DBIO_TEST_FIREBIRD_USER
#   DBIO_TEST_FIREBIRD_PASS
#
# WARNING: creates and drops the tables "artist" and "k37_other".

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live statement cache tests'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

use Scalar::Util ();
use DBIO::Firebird::Deploy;

{
  package DBIO::Firebird::Test::K37Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Firebird');
  __PACKAGE__->load_classes({ 'DBIO::Test::Schema' => [qw/ Artist /] });
}

# karr k34: install_ddl writes the unique constraints of the shared class, and
# every column of Artist is in one; this file drops a column the upgrade then
# adds back, which the diff refuses for a column a constraint uses. The
# statement cache is the subject here, constraints are t/29's: the
# process-local copy of the source has none.
{
  my $s = DBIO::Firebird::Test::K37Schema->source('Artist');
  delete @{ $s->{_unique_constraints} }{ grep { $_ ne 'primary' } keys %{ $s->{_unique_constraints} } };
}

# The second connection: what is in the database, whatever the first one
# believes. It also drops the tables, once the first one is closed.
my $other = DBI->connect($dsn, $user, $pass, {
  RaiseError => 1, PrintError => 0, AutoCommit => 1, ib_dialect => 3,
}) or plan skip_all => 'Cannot connect: ' . DBI->errstr;
$other->func(-lock_resolution => { wait => 10 }, 'ib_set_tx_param');

note "DBD::Firebird $DBD::Firebird::VERSION";

for my $case (
  [ 'without ib_softcommit' => {},                                    0 ],
  [ 'with ib_softcommit'    => { on_connect_call => 'use_softcommit' }, 1 ],
) {
  my ($label, $attrs, $softcommit) = @$case;

  my $schema = DBIO::Firebird::Test::K37Schema->connect($dsn, $user, $pass, {
    quote_names => 1, %$attrs,
  });

  # Core announces non-transactional DDL once per process; it is accurate and
  # it is not what this file is about. Everything else is kept and looked at.
  my @warnings;
  local $SIG{__WARN__} = sub {
    push @warnings, $_[0] unless $_[0] =~ /^non-transactional DDL on /;
  };

  cleanup($schema);
  my $done = eval { run_case($label, $schema, $softcommit); 1 };
  my $died = $@;
  cleanup($schema);

  ok($done, "$label: ran to its end") or diag "died: $died";

  is_deeply([ grep { /no statement executing/ } @warnings ], [],
    "$label: no `no statement executing` from a statement handle");
  diag "warning: $_" for grep { !/no statement executing/ } @warnings;
}

$other->disconnect;
done_testing;

sub run_case {
  my ($label, $schema, $softcommit) = @_;

  my $storage = $schema->storage;
  my $deploy  = DBIO::Firebird::Deploy->new(schema => $schema);

  # Two columns only, so that the SQL is the same before and after the column
  # the upgrade adds.
  my $rs = $schema->resultset('Artist')->search({}, { columns => [qw/ artistid name /] });

  my $name_of = sub {
    my $row = $rs->find($_[0]);
    return $row && $row->name;
  };
  my $ddl = sub {
    my ($sql) = @_;
    $storage->dbh_do(sub { $_[1]->do($sql) });
  };

  # the statement $name_of runs, as DBI's cache holds it
  my $cached_select = sub {
    my @sth = grep { $_->{Statement} =~ /^SELECT .* FROM "artist" .* WHERE .*"artistid" = \?/ }
      values %{ $storage->dbh->{CachedKids} || {} };
    return @sth == 1 ? $sth[0] : undef;
  };

  # --- setup ------------------------------------------------------------------
  $deploy->install;
  # the column Deploy->upgrade will have to add
  $ddl->('ALTER TABLE "artist" DROP "charfield"');

  $schema->resultset('Artist')->create({ artistid => 1, name => 'Alpha' });

  # --- 1. the cache is a cache ------------------------------------------------
  part("$label: 1. statement cache in effect", sub {
    is($name_of->(1), 'Alpha', "$label: a row read through the ORM");

    my $first = $cached_select->();
    ok($first, '... its statement is in the cache of the handle');

    $name_of->(1);
    my $again = $cached_select->();
    ok($first && $again && Scalar::Util::refaddr($first) == Scalar::Util::refaddr($again),
      '... and with nothing destroying it, the same SQL runs on the same statement handle');

    ok($first && $storage->_sth_is_alive($first),
      'the DBD: a prepared statement handle answers the storage\'s question with true');
  });

  # --- 2. Deploy->upgrade on this connection ----------------------------------
  part("$label: 2. Deploy->upgrade", sub {
    my $diff = $deploy->diff;
    is($diff && $diff->as_sql, 'ALTER TABLE "artist" ADD "charfield" char(10);',
      "$label: the upgrade has a column to add");

    $deploy->upgrade;

    is($name_of->(1), 'Alpha',
      '... and the row read before the upgrade is read again after it, with the same SQL');

    my ($added) = $other->selectrow_array(
      q{SELECT COUNT(*) FROM rdb$relation_fields }
    . q{WHERE rdb$relation_name = 'artist' AND rdb$field_name = 'charfield'}
    );
    is($added, 1, '... the upgrade having added the column');
  });

  # --- 3. plain DDL on another table ------------------------------------------
  # Created here and not in the setup: a table the schema does not know is one
  # the upgrade above would have dropped.
  $ddl->('CREATE TABLE "k37_other" ("id" INTEGER NOT NULL PRIMARY KEY)');

  part("$label: 3. DDL on another table", sub {
    $name_of->(1);
    ok(do { my $sth = $cached_select->(); $sth && $storage->_sth_is_alive($sth) },
      "$label: the statement is prepared and in the cache");

    $ddl->('ALTER TABLE "k37_other" ADD "extra1" INTEGER');

    ok(do { my $sth = $cached_select->(); $sth && !$storage->_sth_is_alive($sth) },
      'the DBD: after DDL on another table and its commit, that same handle is '
    . 'still in the cache and answers false -- destroyed');

    is($name_of->(1), 'Alpha', '... and the ORM reads the row all the same');

    ok(do { my $sth = $cached_select->(); $sth && $storage->_sth_is_alive($sth) },
      '... from a statement prepared anew, which is the one in the cache now');
  });

  # --- 4. writes --------------------------------------------------------------
  part("$label: 4. UPDATE and INSERT", sub {
    my $row = $rs->find(1);
    $row->update({ name => 'Beta' });
    $schema->resultset('Artist')->create({ artistid => 2, name => 'Second' });
    is_deeply(names(), { 1 => 'Beta', 2 => 'Second' },
      "$label: an UPDATE and an INSERT, both in the database");

    $ddl->('ALTER TABLE "k37_other" ADD "extra2" INTEGER');

    $row->update({ name => 'Gamma' });
    is(names()->{1}, 'Gamma',
      '... after DDL the same UPDATE is in the database too, not merely reported as done');

    $schema->resultset('Artist')->create({ artistid => 3, name => 'Third' });
    is(names()->{3}, 'Third', '... and so is the same INSERT');

    $ddl->('ALTER TABLE "k37_other" ADD "extra3" INTEGER');

    $schema->resultset('Artist')->create({ artistid => 4, name => 'Fourth' });
    is(names()->{4}, 'Fourth', '... and the INSERT that is the first statement after DDL');
  });

  # --- 5. a rolled-back transaction -------------------------------------------
  part("$label: 5. rolled-back txn_do", sub {
    $name_of->(1);

    my $lived = eval {
      $schema->txn_do(sub {
        $rs->find(1)->update({ name => 'never' });
        die "k37 rollback\n";
      });
      1;
    };
    ok(!$lived && $@ =~ /k37 rollback/, "$label: a txn_do that dies is rolled back")
      or diag $@;

    # Not asked under ib_softcommit: the rollback is a retaining one there, and
    # what it leaves of the statement is not this file's claim.
    ok(do { my $sth = $cached_select->(); $sth && !$storage->_sth_is_alive($sth) },
      'the DBD: the rollback destroyed the statement, without any DDL')
      unless $softcommit;

    is($name_of->(1), 'Gamma', '... and the row is read afterwards, as it was before the transaction');
    is(names()->{1}, 'Gamma', '... which is what the database holds');
  });

  # --- 6. the new statements are the DBD's to destroy --------------------------
  part("$label: 6. DROP TABLE over this connection", sub {
    $name_of->(1);
    $ddl->('ALTER TABLE "k37_other" ADD "extra4" INTEGER');

    # A statement first prepared between the DDL and the moment the storage
    # meets a destroyed handle ...
    my $by_name = $schema->resultset('Artist')
      ->search({ name => 'Gamma' }, { columns => ['artistid'] })->single;
    is($by_name && $by_name->artistid, 1, "$label: a statement first prepared after DDL");

    # ... which is here.
    is($name_of->(1), 'Gamma', '... then one the DDL had destroyed');

    # On the handle itself: a refusal by the server (`object TABLE "artist" is
    # in use`) then shows here as the DROP failing. Through dbh_do it was once
    # answered "dropped" by a reconnect and a second run of the DROP (karr k49,
    # t/32-failed-ddl-no-reconnect-live.t); the handle is the plainer witness.
    my $dbh     = $storage->dbh;
    my $dropped = eval { $dbh->do('DROP TABLE "artist"'); 1 };
    ok($dropped, '... and the table both read from is dropped over the same '
               . 'connection: neither statement was left prepared behind the DBD\'s back')
      or diag $@;
  });

  return 1;
}

# Run one part; a death in it is that part's failure and the next one runs.
sub part {
  my ($name, $code) = @_;
  return 1 if eval { $code->(); 1 };
  fail("$name: died");
  diag $@;
  return;
}

# artistid => name, as the second connection sees it
sub names {
  return { map { $_->[0] => $_->[1] }
    @{ $other->selectall_arrayref('SELECT "artistid", "name" FROM "artist"') } };
}

# Drop whatever this file creates, with the schema's connection closed first so
# that none of its statements holds a table. The bare spelling is what an
# install DDL that does not quote would have created.
sub cleanup {
  my ($schema) = @_;
  $schema->storage->disconnect;
  for my $drop ('DROP TABLE "k37_other"', 'DROP TABLE "artist"', 'DROP TABLE artist') {
    eval { $other->do($drop) };
  }
  return;
}
