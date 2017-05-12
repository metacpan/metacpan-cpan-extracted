use strict;
use warnings;
use Test::More;
use Test::Requires {
    'Test::TCP' => '1.18',
    'Cache::Memcached::Fast' => '0.19'
};

require Test::TCP;
require Cache::Memcached::Fast;
my $port = Test::TCP::empty_port();

my $pid = fork();
if ( $pid == 0 ) {
    exec $^X, '-I./lib','./bin/derived', '-i', 1, '-M', "Memcached,port=$port", './t/CmdsFile';
    exit;
}
sleep 3;
my $memcached = Cache::Memcached::Fast->new({
    servers => ["localhost:$port"]
});
ok($memcached->server_versions()->{"localhost:$port"});
ok($memcached->get("w1"));
ok($memcached->get("w2"));
ok($memcached->get("w1:latest"));
ok($memcached->get("w2:latest"));
ok($memcached->get("w1:full"));
ok($memcached->get("w2:full"));

kill 'TERM', $pid;
waitpid( $pid, 0);
done_testing();

