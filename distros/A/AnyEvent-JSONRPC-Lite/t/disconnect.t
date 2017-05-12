use Test::Base;

plan tests => 3;

use Test::TCP;

use AnyEvent::Socket;
use AnyEvent::JSONRPC::Lite;

my $port = empty_port;

my $state = 'initial';

my $handle;
my $ready = AnyEvent->condvar;

my $server = tcp_server undef, $port, sub {
    my ($fh) = @_ or die $!;

    $state = 'connected';

    $handle = AnyEvent::Handle->new(
        fh     => $fh,
        on_error => sub {
            warn 'Server got: ', $_[2];
            $state = 'disconnected';
        },
        on_eof => sub {
            $state = 'disconnected';
        },
        on_read => sub {  },
    );
}, sub {
    my $t; $t = AnyEvent->timer(
        after => 1,
        cb    => sub {
            $ready->send;
            undef $t;
        },
    );
};

$ready->recv;

{
    my $client = jsonrpc_client '127.0.0.1', $port;
    # disconnect soon after leaving this scope

    my $sleep = AnyEvent->condvar;
    my $t; $t = AnyEvent->timer( after => 1, cb => sub { $sleep->send });
    $sleep->recv;
}

my $cv = AnyEvent->condvar;

my ($client, $timer1, $timer2);
my $t = AnyEvent->timer(
    after => 1,
    cb    => sub {
        is $state, 'disconnected', 'already disconnected ok';

        $client = jsonrpc_client '127.0.0.1', $port;
        $timer1 = AnyEvent->timer(
            after => 0.5,
            cb    => sub {
                is $state, 'connected', 'connected at this time ok';
                undef $client;  # disconnect here
            },
        );

        $timer2 = AnyEvent->timer(
            after => 1,
            cb    => sub {
                is $state, 'disconnected', 'connection disconnected ok';
                $cv->send;
            },
        );
    },
);

$cv->recv;
