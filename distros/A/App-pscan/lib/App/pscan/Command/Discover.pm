package App::pscan::Command::Discover;
use warnings;
use strict;
use base qw( App::pscan::Scanner App::pscan::Command);

BEGIN {
    print "POE::Component::Client::Ping requires root privilege\n"
        if $> and ( $^O ne 'VMS' );
}
use POE;
use POE::Component::Client::Ping;
use App::pscan::Utils;

=head1 NAME

App::pscan::Command::Discover - test the range of ips with Ping

=head1 DESCRIPTION

tcp scan of a given range of the format of Net::IP and a port range.
e.g.: 192.168.1.0/24
      192.168.1.1
      www.google.it


=cut

sub options {
    ( "verbose" => "verbose" );
}

sub scan() {
    my $self = shift;
    info 'Ping for ' . $self->{'IP'}->ip();

    POE::Component::Client::Ping->spawn(
        Alias   => 'pinger',    # The component's name will be "pinger".
        Timeout => 15,          # The default ping timeout.
    );

    # Create a session that will use the pinger.  Its parameters match
    # event names with the functions that will handle them.
    POE::Session->create(
        inline_states => {
            _start =>
                \&client_start,    # Call client_start() to handle "_start".
            pong =>
                \&client_got_pong,  # Call client_got_pong() to handle "pong".
        },
        args => [ $self->{'IP'} ]
    );

    # Start POE's main loop.  It will only return when everything is done.
    $poe_kernel->run();
    exit;

}

sub client_start {
    my ( $kernel, $session, $ip ) = @_[ KERNEL, SESSION, ARG0 ];
    info "Starting to ping hosts";
    do {
        # info "Pinging ".$ip->ip()." at ", scalar(localtime);

        # "Pinger, do a ping and return the results as a pong event.  The
        # address to ping is $ping."
        $kernel->post( pinger => ping => pong => $ip->ip );
    } while ( ++$ip );
}

# Handle a "pong" event (returned by the Ping component because we
# asked it to).  Just display some information about the ping.
sub client_got_pong {
    my ( $kernel, $session ) = @_[ KERNEL, SESSION ];

    # The original request is returned as the first parameter.  It
    # contains the address we wanted to ping, the total time to wait for
    # a response, and the time the request was made.
    my $request_packet = $_[ARG0];
    my ( $request_address, $request_timeout, $request_time )
        = @{$request_packet};

    # The response information is returned as the second parameter.  It
    # contains the response address (which may be different from the
    # request address), the ping's round-trip time, and the time the
    # reply was received.
    my $response_packet = $_[ARG1];
    my ( $response_address, $roundtrip_time, $reply_time )
        = @{$response_packet};

    # It is impossible to know ahead of time how many ICMP ping
    # responses will arrive for a particular address, so the component
    # always waits PING_TIMEOUT seconds.  An undefined response address
    # signals that this waiting period has ended.
    if ( defined $response_address ) {
        info sprintf( "Pinged %-15.15s - Response from %-15.15s in %6.3fs",
            $request_address, $response_address, $roundtrip_time );
    }
    else {
        #    notice "Time's up for responses from $request_address.";
    }
}

1;
