
use Test::More tests => 8;
BEGIN { use_ok('Config::ApacheFormat'); }

my $config = Config::ApacheFormat->new();
isa_ok($config, 'Config::ApacheFormat');
$config->autoload_support(1);
$config->read("t/basic.conf");

is($config->foo, "bar");
is(($config->biff)[0], "baz");
is(($config->biff)[1], "bop");

my @bopbop = $config->bopbop;
is($bopbop[1], 'hello "world"');
is($bopbop[3], 'to');

is($config->get(), 4);
