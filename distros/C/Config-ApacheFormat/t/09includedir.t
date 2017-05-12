
use Test::More tests => 7;
BEGIN { use_ok 'Config::ApacheFormat'; }

my $config = Config::ApacheFormat->new();
$config->read("t/includedir.conf");

is(scalar $config->get('flying'), 'High');
is(scalar $config->get('and'), 'we');
is(scalar $config->get('as'), 'a kite');

is(scalar $config->get('inline'), 'out of order');
is(scalar $config->get('reverse'), 'not');
is(scalar $config->get('ford'), 'prefect');


