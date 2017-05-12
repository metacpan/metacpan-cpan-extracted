#!/usr/bin/env perl

=head1 NAME

anyevent-udp-server.pl - Simple AnyEvent::Handle::UDP UDP server

=head1 DESCRIPTION

Starts a UDP server that listens on a given port for
input (incoming udp packets).

To test it, you can use the following command:
    
    $ echo "Test1" | nc -u -q1 localhost 4000

=head1 AUTHOR

Cosimo Streppone

=cut

use strict;
use warnings;

use AnyEvent::Handle::UDP;
use AnyEvent::Log ();

# Default for AnyEvent is to log nothing
$AnyEvent::Log::FILTER->level('debug');

# AE::Handle::UDP does all for us:
# be sure to use the "bind" option!
my $udp_server = AnyEvent::Handle::UDP->new(
    # Bind to this host and port
    bind => ['0.0.0.0', 4000],

    # AnyEvent will run this callback when getting some input
    on_recv => sub {
        my ($data, $ae_handle, $client_addr) = @_;
        chomp $data;
        AE::log warn => "Received '$data' (handle: $ae_handle)";
        # Send back the command echoed to the client who contacted us 
        $ae_handle->push_send("echo [$data]\n", $client_addr);
    }
);

# Start the main event loop
my $condvar = AE::cv;
$condvar->recv;

# Never gets here.
