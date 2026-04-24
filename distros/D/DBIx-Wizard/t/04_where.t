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

# basic where
{
  my @rows = dbiw('testdb:users')->inflate(0)->where({ status => 'active' })->all;
  is scalar(@rows), 2, 'where filters';
}

# where merges hash conditions
{
  my @rows = dbiw('testdb:users')->inflate(0)->where({ status => 'active' })->where({ name => 'Alice' })->all;
  is scalar(@rows), 1, 'where merges conditions';
  is $rows[0]->{name}, 'Alice', 'where merged correctly';
}

# where with operator
{
  my @rows = dbiw('testdb:users')->inflate(0)->where({ name => { '!=' => 'Alice' } })->order_by('name')->all('name');
  is_deeply \@rows, ['Bob', 'Charlie'], 'where with operator';
}

# where with IS NULL / IS NOT NULL
{
  my @rows = dbiw('testdb:users')->inflate(0)->where({ email => { '!=' => undef } })->all;
  is scalar(@rows), 3, 'where IS NOT NULL';
}

cleanup_test_db();
done_testing;
