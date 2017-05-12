use Moo;
use Test::More;
use Test::Exception;
use Test::Routini;
use Sub::Override;
use Carp;
use Test::MockObject;
use Symbol;

use Cache::Elasticache::Memcache;

has test_class => (
    is => 'ro',
    lazy => 1,
    default => 'Cache::Elasticache::Memcache'
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

has parent_overrides => (
    is => 'ro',
    default => sub {
        my $self = shift;
        my $mock = Test::MockObject->new(gensym);
        $mock->set_isa('IO::Socket');
        $mock->mock('autoflush', sub { return 1 });
        $mock->mock('sockopt', sub { return 1 });
        $mock->mock('setsockopt', sub { return 1 });
        $mock->mock('write_Timeout', sub { return 1 });
        $mock->mock('send', sub { return 1 });
        my @lines = @{$self->config_lines};
        $mock->mock('getline', sub { return shift @lines });
        $mock->mock('close', sub { return 1 });
        my $overrides = Sub::Override->new()
                                     ->replace('Cache::Memcached::Fast::new' , sub { my $object = shift; my @args = @_; $self->last_parent_object($object); $self->last_parent_args(\@args) })
                                     ->replace('Cache::Memcached::Fast::DESTROY' , sub { })
                                     ->replace('IO::Socket::IP::new', sub{ my $object = shift; my @args = @_; croak "config_endpoint:-".{@args}->{'PeerAddr'} unless {@args}->{'PeerAddr'} eq 'good:11211'; return $mock });
        return $overrides;
    }
);

has last_parent_object => (
    is => 'rw',
    default => undef
);

has last_parent_args => (
    is => 'rw',
    default => undef,
);

test "hello world" => sub {
    my $self = shift;
    ok defined $self->test_class->VERSION;
};

test "instantiation" => sub {
    my $self = shift;
    isa_ok $self->test_class->new(config_endpoint => 'good:11211'), $self->test_class;
};

test "update_period defaults to 180 seconds" => sub {
    my $self = shift;
    my $object = $self->test_class->new( config_endpoint => 'good:11211' );
    is $object->{update_period}, 180;
};

test "requires config_endpoint" => sub {
    my $self = shift;
    dies_ok { $self->test_class->new( ) };
    like $@, '/^config_endpoint must be speccified/';
};

test "constructor does not accept servers argument" => sub {
    my $self = shift;
    dies_ok { $self->test_class->new(
        config_endpoint => 'good:11211', servers => ['good:11211']
    ) };
    like $@, '/^servers is not a valid constructors parameter/';
};

run_me;
done_testing;
1;
