package FreePort;

use strict;
use warnings;

sub get_free_port {
    shift;
    my ($from, $to) = @_;

    # http://enwp.org/List_of_TCP_and_UDP_port_numbers#Dynamic.2C_private_or_ephemeral_ports
    $from ||= 49152;
    $to   ||= 65535;
    my $try = 0;
    while ($try <= 20) {
        my $port = int $from + rand $to - $from;
        my $socket;
        $socket = IO::Socket::INET->new(
            Proto    => 'tcp',
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
        );
        if ($socket) {    # can connect, so port is occupied by someone else
            $socket->close;
            next;
        }
        $socket = IO::Socket::INET->new(
            Listen    => 5,
            LocalAddr => '127.0.0.1',
            LocalPort => $port,
            Proto     => 'tcp',
            ReuseAddr => 1,
        );
        if ($socket) {    # ok, can bind, use this
            $socket->close;
            return $port;
        }
        $try++;
    }
    die "Could not find an unused port between $from and $to.\n";
}

1;
