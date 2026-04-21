use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::DBIW;
use DBIx::Wizard;

setup_test_db();

# dbiw('db') returns a DB wrapper
{
  my $db = dbiw('testdb');
  isa_ok $db, 'DBIx::Wizard::DB::Wrapper', 'dbiw without table returns wrapper';
  ok $db->can('transaction'), 'wrapper has transaction method';
  ok $db->can('dbh'), 'wrapper has dbh method';
}

# successful transaction commits
{
  dbiw('testdb')->transaction(sub {
    dbiw('testdb:users')->insert({ name => 'Alice', email => 'alice@test.com', status => 'active' });
    dbiw('testdb:users')->insert({ name => 'Bob', email => 'bob@test.com', status => 'active' });
  });

  my $count = dbiw('testdb:users')->inflate(0)->count;
  is $count, 2, 'transaction committed both rows';
}

# failed transaction rolls back
{
  eval {
    dbiw('testdb')->transaction(sub {
      dbiw('testdb:users')->insert({ name => 'Charlie', email => 'charlie@test.com', status => 'active' });
      die "something went wrong";
    });
  };
  like $@, qr/something went wrong/, 'die propagated';

  my $count = dbiw('testdb:users')->inflate(0)->count;
  is $count, 2, 'rollback: still 2 rows';
}

# nested transaction with savepoint — inner failure
{
  eval {
    dbiw('testdb')->transaction(sub {
      dbiw('testdb:users')->insert({ name => 'Dave', email => 'dave@test.com', status => 'active' });

      eval {
        dbiw('testdb')->transaction(sub {
          dbiw('testdb:users')->insert({ name => 'Eve', email => 'eve@test.com', status => 'active' });
          die "inner failure";
        });
      };
      # inner rolled back, outer continues
    });
  };

  my $count = dbiw('testdb:users')->inflate(0)->count;
  is $count, 3, 'nested: outer committed Dave, inner rolled back Eve';
}

# nested transaction — both succeed
{
  dbiw('testdb')->transaction(sub {
    dbiw('testdb:users')->insert({ name => 'Frank', email => 'frank@test.com', status => 'active' });

    dbiw('testdb')->transaction(sub {
      dbiw('testdb:users')->insert({ name => 'Grace', email => 'grace@test.com', status => 'active' });
    });
  });

  my $count = dbiw('testdb:users')->inflate(0)->count;
  is $count, 5, 'nested: both committed';
}

# transaction requires code ref
{
  eval { dbiw('testdb')->transaction("not a code ref") };
  like $@, qr/transaction requires a code reference/, 'rejects non-coderef';
}

cleanup_test_db();
done_testing;
