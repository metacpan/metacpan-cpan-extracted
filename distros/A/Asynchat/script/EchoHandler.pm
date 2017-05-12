package EchoHandler;

#==============================================================================
#
#         FILE:  EchoHandler.pm
#
#  DESCRIPTION:  handles echoing messages from a single client 
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:   (Sebastiano Piccoli), <sebastiano.piccoli@gmail.com>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  08/02/13 12:00:00 CEST
#     REVISION:  ---
#==============================================================================

use strict;
use warnings;

use base qw( Asynchat );

sub init {
    my($self, $sock) = @_;

    $self->{_received_data} = [];
    $self->SUPER::init($sock);

    # start looking for the ECHO command
    $self->{_process_command} = 1;
    $self->set_terminator('\n');
    
    return $self;
}

sub collect_incoming_data {
    my($self, $data) = @_;
    
    # read an incoming message from the client and put it into our outgoing
    push @{ $self->{_received_data} }, $data;
}

sub found_terminator {
    my $self = shift;
   
    # the end of a command or message has been seen
    $self->process_data();
}

sub process_data {
    my $self = shift;
    
    if ($self->{_process_command}) {
        $self->_process_command();

    }
    else {
        $self->_process_message();
    }
}

sub _process_command {
    my $self = shift;
    
    # ECHO command
    my $command = join('', @{ $self->{_received_data} });
    my($verb, $arg) = split(/ /, $command); 
    my $expected_data_length = 0;
    if ($arg) { # and is a number
        $expected_data_length = int($arg);
    }
    $self->set_terminator($expected_data_length);
    $self->{_process_command} = 0;
    $self->{_received_data} = [];
}

sub _process_message {
    my $self = shift;
    
    # We have read the entire message to be sent back to the client
    my $to_echo = join('', @{ $self->{_received_data} });
    $self->push_direct($to_echo);
    $self->close_when_done();
}

1;

__END__
