use common::sense;

use Test::More tests => 1;

use File::Temp;
use Chouette;
use AnyEvent::HTTP;
use AnyEvent::Socket;

my $dir = File::Temp::tempdir(CLEANUP => 1);

my $chouette = Chouette->new({
    config_defaults => {
        var_dir => $dir,
        listen => "unix:$dir/test.socket",
    },

    routes => {
        '/' => {
            GET => sub {
                my $c = shift;
                die $c->respond({ hello => 'world!' });
            },
        },
    },

    quiet => 1,
});

$chouette->serve;

my $cv = AE::cv;

my $w = http_get "http://localhost",
                 tcp_connect => sub { AnyEvent::Socket::tcp_connect("unix/", "$dir/test.socket", $_[2], $_[3],) },
                 sub {
    is($_[0], '{"hello":"world!"}', 'got hello world back');
    $cv->send;
};

$cv->recv;
