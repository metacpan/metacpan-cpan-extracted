#!/usr/bin/env perl
use 5.12.2;
use Crixa;
use UUID::Tiny qw();
{

    package FibonacciRpcClient;
    use Moose;
    use namespace::autoclean;

    has connection => (
        isa     => 'Crixa',
        is      => 'ro',
        default => sub { Crixa->connect( host => 'localhost', ); },
    );

    has channel => (
        isa     => 'Crixa::Channel',
        is      => 'ro',
        lazy    => 1,
        default => sub { shift->connection->channel },
        handles => [qw(publish queue)],
    );

    has callback_queue => (
        isa     => 'Crixa::Queue',
        is      => 'ro',
        lazy    => 1,
        default => sub { shift->queue( exclusive => 1 ) },
        handles => {
            handle_message      => 'handle_message',
            callback_queue_name => 'name',
        },
    );

    has corr_id => (
        isa     => 'Str',
        is      => 'ro',
        builder => '_build_corr_id'
    );

    sub _build_corr_id {
        UUID::Tiny::create_UUID_as_string(UUID::Tiny::UUID_V4);
    }

    sub call {
        my ( $self, $n ) = @_;

        shift->publish(
            routing_key => 'rpc_queue',
            body        => $n,
            props       => {
                reply_to       => $self->callback_queue_name,
                correlation_id => $self->corr_id,
            }
        );

        my $value;
        until ( defined $value ) {
            $self->handle_message(
                sub {
                    return
                        unless $_->{props}{correlation_id} eq $self->corr_id;
                    $value = $_->{body};
                }
            );
        }

        return int $value;
    }
    __PACKAGE__->meta->make_immutable;
}

my $fibonacci_rpc = FibonacciRpcClient->new();
say " [x] Requesting fib(30)";
my $response = $fibonacci_rpc->call(30);
say " [.] got response $response";

__END__
