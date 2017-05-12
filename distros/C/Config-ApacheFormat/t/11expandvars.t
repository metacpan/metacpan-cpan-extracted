
use Test::More tests => 13;
BEGIN { use_ok 'Config::ApacheFormat' };

my $config = Config::ApacheFormat->new(expand_vars => 1);
$config->read("t/expandvars.conf");

is($config->get('Onevar'), 'A/B');
is($config->get('twovar'), 'A/A');

is($config->get('website'), 'http://my.own.dom');
is($config->get('JScript'), 'http://my.own.dom/js');
is($config->get('Images'), 'http://my.own.dom/images');
is($config->get('private'), 'http://my.own.dom/prv');

is($config->get('basedir'), '/etc');
is($config->get('fullconfig'), '/etc/apache/httpd.conf');
is($config->get('baseconfig'), '/etc/apache/base.httpd.conf');

is($config->block(subcontext => 'Vartest')->get('kiffy'), '/etc/apache/vhost.conf');

is($config->get('money'), '$12.00');
is($config->get('another'), 'The A $String is http://my.own.dom/prvly ${escaped}');

