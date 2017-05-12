use Test::More tests => 9;
use strict; use warnings;

use_ok( 'Bot::Cobalt::Plugin::RDB::SearchCache' );

my $cache = new_ok( 'Bot::Cobalt::Plugin::RDB::SearchCache' );

ok( $cache->cache('Cache', 'my_key', [qw/ a b c /] ), 'Store key' );

is_deeply( scalar $cache->fetch('Cache', 'my_key'), [qw/ a b c /] );

my @arr = $cache->fetch('Cache', 'my_key');

cmp_ok(@arr, '==', 3);

ok( $cache->invalidate('Cache'), 'invalidate()');

cmp_ok( $cache->MaxKeys('5'), '==', 5, 'MaxKeys(5)' );

my $i;
diag "This test will sleep for 6 seconds." if $^O eq 'MSWin32';
for (0 .. 6) {
  ++$i;
  
  if ($^O eq 'MSWin32') {
    sleep 1;
  } else {
    select undef, undef, undef, 0.1;
  }
  
  $cache->cache('Cache', 'key'.$i, [ 'value'.$i ] );
}

diag( $cache->fetch('Cache', 'key1'));
ok( !$cache->fetch('Cache', 'key1'), 'cache shrink' );
ok( $cache->fetch('Cache', 'key2'), 'cache fetch after shrink' );
