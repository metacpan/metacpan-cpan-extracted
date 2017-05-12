use Test::More;
use Test::Mojo;
use lib './lib';

require_ok('AMQP::Subscriber');

my $s = AMQP::Subscriber->new;

isa_ok($s,'AMQP::Subscriber');

# Test overriding the defaults
$s->server('amqp://foo:bar@test:25672/test');
is($s->host, 'test', 'host set');
is($s->port, 25672, 'port set');
is($s->vhost, 'test', 'vhost set');
is($s->username, 'foo', 'user set');
is($s->password, 'bar', 'password set');

# Test the defaults
$s->server();
is($s->host, 'localhost', 'localhost default');
is($s->port, 5672, 'port default');
is($s->vhost, '/', 'vhost default');
is($s->username, 'guest', 'user default');
is($s->password, 'guest', 'password default');


done_testing();
