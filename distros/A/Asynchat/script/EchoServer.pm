package EchoServer;

#==============================================================================
#
#         FILE:  EchoServer.pm
#
#  DESCRIPTION:  Receives connections and established handlers for each client 
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:   (Sebastiano Piccoli), <sebastiano.piccoli@gmail.com>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  08/02/13 00:53:28 CEST
#     REVISION:  ---
#==============================================================================

use strict;
use warnings;

use Asyncore;
use EchoHandler;
use base qw( Asyncore::Dispatcher );

sub init {
    my($self, $port, $family, $type) = @_;

    $self->SUPER::init();

    if (not $port) {
        $port = 37;
    }

    $self->create_socket($family, $type);
    $self->bind(35000);
    $self->listen(5);
}

sub handle_accept {
    my $self = shift;
   
    # called when a client connects to the socket
    my $channel = $self->accept();
    my $echo_channel = EchoHandler->new($channel);
}


1;

__END__
