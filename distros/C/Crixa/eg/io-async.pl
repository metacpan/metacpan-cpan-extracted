#!/usr/bin/env perl
use 5.12.1;
use warnings;

use Crixa;
use Redis;

use CPS qw(kloop);

use IO::Async::Routine;
use IO::Async::Channel;
use IO::Async::Loop;

my $loop      = IO::Async::Loop->new;
my $redis_ch  = IO::Async::Channel->new;
my $rabbit_ch = IO::Async::Channel->new;

my $redis_worker = IO::Async::Routine->new(
    channels_in => [$redis_ch],
    code        => sub {
        my $redis = Redis->new();
        while (1) {
            my $msg = $redis_ch->recv;
            $redis->set( 'test', $msg->{body} );
        }
        return 1;
    },
    on_finish => sub { },
);

my $rabbit_worker = IO::Async::Routine->new(
    channels_out => [$rabbit_ch],
    code         => sub {
        my $mq = Crixa->connect( host => 'localhost' );
        my $queue = $mq->queue( name => 'store', durable => 1 );
        while (1) {
            $queue->handle_message( sub { $rabbit_ch->send($_); } );
        }
        return 1;
    },
    on_finish => sub { },
);

$loop->add($redis_worker);
$loop->add($rabbit_worker);

kloop sub {
    my ( $next, $last ) = @_;
    $rabbit_ch->recv(
        on_recv => sub {
            my ( $c, $data ) = @_;
            $next->();
            $redis_ch->send($data);
        }
    );
};

$loop->run;
