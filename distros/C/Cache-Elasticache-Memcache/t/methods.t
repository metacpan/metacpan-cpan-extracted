use Moo;
use Test::More;
use Test::Exception;
use Test::Routini;
use Test::MockObject;
use Sub::Override;
use Carp;

use Cache::Elasticache::Memcache;

has test_class => (
    is => 'ro',
    lazy => 1,
    default => 'Cache::Elasticache::Memcache'
);

has mock_base_memd => (
    is => 'ro',
    lazy => 1,
    clearer => '_clear_mock_base_memd',
    default => sub {
        my $self = shift;
        my $mock_memd = Test::MockObject->new();
        foreach my $method (@{$self->methods}) {
            $mock_memd->mock($method, sub {return 'deadbeef' if ($_[1] eq 'test') });
        }
        return $mock_memd;
    },
);

has parent_overrides => (
    is => 'ro',
    default => sub {
        my $self = shift;

        my $overrides = Sub::Override->new()
                                     ->replace('Cache::Memcached::Fast::new' , sub { return $self->mock_base_memd })
                                     ->replace('Cache::Memcached::Fast::DESTROY' , sub { })
                                     ->replace($self->test_class.'::checkServers', sub { my $object = shift; $object->{servers} = 1 })
                                     ->replace($self->test_class.'::getServersFromEndpoint', sub { return ['10.112.21.4:11211'] });
        return $overrides;
    }
);

has methods => (
    is => 'ro',
    default => sub {
    return [qw(
enable_compress
namespace
set
set_multi
cas
cas_multi
add
add_multi
replace
replace_multi
append
append_multi
prepend
prepend_multi
get
get_multi
gets
gets_multi
incr
incr_multi
decr
decr_multi
delete
delete_multi
touch
touch_multi
flush_all
nowait_push
server_versions
disconnect_all
)]
    },
);

before run_test => sub {
    my $self = shift;
    $self->mock_base_memd->clear();
};

test "methods" => sub {
    my $self = shift;
    my $memd = $self->test_class->new(
        config_endpoint => 'dave',
    );
    foreach my $method (@{$self->methods}) {
        subtest "Method: $method" => sub {
                $memd->{servers} = 0;
                ok !$self->mock_base_memd->called($method);
                is $memd->$method('test'), 'deadbeef';
                ok $self->mock_base_memd->called($method);
                ok $memd->{servers};
        }
    }
};

run_me;
done_testing;
1;
