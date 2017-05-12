use Test::Base;
use Test::TCP;

plan tests => 2;

use AnyEvent::JSONRPC::Lite;

my $port = empty_port;

my $server = jsonrpc_server undef, $port;
$server->reg_cb(
    echo => sub {
        my ($result_cv, @params) = @_;
        $result_cv->result(@params);
    }
);

my $cv = AnyEvent->condvar;

my $client;
{
    my $closed;
    $client = AnyEvent::JSONRPC::Lite::Client->new(
        host => '127.0.0.1',
        port => $port,
        handler_options => {
            on_error => sub {
                $closed++;
            },
        },
    );

    my $d = $client->call( echo => { foo => 'bar' } );
    my $res = $d->recv;

    is_deeply({ foo => 'bar' }, $res, 'echo response ok');

    undef $server;

    my $t; $t = AnyEvent->timer(
        after => 0.5,
        cb    => sub {
            undef $t;
            ok $closed, 'server closed ok';
            $cv->send;
        },
    );
}

$cv->recv;
