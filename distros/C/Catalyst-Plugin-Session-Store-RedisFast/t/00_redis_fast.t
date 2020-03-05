
use strict;
use warnings;
use utf8;

use lib 't/lib';
use lib 'lib';

use Test::More qw/no_plan/;
use Test::Mock::Redis;

use Catalyst::Test 'RedisFastApp';

# Replace Redis to custom
RedisFastApp->_session_redis_storage(Test::Mock::Redis->new());
*RedisFastApp::session_expires = sub {return time() + 3600};

test_get_set_session_data();
test_delete_session_data();
test_get_set_expires_key();
test_increase_ttl_time();

done_testing;

sub test_get_set_session_data {
    my ($key, $value) = ('test_key', 'test_value');
    ok (RedisFastApp->store_session_data($key, $value), "Test store_session_data");
    is (RedisFastApp->get_session_data($key), $value, "Test get_session_data");
}

sub test_delete_session_data {
    my ($key, $value) = ('test_delete_key', 'test_value');
    ok (RedisFastApp->store_session_data($key, $value), "Test store_session_data");
    ok (RedisFastApp->delete_session_data($key, $value), "Test delete_session_data");
}

sub test_get_set_expires_key {
    my ($key, $value) = ('test_expires_key', 'test_value');
    my $ttl = 1000;
    ok (RedisFastApp->store_session_data("expires:$key", time() + $ttl), "Test store_session_data");
    ok (RedisFastApp->store_session_data("session:$key", $value), "Test store_session_data");
    ok (RedisFastApp->get_session_data("expires:$key") > (time() + $ttl - 1), "Test '$key' expires is $ttl");
}

sub test_increase_ttl_time {
    my ($key, $value) = ('test_increase_ttl_key', 'test_value');
    my $ttl = 1000;
    my $new_ttl = 2000;
    ok (RedisFastApp->store_session_data("expires:$key", time() + $ttl), "Test store_session_data");
    ok (RedisFastApp->store_session_data("session:$key", $value), "Test store_session_data");
    ok (RedisFastApp->store_session_data("expires:$key", time() + $new_ttl), "Test store_session_data");
    ok (RedisFastApp->get_session_data("expires:$key") > (time() + $new_ttl - 1), "Test '$key' expires is $new_ttl");
}
