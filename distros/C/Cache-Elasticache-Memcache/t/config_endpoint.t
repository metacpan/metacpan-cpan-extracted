use Moo;
use Test::More;
use Test::Exception;
use Test::Routini;
use Sub::Override;
use Carp;
use Test::MockObject;
use Test::Deep;
use Symbol;

use Cache::Elasticache::Memcache;

has test_class => (
    is => 'ro',
    lazy => 1,
    default => 'Cache::Elasticache::Memcache'
);

has endpoint_location => (
    is => 'ro',
    lazy => 1,
    default => 'test.lwgyhw.cfg.usw2.cache.amazonaws.com:11211',
);

has last_parent_object => (
    is => 'rw',
    default => undef
);

has last_parent_args => (
    is => 'rw',
    default => undef,
);

has config_lines => (
    is => 'rw',
    lazy => 1,
    clearer => '_clear_config_lines',
    default => sub {
        my $text = "CONFIG cluster 0 141\r\n12\nmycluster.0001.cache.amazonaws.com|10.112.21.1|11211 mycluster.0002.cache.amazonaws.com|10.112.21.2|11211 mycluster.0003.cache.amazonaws.com|10.112.21.3|11211\n\r\nEND\r\nmycluster.0001.cache.amazonaws.com|10.112.21.4|11211\n\r\n";
        return [unpack("(A16)*", $text)];
    }
);

has mock_sockets => (
    is => 'ro',
    lazy => 1,
    clearer => '_clear_mock_sockets',
    default => sub {
        my $self = shift;
        return {
            'good' => $self->build_mock_socket($self->config_lines, gensym),
            'bad_send' => $self->build_mock_socket($self->config_lines,gensym, 'send' => sub { die; }),
        };
    }
);

has parent_overrides => (
    is => 'ro',
    lazy => 1,
    clearer => '_clear_parent_overrides',
    default => sub {
        my $self = shift;
        my $overrides = Sub::Override->new()
                                     ->replace('IO::Socket::IP::new',
            sub{
                my $object = shift;
                my @args = @_;
                return $self->mock_sockets->{'good'} if ({@args}->{'PeerAddr'} eq $self->endpoint_location);
                return $self->mock_sockets->{'bad_send'} if ({@args}->{'PeerAddr'} eq 'bad_send:11211');
                croak "GAAAAAAAA";
            })
                                     ->replace('Cache::Memcached::Fast::new' ,
            sub {
                my $object = shift;
                my @args = @_;


                $self->last_parent_object($object);
                $self->last_parent_args(\@args);

                return Test::MockObject->new();
            })
                                     ->replace('Cache::Memcached::Fast::DESTROY' , sub { });
        return $overrides;
    }
);

before run_test => sub {
    my $self = shift;
    $self->_clear_config_lines;
    $self->reset_overrides;
};

sub reset_overrides {
    my $self = shift;
    $self->_clear_mock_sockets;
    $self->_clear_parent_overrides();
    $self->parent_overrides;
}

sub build_mock_socket {
    my $self = shift;
    my $config_lines = shift;
    my $glob = shift;
    my %args = @_;

    my $mock = Test::MockObject->new($glob);
    $mock->set_isa('IO::Socket');
    foreach my $method (qw(autoflush sockopt send close connected setsockopt write_Timeout)) {
        $mock->mock($method, (exists $args{$method}) ? $args{$method} : $self->default_mock_method($method));
    }
    my @lines = @{$config_lines};
    $mock->mock('getline', sub { return shift @lines });

   return $mock;
}

sub default_mock_method {
    my $self = shift;
    my $method_name = shift;
    return sub { return 1 };
}

test "get_servers_from_endpoint" => sub {
    my $self = shift;
    my $result = $self->test_class->getServersFromEndpoint($self->endpoint_location);
    cmp_deeply( $result, ['10.112.21.1:11211','10.112.21.2:11211', '10.112.21.3:11211'] );
};

test "get_servers_from_endpoint_split_END" => sub {
    my $self = shift;
    $self->config_lines(["\nmycluster.0001.cache.amazonaws.com|10.112.21.4|11211\n\r\n","E","ND\r\n"]);
    $self->reset_overrides;
    my $result = $self->test_class->getServersFromEndpoint($self->endpoint_location);
    cmp_deeply( $result, ['10.112.21.4:11211'] );
};

test "get_servers_from_endpoint_timeout" => sub {
    my $self = shift;
    $self->config_lines(["\nmycluster.0001.cache.amazonaws.com|10.112.21.4|11211\n\r\n"]);
    $self->reset_overrides;
    my $result = $self->test_class->getServersFromEndpoint($self->endpoint_location);
    cmp_deeply( $result, ['10.112.21.4:11211'] );
};

test "update_servers_no_change" => sub {
    my $self = shift;

    my $memd = $self->test_class->new(config_endpoint => $self->endpoint_location);
    my $original_update = $memd->{_last_update};
    my $original_servers = $memd->{servers};
    my $original_memd_obj = $memd->{_memd};
    sleep 1;

    $self->reset_overrides;
    delete $memd->{_sockets}->{$self->endpoint_location};
    $memd->updateServers;

    ok $original_update < $memd->{_last_update};
    cmp_deeply($original_servers, $memd->{servers});
    cmp_ok($original_memd_obj, '==', $memd->{_memd});
};

test "update_servers" => sub {
    my $self = shift;

    my $memd = $self->test_class->new(config_endpoint => $self->endpoint_location);
    my $original_update = $memd->{_last_update};
    my $original_servers = $memd->{servers};
    my $original_memd_obj = $memd->{_memd};
    sleep 1;

    $memd->{servers} = [ '10.112.21.1:11211' ];
    ok !eq_deeply($original_servers, $memd->{servers});

    $self->reset_overrides;
    delete $memd->{_sockets}->{$self->endpoint_location};
    $memd->updateServers;

    ok $original_update < $memd->{_last_update};
    cmp_deeply($original_servers, $memd->{servers});
    cmp_ok($original_memd_obj, '!=', $memd->{_memd});
};

test "check_servers_within_update_period" => sub {
    my $self = shift;

    my $memd = $self->test_class->new(
        config_endpoint => $self->endpoint_location,
        update_period => 9999999,
    );

    my $original_update = $memd->{_last_update};
    my $original_servers = $memd->{servers};
    my $original_memd_obj = $memd->{_memd};
    sleep 2;

    $self->reset_overrides;
    delete $memd->{_sockets}->{$self->endpoint_location};
    $memd->updateServers;

    ok $original_update < $memd->{_last_update};
    cmp_deeply($original_servers, $memd->{servers});
    cmp_ok($original_memd_obj, '==', $memd->{_memd});
};

test "check_servers_outside_update_period" => sub {
    my $self = shift;

    my $memd = $self->test_class->new(
        config_endpoint => $self->endpoint_location,
        update_period => 1,
    );

    my $original_update = $memd->{_last_update};
    my $original_servers = $memd->{servers};
    my $original_memd_obj = $memd->{_memd};
    sleep 2;

    $memd->{servers} = [ '10.112.21.1:11211' ];
    ok !eq_deeply($original_servers, $memd->{servers});

    $self->reset_overrides;
    delete $memd->{_sockets}->{$self->endpoint_location};
    $memd->updateServers;

    ok $original_update < $memd->{_last_update};
    cmp_deeply($original_servers, $memd->{servers});
    cmp_ok($original_memd_obj, '!=', $memd->{_memd});
};

test "retry up to 3 times due to faiure" => sub {
    my $self = shift;

    my $result = $self->test_class->getServersFromEndpoint('bad_send:11211');
    is scalar @{$result}, 0;
    my $send_count = 0;
    my $autoflush_count = 0;
    for my $called (reverse @{ $self->mock_sockets->{'bad_send'}->_calls() })
    {
        $send_count++ if $called->[0] eq 'send';
        $autoflush_count++ if $called->[0] eq 'autoflush';
    }
    is $send_count, 3;
    is $autoflush_count, 3;
};

test "Socket is reused if possible" => sub {
    my $self = shift;

    my $memd = $self->test_class->new(
        config_endpoint => $self->endpoint_location,
        update_period => 1,
    );

    $self->mock_sockets->{'good'}->clear;

    $memd->getServersFromEndpoint($self->endpoint_location);
    ok !$self->mock_sockets->{'good'}->called('autoflush');
};

run_me;
done_testing;
1;
