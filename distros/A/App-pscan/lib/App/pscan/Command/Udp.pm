package App::pscan::Command::Udp;
use warnings;
use strict;
use base qw( App::pscan::Scanner App::pscan::Command);
use IO::Socket::INET;
use POE;
use constant DATAGRAM_MAXLEN => 1024;
use App::pscan::Utils;

=head1 NAME

App::pscan::Command::udp - test the ip with the udp protocol

=head1 DESCRIPTION

udp scan of a given range of the format of Net::IP and a port range.
e.g.: 192.168.1.0/24:80
      192.168.1.1:20-90
      www.google.it:70-80


=head1 OPTIONS

-p or --payload specify a payload to send within the request

=cut

sub options {
    (   "verbose"     => "verbose",
        "p|payload=s" => "payload"
    );
}

sub scan {
    my $self = shift;
    info 'UDP for '
        . $self->{'IP'}->ip()
        . ' port range: '
        . $self->{'first'} . "-"
        . $self->{'last'};

    my $Payload = $self->{'payload'} || "This is a test by App::pscan";
    info 'Payload: ' . $Payload;
    do {
        for ( $self->{'first'} .. $self->{'last'} ) {
            my $port = $_;
            my $host = $self->{'IP'}->ip();
            POE::Session->create(
                inline_states => {
                    _start       => \&client_start,
                    get_datagram => \&client_read,
                    timed_out    => \&timeout
                },
                args => [ $host, $port, $Payload ],
            );

        }
    } while ( ++$self->{'IP'} );

    # Run the clients until the last one has shut down.
    POE::Kernel->run();
    exit;
}

sub client_start {
    my ( $kernel, $session, $heap, $ip, $port, $Payload )
        = @_[ KERNEL, SESSION, HEAP, ARG0, ARG1, ARG2 ];
    my $socket = IO::Socket::INET->new( Proto => 'udp', Timeout => 4 );
    die "Couldn't create client socket: $!" unless $socket;
    $kernel->select_read( $socket, "get_datagram" );
    $kernel->delay( timed_out => 4, $socket );

    #info "Sending '$message' to $ip, waiting for responses";
    my $server_address = pack_sockaddr_in( $port, inet_aton($ip) );
    if ( my $result = send( $socket, $Payload, 0, $server_address ) ) {
        if ( $result == length($Payload) ) {
            info "Message sent to $ip:$port";
        }
        else {
            die "Trouble sending message: $!";
        }
    }
}

sub client_read {
    my ( $kernel, $socket ) = @_[ KERNEL, ARG0 ];
    my $remote_address
        = recv( $socket, my $message = "", DATAGRAM_MAXLEN, 0 );
    return unless defined $remote_address;
    my ( $peer_port, $peer_addr ) = unpack_sockaddr_in($remote_address);
    my $human_addr = inet_ntoa($peer_addr);

    notice "(answer) $human_addr:$peer_port ...";
    notice ",----- Banner from $human_addr:$peer_port";
    notice "| $message";
    notice "`-----";
    $kernel->select_read($socket);
    $kernel->yield("shutdown");

}

sub timeout {

    $_[KERNEL]->select_read( $_[ARG0] );
    $_[KERNEL]->yield("shutdown");

}
1;
