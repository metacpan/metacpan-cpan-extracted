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

# basic find
{
  my @rows = dbiw('testdb:users')->inflate(0)->find({ status => 'active' })->all;
  is scalar(@rows), 2, 'find filters';
}

# find merges hash conditions
{
  my @rows = dbiw('testdb:users')->inflate(0)->find({ status => 'active' })->find({ name => 'Alice' })->all;
  is scalar(@rows), 1, 'find merges conditions';
  is $rows[0]->{name}, 'Alice', 'find merged correctly';
}

# find with operator
{
  my @rows = dbiw('testdb:users')->inflate(0)->find({ name => { '!=' => 'Alice' } })->sort('name')->all('name');
  is_deeply \@rows, ['Bob', 'Charlie'], 'find with operator';
}

# find with IS NULL / IS NOT NULL
{
  my @rows = dbiw('testdb:users')->inflate(0)->find({ email => { '!=' => undef } })->all;
  is scalar(@rows), 3, 'find IS NOT NULL';
}

cleanup_test_db();
done_testing;
