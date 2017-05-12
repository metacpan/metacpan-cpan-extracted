use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;
use Test::MockObject;

my $mock;
BEGIN { require 't/testlib.pl'; $mock = mock_memcached(); }

use Apache::Session::libmemcached;

my $session;
dies_ok(
    sub {
        tie %{$session}, 'Apache::Session::libmemcached', undef, {
            expiration => '300',
        }
    },
    'expected to die for missing servers'
);

dies_ok(
    sub {
        tie %{$session}, 'Apache::Session::libmemcached', undef, {
            servers => ['1.2.3.4:1200'],
            expiration => 'asds',
        }
    },
    'expected to die for wrong expiration time'
);

dies_ok(
    sub {
        tie %{$session}, 'Apache::Session::libmemcached', undef, {
            load_balance_servers => ['1.2.3.4:1200'],
            expiration => '300',
        }
    },
    'expected to die for wrong number of pools'
);

# Insert session info
tie %{$session}, 'Apache::Session::libmemcached', undef, {
    servers => ['1.2.3.4:1200'],
    expiration => '300',
};
my $sid = $session->{_session_id};
$session->{foo} = 'bar';
untie %{$session};

# Test we can retrieve session info
tie %{$session}, 'Apache::Session::libmemcached', $sid, {
    servers => ['1.2.3.4:1200'],
    expiration => '300',
};
ok($session->{foo} eq 'bar');

# Update session info
$session->{foo} = 'baz';
untie %{$session};

# Test we can retrieve updated session info
tie %{$session}, 'Apache::Session::libmemcached', $sid, {
    servers => ['1.2.3.4:1200'],
    expiration => '300',
};
ok($session->{foo} eq 'baz');

# Delete session info
delete $session->{foo};
untie %{$session};

# Test session info is deleted
tie %{$session}, 'Apache::Session::libmemcached', $sid, {
    servers => ['1.2.3.4:1200'],
    expiration => '300',
};
ok(!$session->{foo});
untie %{$session};

