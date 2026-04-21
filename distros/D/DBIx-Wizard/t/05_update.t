use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::DBIW;
use DBIx::Wizard;

setup_test_db();

dbiw('testdb:users')->insert({ name => 'Alice', email => 'alice@example.com', status => 'active' });
dbiw('testdb:users')->insert({ name => 'Bob', email => 'bob@example.com', status => 'inactive' });

# simple update
{
  my $rows = dbiw('testdb:users')->find({ name => 'Bob' })->update({ status => 'active' });
  is $rows, 1, 'update returns affected rows';

  my $status = dbiw('testdb:users')->inflate(0)->find({ name => 'Bob' })->one('status');
  is $status, 'active', 'update worked';
}

# update with expression
{
  dbiw('testdb:users')->find({ name => 'Alice' })->update({ name => dbiw->raw("name || ?", ' Smith') });
  my $name = dbiw('testdb:users')->inflate(0)->find({ email => 'alice@example.com' })->one('name');
  is $name, 'Alice Smith', 'update with expression';
}

# update multiple rows
{
  my $rows = dbiw('testdb:users')->find({ status => 'active' })->update({ status => 'pending' });
  is $rows, 2, 'update multiple rows';
}

cleanup_test_db();
done_testing;
