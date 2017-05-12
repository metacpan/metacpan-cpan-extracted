#!/usr/bin/env perl
use 5.12.2;
use Crixa;

my $mq      = Crixa->connect( host => 'localhost' );
my $channel = $mq->channel;
my $q       = $channel->queue( name => 'task_queue', durable => 1 );

$q->handle_message(
    sub {
        say $_->{body};
        sleep( $_->{body} =~ y/.// );
        say ' [x] Done';
        $channel->ack($_->{delivery_tag} );
    }
);

__END__
