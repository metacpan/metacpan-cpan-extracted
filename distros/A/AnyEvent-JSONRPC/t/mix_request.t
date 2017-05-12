use Test::Base;

plan tests => 8;

use Test::TCP;
use AnyEvent::JSONRPC::TCP::Client;
use AnyEvent::JSONRPC::TCP::Server;

my $port = empty_port;

my $cv = AnyEvent->condvar;

my $server = AnyEvent::JSONRPC::TCP::Server->new( port => $port );

my $waits = [ undef, rand(2), rand(2), rand(2), rand(2) ];
my $exit = 0;

$server->reg_cb(
    wait => sub {
        my ($r, $num, $wait) = @_;

        is( $waits->[$num], $wait, "Num $num will wait for $wait seconds ok");

        my $w; $w = AnyEvent->timer(
            after => $wait,
            cb    => sub {
                $r->result($wait);
                if (++$exit >= 4) {
                    my $w; $w = AnyEvent->timer(
                        after => 0.3,
                        cb    => sub { undef $w; $cv->send },
                    );
                }
                else {
                    undef $w;
                }
            },
        );
    },
);

my $client = AnyEvent::JSONRPC::TCP::Client->new( version => '1.0', host => '127.0.0.1', port => $port );

my $cv1 = $client->call( wait => '1', $waits->[1] );
my $cv2 = $client->call( wait => '2', $waits->[2] );
my $cv3 = $client->call( wait => '3', $waits->[3] );
my $cv4 = $client->call( wait => '4', $waits->[4] );

$cv1->cb(sub { is(shift->recv, $waits->[1], "cv1 waited $waits->[1] seconds ok") });
$cv2->cb(sub { is(shift->recv, $waits->[2], "cv2 waited $waits->[2] seconds ok") });
$cv3->cb(sub { is(shift->recv, $waits->[3], "cv3 waited $waits->[3] seconds ok") });
$cv4->cb(sub { is(shift->recv, $waits->[4], "cv4 waited $waits->[4] seconds ok") });

$cv->recv;
