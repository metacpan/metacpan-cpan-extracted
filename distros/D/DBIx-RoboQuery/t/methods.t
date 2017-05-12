# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;

my $qmod = 'DBIx::RoboQuery';
eval "require $qmod" or die $@;

my $sql = 'SELECT * FROM table';
my $order = 'ORDER BY field';
my $query;

# key_columns
$query = $qmod->new(sql => "$sql $order",);
is_deeply([$query->key_columns], [], 'key columns not provided to constructor');

$query = $qmod->new(sql => "$sql $order", key_columns => 'hello');
is_deeply([$query->key_columns], [qw(hello)], 'key columns set from constructor');

$query = $qmod->new(sql => "$sql $order", key_columns => ['hello']);
is_deeply([$query->key_columns], [qw(hello)], 'key columns set from constructor');

$query->key_columns;
is_deeply([$query->key_columns], [qw(hello)], 'key columns not changed');

$query->key_columns('there');
is_deeply([$query->key_columns], [qw(there)], 'key columns set');

$query->key_columns('hello', 'there');
is_deeply([$query->key_columns], [qw(hello there)], 'key columns set with list');

$query->key_columns(['hello', 'there']);
is_deeply([$query->key_columns], [qw(hello there)], 'key columns set with arrayref');

$query->key_columns(['hello', 'there'], 'you');
is_deeply([$query->key_columns], [qw(hello there you)], 'key columns set with mixture');

$query->key_columns('hello', ['there'], 'you');
is_deeply([$query->key_columns], [qw(hello there you)], 'key columns set with mixture');

# drop_columns
$query = $qmod->new(sql => $sql);
is_deeply([$query->drop_columns], [], 'drop columns not provided to constructor');

$query = $qmod->new(sql => $sql, drop_columns => 'arr');
is_deeply([$query->drop_columns], ['arr'], 'drop columns passed to constructor');

$query->drop_columns('hello', ['there'], 'you');
is_deeply([$query->drop_columns], [qw(hello there you)], 'drop columns set with mixture');

# order
$query = $qmod->new(sql => $sql);
ok(!exists $query->{order}, 'order does not exist yet');
is_deeply([$query->order], [], 'no order found in SQL');

$query = $qmod->new(sql => "$sql $order");
ok(!exists $query->{order}, 'order does not exist yet');
is_deeply([$query->order], [qw(field)], 'order set from SQL');

$query->order;
is_deeply([$query->order], [qw(field)], 'order unchanged');

$query->order('fld1');
is_deeply([$query->order], [qw(fld1)], 'order set');

$query->order('fld1', ['fld2']);
is_deeply([$query->order], [qw(fld1 fld2)], 'order set with mixture');

$query = $qmod->new(sql => $sql, order => []);
is_deeply([$query->order], [], 'order set from constructor');

$query = $qmod->new(sql => $sql, order => 'hi');
is_deeply([$query->order], ['hi'], 'order set from constructor');

done_testing;
