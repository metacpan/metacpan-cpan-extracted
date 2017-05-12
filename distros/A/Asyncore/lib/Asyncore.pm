package Asyncore;
{
  $Asyncore::VERSION = '0.08';
}

#==============================================================================
#
#         FILE:  Asyncore.pm
#
#  DESCRIPTION:  porting in Perl of asyncore.py (python 2.7) 
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:   (Sebastiano Piccoli), <sebastiano.piccoli@gmail.com>
#      COMPANY:  
#      VERSION:  0.08
#      CREATED:  26/06/12 20:27:28 CEST
#     REVISION:  ---
#==============================================================================

use strict;
use warnings;

use IO::Select;
use Socket;
use Carp;

our $socket_map;

if (not $socket_map) {
    $socket_map = {}
}

sub _read {
    my $obj = shift;
    
    eval {
        $obj->handle_read_event();
    };
    if ($@) {
        $obj->handle_error($@);      
    }
}

sub _write {
    my $obj = shift;
    
    eval {
        $obj->handle_write_event();
    };
    if ($@) {
        $obj->handle_error($@);      
    }
}

sub _exception {
    my $obj = shift;
    
    eval {
        $obj->handle_expt_event();
    };
    if ($@) {
        $obj->handle_error($@);
    }
}

sub poll {
    my($timeout, $map) = @_;
    
    if (not $map) {
        $map = $socket_map;
    }
    
    if ($map) {
        my $r = new IO::Select;
        my $w = new IO::Select;
        my $e = new IO::Select;
        foreach my $fd (keys %{ $map }) {
            my $obj = $map->{$fd};
            my $is_r = $obj->readable();
            my $is_w = $obj->writable();
            
            if ($is_r) {
                $r->add($obj->{_socket});
            }
            if ($is_w and not $obj->{_accepting}) {
                $w->add($obj->{_socket});

            }
            if ($is_r or $is_w) {
                $e->add($obj->{_socket});
            }
        }
        if (not @$r and not @$w and not @$e) {
            sleep($timeout);
            return
        }
        
        my($rr, $rw, $he);
        eval {
            # rr, wr: ready for reading/writing. he: has exception
            ($rr, $rw, $he) = IO::Select->select($r, $w, $e, $timeout);
        };
        if ($@) {
            croak "$@";
        }
        
        foreach my $fd (@$rr) {
            next if !defined(fileno($fd));
            my $obj = $map->{fileno($fd)};
            if (not $obj) {
                next;
            }
            _read($obj);
        }
        
        foreach my $fd (@$rw) {
            next if !defined(fileno($fd));
            my $obj = $map->{fileno($fd)};
            if (not $obj) {
                next;
            }
            _write($obj);
        }
        
        foreach my $fd (@$he) {
            my $obj = $map->{$fd->fileno()};
            if (not $obj) {
                next;
            }
            _exception($obj);
        }
    }
}

sub loop {
    my($timeout, $use_poll, $map, $count) = @_;
    
    if (not $timeout) {
        $timeout = 30;
    }

    if (not $map) {
        $map = $socket_map;
    }

    #if ($use_poll and hasattr(select, 'poll') {
        #$poll_fun = $poll2
    #}
    #else {
        #$poll_fun = $poll
    #}

    if (not $count) {
        while ($map) {
            #$poll_fun($timeout, $map)
            poll($timeout, $map)
        }
    }
    else {
        while (($map) and ($count > 0)) {
            #$poll_fun($timeout, $map);
            $count--;
        }
    }
}



package Asyncore::Dispatcher;
{
    $Asyncore::Dispatcher::VERSION = '0.08';
}

#==============================================================================
#
#         FILE:  Asyncore.pm
#      PACKAGE:  Asyncore::Dispatcher
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:   (Sebastiano Piccoli), <sebastiano.piccoli@gmail.com>
#      COMPANY:  
#      VERSION:  0.8
#      CREATED:  26/06/12 20:27:28 CEST
#     REVISION:  ---
#==============================================================================

use strict;
use warnings;

use Socket;
use Fcntl;
use Carp;
use Errno;

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->init(@_);
}

sub init {
    my($self, $sock, $map) = @_;

    if (not $map) {
        $self->{_map} = $socket_map;
    }
    else {
        $self->{_map} = $map; 
    }

    $self->{_fileno} = 0;
    
    if ($sock) {
        # Set to nonblocking just to make sure for cases where we 
        # get a socket from a blocking source
        fcntl($sock, F_SETFL, O_NONBLOCK);
        $self->set_socket($sock, $map);
        $self->{_connected} = 1;
        
        if (not getpeername($sock)) {
            if ($!{ENOTCONN} || $!{EINVAL}) {
                # Handle the case where we got an unconnected socket
                $self->{_connected} = 0;
            }
            else {
                # Handle the case where the socket is broken in some unknown
                # way, alert the user and remove it from the map (to prevent
                # polling of broken sockets)
                $self->del_channel($map);
        
            }
        }
    }
    else {
        $self->{_socket} = 0;
    }
    
    return $self;
}

sub add_channel {
    my($self, $map) = @_;

    if (not $map) {
        $map = $self->{_map}
    }

    $map->{$self->{_fileno}} = $self;
}

sub del_channel {
    my($self, $map) = @_;

    if (not $map) {
        $map = $self->{_map}
    }
    
    my $fd = $self->{_fileno};
    foreach my $mfd (keys %{ $map }) {
        if ($mfd == $fd) {
            delete $map->{$mfd};
        }
    }
    
    $self->{_fileno} = undef;
}   

sub create_socket {
    my($self, $family, $type) = @_;
    
    if (not $family) {
        $family = AF_INET;
    }
    if (not $type) {
        $type = SOCK_STREAM; # tcp
    }
    # SOCK_DGRAM (udp), SOCK_RAW (icmp)
    
    my $sock;
    my $proto = getprotobyname("tcp"); # fixme
    socket($sock, AF_INET, SOCK_STREAM, $proto) || croak "$!";
    fcntl($sock, F_SETFL, O_NONBLOCK);
    
    $self->set_socket($sock);
}

sub set_socket {
    my($self, $sock, $map) = @_;

    $self->{_socket} = $sock;
    $self->{_fileno} = fileno($sock);
    $self->add_channel($map);
}
    
sub readable {
    my $self = shift;
    
    return 1;
}

sub writable {
    my $self = shift;
    
    return 1;
}

sub bind {
    my($self, $port) = @_;
    
    my $sock = $self->{_socket};
    my $iaddr = gethostbyname('localhost');
    bind($sock, sockaddr_in($port, $iaddr));
}

sub listen {
    my($self, $num) = @_;

    $self->{_accepting} = 1;

    my $sock = $self->{_socket};
    listen($sock, $num);
}

sub connect {
    my($self, $addr, $port) = @_;

    $self->{_connected} = 0;
    $self->{_connecting} = 1;

    my $sock = $self->{_socket};
    my $iaddr = inet_aton($addr);
    my $paddr = sockaddr_in($port, $iaddr);
    # In the case of a non-blocking socket connection cannot be completed
    # immediately. connect is a form of write so select() or poll() can be
    # used to determine when it's possible to write.
    unless (connect($sock, $paddr)) {
        if ($!{EINPROGRESS}) {
            return;
        }
    }
    
    $self->{_addr} = $addr;
    $self->{_port} = $port;
    $self->handle_connect_event();
}

sub accept {
    my $self = shift;
    
    my $conn;
    my $sock = $self->{_socket};
    
    if (not accept($conn, $sock)) {
        if ($!{EWOULDBLOCK} || $!{ECONNABORTED} || $!{EAGAIN}) {
            # Handle the case where we cannot accept connection
            return;
        }
        else {
            carp 'Unknown error in accept()';
        }        
    }
    
    return $conn;
}

sub send {
    my($self, $data) = @_;
    
    my $sock = $self->{_socket};
    
    my $result;
    eval {
        send($sock, $data, 0);
    };
    if ($@) {
        croak "$@";
    }

    return $result;
}

sub receive {
    my($self, $buffer_size) = @_;
    
    my $data;
    my $sock = $self->{_socket};
    recv($sock, $data, $buffer_size, 0);
    
    if (not $data) {
        $self->handle_close();
        return '';
    }
    else {
        return $data;
    }
    
    # check error todo
}

sub close {
    my $self = shift;
    
    $self->{_connected} = 0;
    $self->{_accepting} = 0;
    $self->{_connecting} = 0;
    
    my $sock = $self->{_socket};
    close($sock);
}

sub handle_close {
    my $self = shift;
    
    $self->close();
}

sub handle_read_event {
    my $self = shift;
    
    if ($self->{_accepting}) {
        $self->handle_accept();
    }
    elsif (not $self->{_connected}) {
        if ($self->{_connecting}) {
            $self->handle_connect_event();
        }
        $self->handle_read();
    }
    else {
        $self->handle_read();
    }
}

sub handle_connect_event {
    my $self = shift;
    
    # some preliminary check todo
    
    $self->handle_connect();
    $self->{_connected} = 1;
    $self->{_connecting} = 0;
}

sub handle_write_event {
    my $self = shift;
    
    if ($self->{_accepting}) {
        return;
    }
    
    if (not $self->{_connected}) {
        if ($self->{_connecting}) {
            $self->handle_connect_event();
        }
    }
    $self->handle_write();
}

sub handle_expt_event {
    my $self = shift;
    
    my $err = $self->{_socket}->getsockopt();
    if ($err != 0) {
        $self->handle_close();
    }
    else {
        $self->handle_expt();
    }
}

sub handle_error {
    my($self, $error) = @_;
    
    warn $error;
    
    $self->handle_close();
}

sub handle_expt {
    # overrided
}

sub handle_read {
    # overrided
}

sub handle_write {
    # overrided
}

sub handle_connect {
    # overrided
}

sub handle_accept {
    # overrided
}


1;

__END__


=head1 NAME

Asyncore - basic infrastracture for asynchronous socket services

=head1 SYNOPSIS

    use Asyncore;
    use base qw( Asyncore::Dispatcher );
    
    my $server = Asyncore::Dispatcher->new();
    $server->create_socket();
    $server->bind($port)
    $server->listen(5);
 
    Asyncore::loop();

 
=head1 DESCRIPTION

Asyncore is a basic infrastructure for asyncronous socket programming. It provides an implementation of "reactive socket" and it provides hooks for handling events. Code must be written into these hooks (handlers).
 
Asyncore captures the state of each connection (at the lowest level there is a call to select() and poll()) and it relies on the work to be done on the basis of the connection status (handler).
 
To manage an asyncronous socket handler instantiate a subclass of Asyncore::Dispatcher and override methods that follow:
 
 writable
 readble
 handle_connect
 handle_accept
 handle_read
 handle_write
 handle_close
 handle_expt
 handle_error
 
 
=head1 METHODS

=head2 Asyncore::loop($timeout, $use_poll, \%map, $count)
 
Enter a polling loop that terminates after count passes or all open channels have been closed. All arguments are optional. The count parameter defaults to undef, resulting in the loop terminating only when all channels have been closed. The timeout argument sets the timeout parameter for the appropriate select() or poll() call, measured in seconds; the default is 30 seconds. [The use_poll parameter, if true, indicates that poll() should be used in preference to select() (the default is False) TBD].
 
The map parameter is an hash reference whose items are the channels to watch. As channels are closed they are deleted from their map. If map is omitted, a global map is used. Channels (instances of Asyncore::Dispatcher, Asynchat::async_chat() and subclasses thereof) can freely be mixed in the map.

=head2 handle_connect()
 
=head2 handle_accept()
 
=head2 handle_write()

=head1 ACKNOWLEDGEMENTS

This module is a porting of asyncore.py written in python.
 
=head1 LICENCE

LGPL
