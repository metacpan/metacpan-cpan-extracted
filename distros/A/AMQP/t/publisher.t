use Test::More tests => 2;
use Test::Mojo;
use lib './lib';

require_ok('AMQP::Publisher');

my $p = AMQP::Publisher->new;

isa_ok($p,'AMQP::Publisher');
