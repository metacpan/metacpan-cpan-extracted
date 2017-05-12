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

my $null = '';
open my $fh, '>', \$null;
my $tlsme = App::TLSMe->new(
    logger    => App::TLSMe::Logger->new(fh => $fh),
    cert_file => 'tlive/cert',
    key_file  => 'tlive/key',
    listen    => "$host:$port",
    backend   => "$backend_host:$backend_port"
);

my $response = '';
my $handle; $handle = AnyEvent::Handle->new(
    connect => [$host, $port],
    on_read => sub {
        my ($handle) = @_;

        $handle->push_read(
            line => sub {
                $response .= $_[1];
            }
        );
    },
    on_error => sub {
        $tlsme->stop;
    },
    on_eof => sub {
        $tlsme->stop;
    }
);

$handle->push_write(<<"EOF");
GET / HTTP/1.1

EOF

$tlsme->run;

is($response, 'HTTP/1.1 501 Not ImplementedContent-Length: 93');

done_testing;
