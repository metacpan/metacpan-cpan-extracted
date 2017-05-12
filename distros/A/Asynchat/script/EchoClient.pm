package EchoClient;

#==============================================================================
#
#         FILE:  EchoClient.pm
#
#  DESCRIPTION:  Sends message to the server and receives response
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:   (Sebastiano Piccoli), <sebastiano.piccoli@gmail.com>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  08/02/13 13:55:00 CEST
#     REVISION:  ---
#==============================================================================

use strict;
use warnings;

use base qw( Asynchat );

sub init {
    my($self, $addr, $port, $family, $type, $message) = @_;

    $self->{_message} = $message; 
    $self->{_received_data} = [];

    $self->SUPER::init();

    if (not $port) {
        $port = 37;
    }

    $self->create_socket($addr, $family, $type);
    $self->connect($addr, $port);
}

sub handle_connect {
    my $self = shift;
    
    # Send the command
    $self->push_direct(sprintf("ECHO %d\n", length($self->{_message})));
    
    # Send the message
    #$self->push_with_producer(EchoProducer::more($self->{_message}));
    $self->push_with_producer($self->{_message});
    
    $self->set_terminator(length($self->{_message}));
}

sub collect_incoming_data {
    my($self, $data) = @_;

    push @{ $self->{_received_data} }, $data;
}

sub found_terminator {
    my $self = shift;
    
    my $received_message = join('', @{ $self->{_received_data} });

    if ($received_message eq $self->{_message}) {
        print "RECEIVED A COPY OF MESSAGE:\n";
        printf "%s", $received_message;
    }
    else {
        print "ERROR IN TRASMISSION\n";
        printf "EXPECTED: %s\n", $self->{_message};
        printf "RECEIVED: %s\n", $received_message;
    }
    $self->handle_close();
}


package EchoProducer;

use strict;
use warnings;

use Asynchat;
use base qw( Asynchat::SimpleProducer );

sub more {
    my $self = shift;

    # todo 
}

1;

__END__
