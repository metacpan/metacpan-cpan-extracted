package App::pscan::Command::Tcp;
use warnings;
use strict;
use base qw( App::pscan::Scanner App::pscan::Command);
use POE qw(Wheel::SocketFactory Wheel::ReadWrite);
use POE::Component::Client::TCP;
use POE::Filter::Stream;
use App::pscan::Utils;

=head1 NAME

App::pscan::Command::tcp - test the ip with the tcp protocol

=head1 DESCRIPTION

tcp scan of a given range of the format of Net::IP and a port range.
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


sub scan() {
    my $self = shift;
    info 'TCP for '
        . $self->{'IP'}->ip()
        . ' port range: '
        . $self->{'first'} . "-"
        . $self->{'last'};

    my $Payload = $self->{'payload'} || "";
    info 'Payload: '.$Payload;
    do {
        for ( $self->{'first'} .. $self->{'last'} ) {
            my $port = $_;
            my $host = $self->{'IP'}->ip() if exists $self->{'IP'};
            POE::Component::Client::TCP->new(
                RemoteAddress => $host,
                RemotePort    => $port,
                Filter        => "POE::Filter::Stream",

              # The client has connected.  Display some status and prepare to
              # gather information.  Start a timer that will send ENTER if the
              # server does not talk to us for a while.
                Connected => sub {
                    info "connected to $host:$port ...";
                    $_[HEAP]->{banner_buffer} = [];
                    $_[KERNEL]->delay( send_enter => 5 );
                },

                # The connection failed.
                ConnectError => sub {

                    #error "could not connect to $host:$port ...";
                },

              # The server has sent us something.  Save the information.  Stop
              # the ENTER timer, and begin (or refresh) an input timer.  The
              # input timer will go off if the server becomes idle.
                ServerInput => sub {
                    my ( $kernel, $heap, $input ) = @_[ KERNEL, HEAP, ARG0 ];
                    notice "got input from $host:$port ...";
                    push @{ $heap->{banner_buffer} }, $input;
                    $kernel->delay( send_enter    => undef );
                    $kernel->delay( input_timeout => 1 );
                },

                # These are handlers for additional events not included in the
                # default Server::TCP module.  In this example, they handle
                # timers that have gone off.
                InlineStates =>
                    { # The server has not sent us anything yet.  Send an ENTER
                     # keystroke (really a network newline, \x0D\x0A), and wait
                     # some more.
                    send_enter => sub {
                        info "sending enter on $host:$port ...";
                        $_[HEAP]->{server}->put($Payload)
                            if $_[HEAP]->{server};    # sends enter
                        $_[KERNEL]->delay( input_timeout => 5 );
                    },

                # The server sent us something already, but it has become idle
                # again.  Display what the server sent us so far, and shut
                # down.
                    input_timeout => sub {
                        my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
                        notice "got input timeout from $host:$port ...";
                        notice ",----- Banner from $host:$port";
                        foreach ( @{ $heap->{banner_buffer} } ) {
                            notice "| $_";

                            # print "| ", unpack("H*", $_), "\n";
                        }
                        notice "`-----";
                        $kernel->yield("shutdown");
                    },
                    },
            );
        }
    } while ( ++$self->{'IP'} );

    info 'Spawning scans';

    # Run the clients until the last one has shut down.
    $poe_kernel->run();
    exit;
}

1;
