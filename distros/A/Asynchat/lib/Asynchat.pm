package Asynchat;
{
  $Asynchat::VERSION = '0.01';
}

#==============================================================================
#
#         FILE:  Asynchat.pm
#
#  DESCRIPTION:  porting in Perl of asynchat.py (python 2.7) 
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:   (Sebastiano Piccoli), <sebastiano.piccoli@gmail.com>
#      COMPANY:  
#      VERSION:  0.01
#      CREATED:  08/09/12 19:47:28 CEST
#     REVISION:  ---
#==============================================================================

use strict;
use warnings;

use Scalar::Util::Numeric qw(isnum isint);
use Asyncore;
use base qw( Asyncore::Dispatcher );
use Socket;
use Carp;

our $ac_in_buffer_size = 4096;
our $ac_out_buffer_size = 4096;

sub init {
    my($self, $sock, $map) = @_;

    $self->{_ac_in_buffer} = '';
    $self->{_incoming} = [];
    $self->{_producer_fifo} = []; # a list of data;
    $self->SUPER::init($sock, $map);
    
    return $self;
}

sub collect_incoming_data {
    # overrided
}

sub _collect_incoming_data {
    my($self, $data) = @_;
    
    push(@{ $self->{_incoming} }, $data);
}

sub _get_data {
    my $self = shift;

    my $data = join("", @{ $self->{_incoming} });
    #delete $self->{_incoming};
    
    return $data;
}

sub found_terminator {
    # overrided
}

sub set_terminator {
    my($self, $terminator) = @_;
    
    # Set the input delimiter.
    # Can be a fixed string of any length, an integer, or undef
    $self->{_terminator} = $terminator;
}

sub get_terminator {
    my $self = shift;
    
    return $self->{_terminator};
}

sub handle_read {
    my $self = shift;
    
    my $data = $self->receive($ac_in_buffer_size);	
    # catch error todo
    
    $self->{_ac_in_buffer} = $self->{_ac_in_buffer} . $data;
    
    # Continue to search for terminator in ac_in_buffer,
    # while calling collect_incoming_data. The while loop
    # is necessary because we might read several data terminator
    # combos with a single recv(4096).
    while ($self->{_ac_in_buffer}) {
        my $lb = length($self->{_ac_in_buffer});
        my $terminator = $self->get_terminator();
        if (not $terminator) {
            # no terminator, collect it all
            $self->collect_incoming_data($self->{_ac_in_buffer});
            $self->{_ac_in_buffer} = '';
        }
        elsif ((isnum($terminator)) and (isint($terminator) > 0)) {
            # numeric terminator
            my $n = $terminator;
            if ($lb < $n) {
                $self->collect_incoming_data($self->{_ac_in_buffer});
                $self->{_ac_in_buffer} = '';
                $self->{_terminator} = $self->{_terminator} - $lb;
            }
            else {
                # collect first n chars just to complete all the chars 
                $self->collect_incoming_data(substr($self->{_ac_in_buffer}, 0, $n));
                $self->{_ac_in_buffer} = substr($self->{_ac_in_buffer}, $n, $lb);
                $self->{_terminator} = 0;
                $self->found_terminator();
            }
        }
        else {
            # 3 cases:
            # 1) end of buffer matches terminator exactly:
            #    collect data, transition
            # 2) end of buffer matches some prefix:
            #    collect data to the prefix
            # 3) end of buffer does not match any prefix:
            #    collect data
            my $terminator_length = length($terminator);
            if ($self->{_ac_in_buffer} =~ m/$terminator/g) {
                # we found the terminator so collect data just to terminator
                my $offset = pos($self->{_ac_in_buffer});
                if ($offset > 0) {
                    $self->collect_incoming_data(substr($self->{_ac_in_buffer}, 0, $offset));
                }
                # todo: check this sum
                #$self->{_ac_in_buffer} = substr($self->{_ac_in_buffer}, $offset+$terminator_length);
                $self->{_ac_in_buffer} = substr($self->{_ac_in_buffer}, $offset);
                $self->found_terminator();
            }
            else {
                if (find_prefix_at_end($self->{_ac_in_buffer}, $terminator)) {
                    # todo    
                }
                else {
                    $self->collect_incoming_data($self->{_ac_in_buffer});
                    $self->{_ac_in_buffer} = "";
                }
            }
        }
    }
}

sub handle_write {
    my $self = shift;
    
    $self->initiate_send();
}

sub handle_close {
    my $self = shift;
    
    $self->close();
}

sub push_direct {
    my($self, $data) = @_;
    
    my $sabs = $ac_in_buffer_size;
    if (length($data) > $sabs) {
        for (my $i = 0; $i < length($data); $i += $sabs) {
            push(@{ $self->{_producer_fifo} }, substr($data, $i, $i + $sabs));
        }
    }
    else {
        push @{ $self->{_producer_fifo} }, $data;
    }
    $self->initiate_send();
}

sub push_with_producer {
    my($self, $producer) = @_;
    
    push @{ $self->{_producer_fifo} }, $producer;
    $self->initiate_send(); 
}

sub readable {
    return 1;    
}

sub writeable {
    my $self = shift;
    
    # check this
    return $self->{_producer_fifo} || (not $self->{_connected});
}

sub close_when_done {
    my $self = shift;

    # automatically close this channel once the outgoing queue is empty
    push @{ $self->{_producer_fifo} }, undef;
}

sub initiate_send {
    my $self = shift;  
    
    while ((@{ $self->{_producer_fifo} }) and ($self->{_connected})) {
        my $first = shift @{ $self->{_producer_fifo} };
        
        if (!defined $first) {
            $self->handle_close();    
            return;
        }
        if ($first eq '') {
            shift @{ $self->{_producer_fifo} };
        }
        
        my $data = substr($first, 0, $ac_out_buffer_size);
       
        # catch exception todo
        my $sock = $self->{_socket};
        my $num_sent = send($sock, $data, 0);
       
        if ($num_sent) {
            if (($num_sent < length($data)) or
                ($ac_out_buffer_size < length($first))) {
                
                unshift @{ $self->{_producer_fifo} }, substr($first, $num_sent);
            }
        }
   
        # we tried to send some actual data 
        return;
    } 
}

sub discard_buffers {
    my $self = shift;

    $self->{_ac_in_buffer} = '';
    $self->{_incoming} = [];
    $self->{_producer_fifo} = [];
}

sub find_prefix_at_end {
    # todo
}


package Asynchat::SimpleProducer;

#==============================================================================
#
#         FILE:  Asynchat.pm
#      PACKAGE:  Asynchat::SimpleProducer
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:   (Sebastiano Piccoli), <sebastiano.piccoli@gmail.com>
#      COMPANY:  
#      VERSION:  0.1
#      CREATED:  08/02/13 14:34:00 CEST
#     REVISION:  ---
#==============================================================================

use strict;
use warnings;

sub init {
    my $self = shift;

    # todo
}

sub more {
    my $self = shift;    

    # todo
}

1;

__END__


=head1 NAME

Asynchat - used as base class of Asyncore to simplify to handle protocols


=head1 SYNOPSIS

    use base qw( Asynchat );
    
    my $channel = Subclass->new($addr, $port);
    
    $channel->handle_connect( ... )
    $channel->collect_incoming_data( ... );
    $channel->found_terminator( ... )

 
=head1 DESCRIPTION

Asynchat builds on Asyncore, simplifying asynchronous clients and servers and making it easier to handle protocols whose elements are terminated by arbitrary strings, or are of variable length. 
 
Asyncore is a basic infrastructure for asyncronous socket programming. It provides an implementation of "reactive socket" and it provides hooks for handling events. Code must be written into these hooks (handlers).
 
Asynchat is intended as an abstract class. Override collect_incoming_data() and found_terminator() in a subclass to provide the implementation of the protocol you are writing.
 
See the folder <i>script</i> for a complete example on the correct use of this module.
 

=head1 METHODS

=head2 collect_incoming_data($data)

=head2 set_terminator($string)
 
=head2 get_terminator()
 
=head2 found_terminator()
 
=head2 push_direct($data)
 
=head2 push_with_producer($data)
 
=head2 close_when_done()
 

=head1 ACKNOWLEDGEMENTS

This module is a porting of asynchat.py written in python.


=head1 LICENCE

LGPL
