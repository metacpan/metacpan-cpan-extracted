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

# all
{
  my @rows = dbiw('testdb:users')->inflate(0)->all;
  is scalar(@rows), 3, 'all returns 3 rows';
  is ref($rows[0]), 'HASH', 'rows are hashrefs';
}

# all with column list
{
  my @rows = dbiw('testdb:users')->inflate(0)->all(['name', 'status']);
  is scalar(@rows), 3, 'all with columns';
  ok exists $rows[0]->{name}, 'has name column';
}

# all with single column returns flat list
{
  my @names = dbiw('testdb:users')->inflate(0)->sort('name')->all('name');
  is_deeply \@names, ['Alice', 'Bob', 'Charlie'], 'all(scalar) returns flat list';
}

# one returns single hashref
{
  my $row = dbiw('testdb:users')->inflate(0)->find({ name => 'Alice' })->one;
  is $row->{name}, 'Alice', 'one returns hashref';
  is $row->{email}, 'alice@example.com', 'one has all columns';
}

# one with single column returns scalar
{
  my $email = dbiw('testdb:users')->inflate(0)->find({ name => 'Alice' })->one('email');
  is $email, 'alice@example.com', 'one(scalar) returns value';
}

# count
{
  my $count = dbiw('testdb:users')->inflate(0)->count;
  is $count, 3, 'count all';
}
{
  my $count = dbiw('testdb:users')->inflate(0)->find({ status => 'active' })->count;
  is $count, 2, 'count with find';
}

# sort
{
  my @names = dbiw('testdb:users')->inflate(0)->sort('-name')->all('name');
  is_deeply \@names, ['Charlie', 'Bob', 'Alice'], 'sort DESC';
}
{
  my @names = dbiw('testdb:users')->inflate(0)->sort('name')->all('name');
  is_deeply \@names, ['Alice', 'Bob', 'Charlie'], 'sort ASC';
}

# limit
{
  my @names = dbiw('testdb:users')->inflate(0)->sort('name')->limit(2)->all('name');
  is_deeply \@names, ['Alice', 'Bob'], 'limit';
}

# offset
{
  my @names = dbiw('testdb:users')->inflate(0)->sort('name')->limit(1)->offset(1)->all('name');
  is_deeply \@names, ['Bob'], 'offset';
}

# terminal methods don't mutate ResultSet
{
  my $rs = dbiw('testdb:users')->inflate(0)->find({ status => 'active' });
  my $count = $rs->count;
  is $count, 2, 'count before all';
  my @rows = $rs->all;
  is scalar(@rows), 2, 'all after count still works';
  ok exists $rows[0]->{name}, 'all after count has columns';
}

# one doesn't mutate limit
{
  my $rs = dbiw('testdb:users')->inflate(0)->sort('name');
  my $first = $rs->one('name');
  is $first, 'Alice', 'one returns first';
  my @all = $rs->all('name');
  is scalar(@all), 3, 'all after one returns all rows';
}

# exists
{
  ok dbiw('testdb:users')->inflate(0)->find({ name => 'Alice' })->exists, 'exists returns true';
  ok !dbiw('testdb:users')->inflate(0)->find({ name => 'Nobody' })->exists, 'exists returns false';
}

# distinct with scalar returns flat list of unique values
{
  my @s = dbiw('testdb:users')->inflate(0)->sort('status')->distinct('status');
  is_deeply \@s, ['active', 'inactive'], 'distinct(scalar) returns flat list';
}

# distinct with arrayref returns hashrefs
{
  my @rows = dbiw('testdb:users')->inflate(0)->sort('status')->distinct(['status']);
  is scalar(@rows), 2, 'distinct(arrayref) returns 2 rows';
  is $rows[0]->{status}, 'active', 'first status';
  is $rows[1]->{status}, 'inactive', 'second status';
}

# distinct requires a column argument
{
  eval { dbiw('testdb:users')->distinct };
  like $@, qr/distinct\(\) requires/, 'distinct without columns croaks';
}

cleanup_test_db();
done_testing;
