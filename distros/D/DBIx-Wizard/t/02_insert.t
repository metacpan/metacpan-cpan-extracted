use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::DBIW;
use DBIx::Wizard;

setup_test_db();

# simple insert returns auto-increment id
{
  my $id1 = dbiw('testdb:users')->insert({ name => 'Alice', email => 'alice@example.com', status => 'active' });
  ok $id1, 'insert returns id';

  my $id2 = dbiw('testdb:users')->insert({ name => 'Bob', email => 'bob@example.com', status => 'active' });
  is $id2, $id1 + 1, 'insert auto-increments';
}

# insert with expression
{
  dbiw('testdb:users')->insert({ name => dbiw->raw("'Charlie'"), email => 'charlie@example.com', status => 'inactive' });
  my $row = dbiw('testdb:users')->inflate(0)->find({ email => 'charlie@example.com' })->one;
  is $row->{name}, 'Charlie', 'insert with expression';
}

cleanup_test_db();
done_testing;
