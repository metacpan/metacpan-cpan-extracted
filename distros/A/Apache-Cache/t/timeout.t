BEGIN
{
    use strict;
    use Test;
    plan tests => 8;
}

use Apache::Cache qw(:status :expires);
ok(1);

my $cache = new Apache::Cache;
ok(defined $cache);

$cache->set(key=>'data', EXPIRES_NOW);
ok($cache->status, SUCCESS);

$cache->get('key');
ok($cache->status, EXPIRED);

$cache->set(key2=>'data', '5 seconds');
ok($cache->status, SUCCESS);

my $data = $cache->get('key2');
ok($cache->status, SUCCESS);
ok($data, 'data');

sleep 5; # wait for data's expire
$cache->get('key2');
ok($cache->status, EXPIRED);
