use Test::More tests => 24;
use Cache::Memcached::Mock;

my $c = Cache::Memcached::Mock->new();
my $k = 'counter1';

is($c->get($k), undef, 'Key doesn\'t initially exist');

is($c->incr($k), undef, 'Can\'t increment unknown key');
is($c->get($k), undef, 'Key isn\'t set');

is($c->decr($k), undef, 'Can\'t decrement unknown key');
is($c->get($k), undef, 'Key isn\'t set');

ok($c->set($k, 0), 'Set key');
ok($c->incr($k));
is($c->get($k) => 1, 'First incr() returns 1');

ok($c->incr($k));
is($c->get($k) => 2, 'Test that incr() really works');

$c->incr($k);
is($c->incr($k) => 4, 'incr() returns the new value of the counter');

$c->decr($k);
is($c->get($k) => 3, 'decr() also works');

$c->incr($k);
$c->incr($k);
is($c->get($k) => 5, 'Test that incr() really works');

is($c->incr($k, 2) => 7, 'incr() returns the new value?');
is($c->get($k) => 7, 'Test that incr() with offset works');

is($c->incr($k, 0) => 7, 'Increment by zero.');
is($c->decr($k, 0) => 7, 'Decrement by zero.');
is($c->get($k) => 7, 'Value is left unchanged.');

my $MASK = 2 ** 32 - 1;

$c->set($k, -5);
is($c->decr($k), (-5 & $MASK) - 1, 'Decrement negative number');

$c->set($k, -5);
is($c->decr($k, 2), (-5 & $MASK) - 2, 'Decrement negative number with positive offset');

$c->set($k, -5);
is($c->decr($k, -2), 0, 'Decrement negative number with negative offset');

$c->set($k, -5);
is($c->incr($k), (-5 & $MASK) + 1, 'Increment negative number');

$c->set($k, -5);
is($c->incr($k, 2), (-5 & $MASK) + 2, 'Increment negative number with positive offset');

$c->set($k, -5);
is($c->incr($k, -2), (-5 & $MASK) - 2, 'Increment negative number with negative offset');
