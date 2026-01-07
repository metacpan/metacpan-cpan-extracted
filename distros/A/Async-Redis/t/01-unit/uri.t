# t/01-unit/uri.t
use strict;
use warnings;
use Test2::V0;

use Async::Redis::URI;

subtest 'basic redis URI' => sub {
    my $uri = Async::Redis::URI->parse('redis://localhost');
    is($uri->scheme, 'redis', 'scheme');
    is($uri->host, 'localhost', 'host');
    is($uri->port, 6379, 'default port');
    is($uri->database, 0, 'default database');
    ok(!$uri->password, 'no password');
    ok(!$uri->username, 'no username');
    ok(!$uri->tls, 'no tls');
    ok(!$uri->is_unix, 'not unix socket');
};

subtest 'redis URI with port' => sub {
    my $uri = Async::Redis::URI->parse('redis://localhost:6380');
    is($uri->host, 'localhost', 'host');
    is($uri->port, 6380, 'custom port');
};

subtest 'redis URI with password only' => sub {
    my $uri = Async::Redis::URI->parse('redis://:secret@localhost');
    is($uri->password, 'secret', 'password parsed');
    ok(!$uri->username, 'no username');
    is($uri->host, 'localhost', 'host');
};

subtest 'redis URI with username and password (ACL)' => sub {
    my $uri = Async::Redis::URI->parse('redis://myuser:mypass@localhost');
    is($uri->username, 'myuser', 'username');
    is($uri->password, 'mypass', 'password');
};

subtest 'redis URI with database' => sub {
    my $uri = Async::Redis::URI->parse('redis://localhost/5');
    is($uri->database, 5, 'database from path');
};

subtest 'redis URI with database 0 explicit' => sub {
    my $uri = Async::Redis::URI->parse('redis://localhost/0');
    is($uri->database, 0, 'database 0 explicit');
};

subtest 'full redis URI' => sub {
    my $uri = Async::Redis::URI->parse('redis://admin:secret123@redis.example.com:6380/2');
    is($uri->scheme, 'redis', 'scheme');
    is($uri->host, 'redis.example.com', 'host');
    is($uri->port, 6380, 'port');
    is($uri->username, 'admin', 'username');
    is($uri->password, 'secret123', 'password');
    is($uri->database, 2, 'database');
    ok(!$uri->tls, 'no tls');
};

subtest 'rediss (TLS) URI' => sub {
    my $uri = Async::Redis::URI->parse('rediss://localhost:6380');
    is($uri->scheme, 'rediss', 'scheme');
    ok($uri->tls, 'tls enabled');
    is($uri->port, 6380, 'port');
};

subtest 'rediss with auth' => sub {
    my $uri = Async::Redis::URI->parse('rediss://user:pass@secure.redis.io');
    ok($uri->tls, 'tls enabled');
    is($uri->username, 'user', 'username');
    is($uri->password, 'pass', 'password');
    is($uri->port, 6379, 'default port');
};

subtest 'unix socket URI' => sub {
    my $uri = Async::Redis::URI->parse('redis+unix:///var/run/redis.sock');
    is($uri->scheme, 'redis+unix', 'scheme');
    is($uri->path, '/var/run/redis.sock', 'socket path');
    ok($uri->is_unix, 'is unix socket');
    is($uri->database, 0, 'default database');
};

subtest 'unix socket with password' => sub {
    my $uri = Async::Redis::URI->parse('redis+unix://:secret@/var/run/redis.sock');
    is($uri->path, '/var/run/redis.sock', 'socket path');
    is($uri->password, 'secret', 'password');
    ok($uri->is_unix, 'is unix socket');
};

subtest 'unix socket with database query param' => sub {
    my $uri = Async::Redis::URI->parse('redis+unix:///var/run/redis.sock?db=3');
    is($uri->path, '/var/run/redis.sock', 'socket path');
    is($uri->database, 3, 'database from query');
};

subtest 'unix socket with multiple query params' => sub {
    my $uri = Async::Redis::URI->parse('redis+unix:///run/redis.sock?db=5&timeout=10');
    is($uri->database, 5, 'database');
    # timeout would be handled by caller, not URI parser
};

subtest 'URL-encoded password' => sub {
    my $uri = Async::Redis::URI->parse('redis://:p%40ss%3Aword@localhost');
    is($uri->password, 'p@ss:word', 'password URL-decoded');
};

subtest 'URL-encoded username' => sub {
    my $uri = Async::Redis::URI->parse('redis://user%40domain:pass@localhost');
    is($uri->username, 'user@domain', 'username URL-decoded');
};

subtest 'to_hash for constructor' => sub {
    my $uri = Async::Redis::URI->parse('redis://user:pass@localhost:6380/2');
    my %hash = $uri->to_hash;

    is($hash{host}, 'localhost', 'host');
    is($hash{port}, 6380, 'port');
    is($hash{username}, 'user', 'username');
    is($hash{password}, 'pass', 'password');
    is($hash{database}, 2, 'database');
    ok(!exists $hash{tls}, 'no tls key when false');
};

subtest 'to_hash with TLS' => sub {
    my $uri = Async::Redis::URI->parse('rediss://localhost');
    my %hash = $uri->to_hash;

    is($hash{tls}, 1, 'tls in hash');
};

subtest 'to_hash for unix socket' => sub {
    my $uri = Async::Redis::URI->parse('redis+unix:///var/run/redis.sock?db=1');
    my %hash = $uri->to_hash;

    is($hash{path}, '/var/run/redis.sock', 'path');
    is($hash{database}, 1, 'database');
    ok(!exists $hash{host}, 'no host for unix socket');
    ok(!exists $hash{port}, 'no port for unix socket');
};

subtest 'invalid URI - bad scheme' => sub {
    ok(dies { Async::Redis::URI->parse('http://localhost') },
       'http scheme rejected');
    ok(dies { Async::Redis::URI->parse('mysql://localhost') },
       'mysql scheme rejected');
};

subtest 'invalid URI - malformed' => sub {
    ok(dies { Async::Redis::URI->parse('not a uri at all') },
       'garbage rejected');
    ok(dies { Async::Redis::URI->parse('redis://') },
       'empty host rejected');
};

subtest 'parse returns undef for empty/undef' => sub {
    is(Async::Redis::URI->parse(''), undef, 'empty string');
    is(Async::Redis::URI->parse(undef), undef, 'undef');
};

done_testing;
