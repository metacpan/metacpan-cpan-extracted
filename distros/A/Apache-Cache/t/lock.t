BEGIN
{
    use strict;
    use Test;
    plan tests => 8;
}

use Apache::Cache qw(:status);
ok(1);

my $cache1 = new Apache::Cache (cachename=>'TEST');
my $cache2 = new Apache::Cache (cachename=>'TEST');

$cache1->lock;
ok($cache1->status, SUCCESS);

# try to access a locked data
$cache2->set('foo', 'bar');
ok($cache2->status, FAILURE);

# DESTROY should unlock cache1
undef $cache1;

# so data is no longer locked
$cache2->set('foo', 'bar');
ok($cache2->status, SUCCESS);

$cache1 = new Apache::Cache (cachename=>'TEST', default_lock_timeout=>5);

$cache2->lock;
ok($cache2->status, SUCCESS);

my $now = time();
# trying to change the locked data, this will failed, but after 5 seconds
# we want to verify this
$cache1->set('foo', 'bar');
my $now2 = time();
ok($cache1->status, FAILURE);
ok($now2 - $now >= 5);

undef $cache2;
$cache1->clear;
ok($cache1->status, SUCCESS);
