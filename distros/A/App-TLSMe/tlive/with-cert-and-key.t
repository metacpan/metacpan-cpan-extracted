use strict;
use warnings;

use lib 'tlive/lib';

use Test::More;

use AnyEvent;
use AnyEvent::Impl::Perl;
use AnyEvent::Socket;
use IO::Socket;

use App::TLSMe;
use App::TLSMe::Logger;
use FreePort;

my $host         = '127.0.0.1';
my $port         = FreePort->get_free_port();
my $backend_host = '127.0.0.1';
my $backend_port = FreePort->get_free_port();

tcp_server $backend_host, $backend_port, sub {
    my ($fh, $host, $port) = @_;

    syswrite $fh, "200 OK\015\012";
};

my $null = '';
open my $fh, '>', \$null;
my $tlsme = App::TLSMe->new(
    logger    => App::TLSMe::Logger->new(fh => $fh),
    cert_file => 'tlive/cert',
    key_file  => 'tlive/key',
    listen    => "$host:$port",
    backend   => "$backend_host:$backend_port"
);

my $handle = AnyEvent::Handle->new(
    connect => [$host, $port],
    tls     => "connect",
    tls_ctx => {},
    on_read => sub {
        my ($handle) = @_;

        $handle->push_read(
            line => sub {
                is($_[1], '200 OK');
            }
        );
    },
    on_eof => sub {
        $tlsme->stop;
    }
);

$handle->push_write(<<"EOF");
GET / HTTP/1.1

EOF

$tlsme->run;

done_testing;
