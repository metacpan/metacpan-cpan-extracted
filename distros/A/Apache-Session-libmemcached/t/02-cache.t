use strict;
use warnings;

use Test::More tests => 10;
use Test::MockObject;

my $mock;
BEGIN { require 't/testlib.pl'; $mock = mock_memcached(); }

use Apache::Session::libmemcached;


my $session;
# Create 10 sessions with load balance. Write and read operations will
# be balanced between both pools
for my $i (1..10) {
        my ($key, $value) = (int(rand(1000)), int(rand(1000)));
        tie %{$session}, 'Apache::Session::libmemcached', undef, {
            load_balance_pools => [['1.2.3.4:1200'], ['1.2.3.4:1201']],
            expiration => '300',
        };

        # Insert session info
        my $sid = $session->{_session_id};
        $session->{$key} = $value;
        untie %{$session};

        # Test we can retrieve session info
        tie %{$session}, 'Apache::Session::libmemcached', $sid, {
            load_balance_pools => [['1.2.3.4:1200'], ['1.2.3.4:1201']],
            expiration => '300',
        };
        ok($session->{$key} == $value );
        untie %{$session};
}
