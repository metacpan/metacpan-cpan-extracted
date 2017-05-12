
use Test::More tests => 9;

BEGIN { use_ok('Config::ApacheFormat'); }

my $config = Config::ApacheFormat->new();
isa_ok($config, 'Config::ApacheFormat');

$config->read("t/basic.conf");
is($config->get('foo'), "bar");
is(($config->get('biff'))[0], "baz");
is(($config->get('biff'))[1], "bop");
is($config->get('bool'), 1);

my @bopbop = $config->get('bopbop');
is($bopbop[1], 'hello "world"');
is($bopbop[3], 'to');

is($config->get(), 4);
