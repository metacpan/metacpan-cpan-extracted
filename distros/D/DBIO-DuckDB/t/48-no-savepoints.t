#!/usr/bin/env perl
# t/48-no-savepoints.t — this driver has no savepoints (karr k31).
#
# DuckDB has no SAVEPOINT. Measured on libduckdb v1.5.3: SAVEPOINT, RELEASE
# SAVEPOINT and ROLLBACK TO SAVEPOINT are each a Parser Error, inside a
# transaction and outside one. Core asks ->can('_exec_svp_begin') whether a
# storage has savepoints and refuses by itself when it has none, so this
# storage must not define the three _exec_svp_* methods. It used to, and
# auto_savepoint => 1 then sent the engine statements it cannot parse.
#
# What is observed is the SQL that reaches the handle (DBI Callbacks on do and
# prepare), not the wording of an error: a refusal is only a refusal if nothing
# was sent.
#
# Offline: in-memory DuckDB only, no DSN, no server, no DBIO_TEST_* anything.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use DBI;

use DBIO::DuckDB::Test;

my $REFUSAL = qr/doesn't support savepoints/;

# The premise. If a libduckdb ever parses these, this block goes red and the
# decision to ship no _exec_svp_* is due for a second look -- with a version
# to measure a gate against, which is what was missing when they were removed.
{
  my $raw = DBI->connect('dbi:DuckDB:dbname=:memory:', '', '',
    { RaiseError => 1, PrintError => 0, AutoCommit => 1 });

  $raw->do('BEGIN TRANSACTION');
  for my $sql (
    'SAVEPOINT savepoint_0',
    'ROLLBACK TO SAVEPOINT savepoint_0',
    'RELEASE SAVEPOINT savepoint_0',
  ) {
    throws_ok { $raw->do($sql) } qr/Parser Error/,
      "the engine does not parse: $sql";
  }
  $raw->do('ROLLBACK');
  $raw->disconnect;
}

my @sent;
my $record = sub { push @sent, $_[1]; return };

my $schema = DBIO::DuckDB::Test->init_schema(
  no_deploy      => 1,
  auto_savepoint => 1,
  Callbacks      => { do => $record, prepare => $record },
);
my $storage = $schema->storage;

$storage->dbh->do('CREATE TABLE nested (label VARCHAR)');

sub sent_matching { my $re = shift; [ grep { $_ =~ $re } @sent ] }
sub savepoint_sql { sent_matching(qr/SAVEPOINT/i) }

sub labels {
  my $prefix = shift;
  return $storage->dbh->selectcol_arrayref(
    'SELECT label FROM nested WHERE label LIKE ? ORDER BY label', {}, "$prefix%");
}

sub add { $storage->dbh->do("INSERT INTO nested VALUES ('$_[0]')") }

ok $storage->auto_savepoint,
  'auto_savepoint is on -- without it nothing below would ask for a savepoint';

ok !$storage->can($_), "the storage does not define $_ -- the probe core decides by"
  for qw(_exec_svp_begin _exec_svp_release _exec_svp_rollback);

# The three savepoint methods, called directly inside a transaction.
{
  @sent = ();
  $storage->txn_begin;
  add('direct-before');

  throws_ok { $storage->$_ } $REFUSAL,
    "$_ in a transaction gets core's refusal, not an engine error"
    for qw(svp_begin svp_release svp_rollback);

  is_deeply savepoint_sql(), [],
    '... and no savepoint statement reached the engine';
  ok scalar @{ sent_matching(qr/direct-before/) },
    '... (the recorder does see what this transaction sends)';
  is_deeply [ @{ $storage->savepoints || [] } ], [],
    q{... and core's savepoint stack did not grow};
  is $storage->transaction_depth, 1, '... and the transaction is still open';

  lives_ok { add('direct-after'); $storage->txn_commit }
    '... and takes another statement and commits';
  is $storage->transaction_depth, 0, 'transaction_depth is back to 0';
  is_deeply labels('direct'), [qw(direct-after direct-before)],
    'the work on both sides of the refusal is committed';
}

# A nested txn_do under auto_savepoint: txn_begin asks for a savepoint.
{
  @sent = ();
  my $inner_ran = 0;

  throws_ok {
    $storage->txn_do(sub {
      add('uncaught-outer');
      $storage->txn_do(sub { $inner_ran++; add('uncaught-inner') });
    });
  } $REFUSAL, 'a nested txn_do under auto_savepoint is refused by core';

  is $inner_ran, 0, '... before the inner block runs';
  is_deeply savepoint_sql(), [],
    '... and no SAVEPOINT / RELEASE / ROLLBACK TO reached the engine';
  ok scalar @{ sent_matching(qr/uncaught-outer/) },
    '... (the recorder does see what this transaction sends)';
  is $storage->transaction_depth, 0, '... and transaction_depth is back to 0';
  is_deeply [ @{ $storage->savepoints || [] } ], [],
    q{... and core's savepoint stack is empty};
  is_deeply labels('uncaught'), [],
    '... and the outer block, which died of the refusal, is rolled back';

  lives_ok { $storage->txn_do(sub { add('uncaught-next') }) }
    'the connection survives -- the next txn_do runs';
  is_deeply labels('uncaught'), ['uncaught-next'], '... and its commit is visible';
}

# The same refusal, caught by the outer block: the outer transaction is intact.
{
  @sent = ();
  my ($refusal, $depth_after);

  lives_ok {
    $storage->txn_do(sub {
      add('caught-before');
      eval { $storage->txn_do(sub { add('caught-inner') }); 1 } or $refusal = $@;
      $depth_after = $storage->transaction_depth;
      add('caught-after');
    });
  } 'an outer txn_do that catches the refusal carries on and commits';

  like $refusal, $REFUSAL, '... what it caught is the refusal';
  is $depth_after, 1, '... transaction_depth stayed at the outer level';
  is_deeply savepoint_sql(), [], '... no savepoint statement reached the engine';
  is $storage->transaction_depth, 0, '... and transaction_depth is back to 0';
  is_deeply labels('caught'), [qw(caught-after caught-before)],
    '... with the work on both sides of the refusal committed';
}

# A nested txn_scope_guard takes the same txn_begin path.
{
  @sent = ();
  my $depth_after;

  {
    my $outer = $storage->txn_scope_guard;
    add('guard-before');

    throws_ok { $storage->txn_scope_guard } $REFUSAL,
      'a nested txn_scope_guard under auto_savepoint is refused by core';
    $depth_after = $storage->transaction_depth;

    add('guard-after');
    $outer->commit;
  }

  is $depth_after, 1, '... transaction_depth stayed at the outer level';
  is_deeply savepoint_sql(), [], '... no savepoint statement reached the engine';
  ok scalar @{ sent_matching(qr/guard-before/) },
    '... (the recorder does see what this transaction sends)';
  is $storage->transaction_depth, 0, '... and transaction_depth is back to 0';
  is_deeply labels('guard'), [qw(guard-after guard-before)],
    '... and the outer guard commits the work on both sides of the refusal';
}

# What nesting looks like on this driver: auto_savepoint off, one transaction.
{
  $storage->auto_savepoint(0);
  @sent = ();

  lives_ok {
    $storage->txn_do(sub {
      add('flat-outer');
      $storage->txn_do(sub { add('flat-inner') });
    });
  } 'without auto_savepoint a nested txn_do joins the outer transaction';

  is_deeply savepoint_sql(), [], '... no savepoint statement';
  is_deeply labels('flat'), [qw(flat-inner flat-outer)], '... both committed';
}

$storage->disconnect;

done_testing;
