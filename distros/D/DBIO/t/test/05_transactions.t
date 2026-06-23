use strict;
use warnings;

use Test::More;
use DBIO::Test;

my $schema = DBIO::Test->init_schema;

# Transaction tracking
{
  $schema->storage->reset_captured;

  $schema->txn_do(sub {
    $schema->resultset('Artist')->search({ name => 'x' })->all;
  });

  my @q = $schema->storage->captured_queries;
  ok scalar @q >= 3, 'transaction queries captured (begin + select + commit)';

  is $q[0]{op}, 'txn_begin', 'first is BEGIN';
  is $q[0]{sql}, 'BEGIN', 'BEGIN SQL';
  is $q[-1]{op}, 'txn_commit', 'last is COMMIT';
  is $q[-1]{sql}, 'COMMIT', 'COMMIT SQL';
}

# Nested transaction (savepoint)
{
  $schema->storage->auto_savepoint(1);
  $schema->storage->reset_captured;

  $schema->txn_do(sub {
    $schema->txn_do(sub {
      $schema->resultset('Artist')->search({ name => 'y' })->all;
    });
  });

  my @q = $schema->storage->captured_queries;
  my @ops = map { $_->{op} } @q;

  ok( (grep { $_ eq 'svp_begin' } @ops), 'savepoint begin tracked' );
  ok( (grep { $_ eq 'svp_release' } @ops), 'savepoint release tracked' );
}

# Rollback tracking
{
  $schema->storage->reset_captured;

  eval {
    $schema->txn_do(sub {
      die "intentional rollback";
    });
  };

  my @q = $schema->storage->captured_queries;
  my @ops = map { $_->{op} } @q;

  ok( (grep { $_ eq 'txn_begin' } @ops), 'begin tracked before rollback' );
  ok( (grep { $_ eq 'txn_rollback' } @ops), 'rollback tracked' );
}

done_testing;
