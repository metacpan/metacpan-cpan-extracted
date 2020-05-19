use Test::More tests => 1;
use Test::Deep;

use Daemonise;
my $d = Daemonise->new(no_daemon => 1);

is  (1, 1, "true");

#plan qw/no_plan/;
#
#{
#    # plugin loading and configuring
#    $d->load_plugin('KyotoTycoon');
#    $d->configure;
#    is(ref $d->tycoon, 'Cache::KyotoTycoon', 'configuring plugin');
#
#    # setting simple key
#    my $ret = $d->cache_set('key', 'scalarvalue');
#    ok($ret, 'storing non ref data');
#
#    # retrieving simple key
#    ($ret, my $exp) = $d->cache_get('key');
#    is($ret, 'scalarvalue', 'retrieving non ref data');
#
#    # cut of last digit of timestamp to "roughly" match the expire
#    my $time = substr(time + $d->cache_default_expire, 0, -1);
#    like($exp, qr/^$time/, 'default expire time was set');
#
#    # setting complex key
#    $ret = $d->cache_set('key', { complex => 'structure' });
#    ok($ret, 'storing complex data');
#
#    # retrieving complex key
#    $ret = $d->cache_get('key');
#    cmp_deeply($ret, { complex => 'structure' }, 'retrieving complex data');
#
#    # deleting key
#    $ret = $d->cache_del('key');
#    ok($ret, 'deleting cache key');
#}
