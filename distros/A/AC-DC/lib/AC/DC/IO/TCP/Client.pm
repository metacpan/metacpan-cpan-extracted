# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Mar-27 15:11 (EDT)
# Function: tcp client
#
# $Id$

# callbacks:
#  connect
#  error	=> shut()

package AC::DC::IO::TCP::Client;
use AC::DC::Debug 'tcp_client';
use Socket;
use POSIX;
use strict;

our @ISA = 'AC::DC::IO::TCP';

sub new {
    my $class = shift;
    my $addr  = shift;
    my $port  = shift;

    ($addr, $port) = $class->use_addr_port( $addr, $port );

    debug("starting new tcp client: $addr:$port");
    my $ip = inet_aton($addr);
    unless($ip){
        verbose("tcp client cannot resolve '$addr'");
        return ;
    }

    my $me = $class->SUPER::new( @_ );

    $me->{tcp_server_ip}   = $ip;
    $me->{tcp_server_addr} = $addr;
    $me->{tcp_server_port} = $port;

    return $me;
}

sub start {
    my $me = shift;

    my $fd;
    my $i = socket($fd, PF_INET, SOCK_STREAM, 0);
    $me->SUPER::start($fd);
    unless( $i ){
        verbose("tcp client socket failed: $! ($me->{info})");
        $me->run_callback('error', { cause => 'socket', error => "socket failed: $!" });
        $me->shut();
        return ;
    }

    while(1){
        my $i = connect($fd, sockaddr_in($me->{tcp_server_port}, $me->{tcp_server_ip}) );
        last if $i;		# success
        next if $! == EINTR;	# signal, retry
        last if $! == EISCONN || $! == EALREADY || $! == EINPROGRESS;

        debug("tcp client connect failed: $! ($me->{info})");
        $me->run_callback('error', { cause => 'connect', error => "connect failed: $!" });
        $me->shut();
        return ;
    }

    $me->wantwrite(1);
    return $me;
}

sub _writable {
    my $me = shift;

    # socket will elect as writable once the connect completes
    unless( $me->{_connected} ){
        my $fd = $me->{fd};
        my $i = unpack('L', getsockopt($fd, SOL_SOCKET, SO_ERROR));
        if( $i ){
            my $e = $! = $i;
            debug("tcp client connect failed: $! ($me->{info})");
            $me->run_callback('error', { cause => 'connect', error => "connect failed: $e" });
            $me->shut();
            return;
        }

        debug("tcp client connected $me->{info}");
        $me->{_connected} = 1;
        $me->run_callback('connect', undef);
    }

    $me->SUPER::_writable(@_);
}

sub use_addr_port {
    my $class = shift;

    return @_;
}



1;
