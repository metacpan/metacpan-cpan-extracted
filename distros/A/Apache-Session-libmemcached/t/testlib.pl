use strict;
use warnings;

use Test::MockObject;

# Return a mock memcached object
sub mock_memcached {
    my $mock = Test::MockObject->new();
    $mock->fake_module(
        'Memcached::libmemcached',

    );
    $mock->fake_new('Memcached::libmemcached');
    $mock->set_true('memcached_server_add');
    $mock->mock(
        memcached_get => sub { return $_[0]->{$_[1]} }
    );
    $mock->mock(
        memcached_set => sub { $_[0]->{$_[1]} = $_[2] }
    );
    $mock->mock(
        memcached_replace => sub { $_[0]->{$_[1]} = $_[2] }
    );
    $mock->mock(
        memcached_delete => sub { delete $_[0]->{$_[1]} }
    );

    return $mock;
}

1;
