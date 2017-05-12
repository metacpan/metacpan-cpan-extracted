use Test::Base;

plan tests => 4;

use Test::TCP;
use AnyEvent::JSONRPC::Lite::Client;
use AnyEvent::JSONRPC::Lite::Server;

my $cv = AnyEvent->condvar;

my $port   = empty_port;
my $server = AnyEvent::JSONRPC::Lite::Server->new( port => $port );

$server->reg_cb(
    echo => sub {
        my ($r, @params) = @_;
        $r->result(@params);
    },
);

my $c1 = AnyEvent::JSONRPC::Lite::Client->new( host => '127.0.0.1', port => $port );
my $c2 = AnyEvent::JSONRPC::Lite::Client->new( host => '127.0.0.1', port => $port );

my $d1 = $c2->call('echo', 'call 1');
my $d2 = $c2->call('echo', 'call 2');

$cv->begin;
$d1->cb(sub {
    is($d1->recv, 'call 1', 'call 1 ok');

    my $d3 = $c1->call('echo', 'call 3');
    $d3->cb(sub {
        is($d3->recv, 'call 3', 'call 3 ok');
        $cv->end;
    });
});

$cv->begin;
$d2->cb(sub {
    is($d2->recv, 'call 2', 'call 2 ok');

    my $d4 = $c2->call('echo', 'call 4');
    $d4->cb(sub {
        is($d4->recv, 'call 4', 'call 4 ok');
        $cv->end;
    });
});

$cv->recv;
