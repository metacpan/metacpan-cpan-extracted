use Test::More;
use strict;
use warnings;
use Test::RedisServer;

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

{
    package Hoge;
    use strict;
    use warnings;
    use parent 'Amon2';
    sub load_config { +{ Redis => { $redis_server->connect_info }} }
    __PACKAGE__->load_plugin('Redis');
}

{
    my $c = Hoge->bootstrap();
    isa_ok $c, 'Hoge';
    ok $c->redis;
}



done_testing();
