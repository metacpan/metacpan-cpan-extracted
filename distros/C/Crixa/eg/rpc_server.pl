#!/usr/bin/env perl
use 5.12.2;
use Crixa;

my $mq      = Crixa->connect( host => "localhost", );
my $channel = $mq->channel;
my $q       = $channel->queue( name => 'rpc_queue' );

sub fib {
    my $n = shift;
    return 0 unless $n;
    return 1 if $n == 1;
    return fib( $n - 1 ) + fib( $n - 2 );
}

$channel->basic_qos( prefetch_count => 1 );
$q->handle_message(
    sub {
        my $n = int $_->{body};
        say " [.] fib($n)";
        my $response = fib($n);
        $channel->publish(
            routing_key => $_->{props}{reply_to},
            body        => $response,
            props       => { correlation_id => $_->{props}{correlation_id} },
        );
        $channel->ack( $_->{delivery_tag} );
    }
);

__END__
