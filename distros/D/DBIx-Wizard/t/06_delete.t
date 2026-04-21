use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::DBIW;
use DBIx::Wizard;

setup_test_db();

dbiw('testdb:users')->insert({ name => 'Alice', email => 'alice@example.com', status => 'active' });
dbiw('testdb:users')->insert({ name => 'Bob', email => 'bob@example.com', status => 'active' });
dbiw('testdb:users')->insert({ name => 'Charlie', email => 'charlie@example.com', status => 'inactive' });

# delete with condition
{
  dbiw('testdb:users')->find({ name => 'Charlie' })->delete;
  my $count = dbiw('testdb:users')->inflate(0)->count;
  is $count, 2, 'delete with condition';
}

# truncate
{
  dbiw('testdb:users')->truncate;
  my $count = dbiw('testdb:users')->inflate(0)->count;
  is $count, 0, 'truncate empties table';
}

cleanup_test_db();
done_testing;
