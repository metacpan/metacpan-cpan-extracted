use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::DBIW;
use DBIx::Wizard;

my $dbh = setup_test_db();

dbiw('testdb:users')->insert({ name => 'Alice', email => 'alice@example.com', status => 'active' });
dbiw('testdb:users')->insert({ name => 'Bob', email => 'bob@example.com', status => 'active' });

$dbh->do("INSERT INTO orders (user_id, amount) VALUES (1, 100.00)");
$dbh->do("INSERT INTO orders (user_id, amount) VALUES (2, 99.50)");
$dbh->do("INSERT INTO orders (user_id, amount) VALUES (2, 50.25)");

# inner join
{
  my @rows = dbiw('testdb:users')
    ->as('u')
    ->join('orders|o' => 'o.user_id = u.id')
    ->inflate(0)
    ->all(['u.name', 'o.amount']);
  is scalar(@rows), 3, 'inner join';
}

# join with where
{
  my @rows = dbiw('testdb:users')
    ->as('u')
    ->join('orders|o' => 'o.user_id = u.id')
    ->where({ 'u.name' => 'Bob' })
    ->inflate(0)
    ->all(['u.name', 'o.amount']);
  is scalar(@rows), 2, 'join with where';
}

# as sets table alias
{
  my $rs = dbiw('testdb:users')->as('u')->inflate(0);
  my ($sql) = $rs->_build_select->to_sql;
  like $sql, qr/FROM users u/, 'as sets table alias';
}

cleanup_test_db();
done_testing;
