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

# cursor returns Cursor object
{
  my $cursor = dbiw('testdb:users')->inflate(0)->sort('name')->cursor;
  isa_ok $cursor, 'DBIx::Wizard::Cursor';
}

# cursor iterates rows
{
  my $cursor = dbiw('testdb:users')->inflate(0)->sort('name')->cursor;
  my @names;
  while (my $row = $cursor->next) {
    push @names, $row->{name};
  }
  is_deeply \@names, ['Alice', 'Bob', 'Charlie'], 'cursor iterates all rows';
}

# cursor with columns
{
  my $cursor = dbiw('testdb:users')->inflate(0)->sort('name')->cursor(['name']);
  my $row = $cursor->next;
  ok exists $row->{name}, 'cursor with columns';
}

# cursor returns undef at end
{
  my $cursor = dbiw('testdb:users')->inflate(0)->limit(1)->cursor;
  my $row1 = $cursor->next;
  ok $row1, 'first row exists';
  my $row2 = $cursor->next;
  ok !$row2, 'no more rows';
}

cleanup_test_db();
done_testing;
