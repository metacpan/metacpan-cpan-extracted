# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-18 13:20 (EST)
# Function: send messages to end-user console
#
# $Id: EUConsole.pm,v 1.1 2010/11/01 18:41:41 jaw Exp $

package AC::MrGamoo::EUConsole;
use AC::MrGamoo::Debug 'euconsole';
use AC::MrGamoo::MySelf;
use AC::Daemon;
use AC::MrGamoo::Protocol;
use Socket;
use strict;


sub new {
    my $class  = shift;
    my $jobid  = shift;
    my $console = shift;	# ipaddr:port

    return bless {}, $class unless $console;

    # open socket to end-user console session, if requested
    my($addr, $port) = split /:/, $console;
    my $ip = inet_aton($addr);

    my $fd;
    my $i = socket($fd, PF_INET, SOCK_DGRAM, 0);
    $i = connect( $fd, sockaddr_in($port, $ip) );
    unless( $i ){
        verbose("cannot connect to user console: $!");
        return;
    }

    return bless {
        fd 	=> $fd,
        jobid	=> $jobid,
        msgid 	=> (time() & 0xFFFF),
    }, $class;
}

sub send_msg {
    my $me = shift;
    my $type = shift;
    my $msg  = shift;

    my $fd = $me->{fd};
    return unless $fd;

    my $req = AC::MrGamoo::Protocol->encode_request( {
        type		=> 'mrgamoo_diagmsg',
        want_reply	=> 0,
        msgid		=> $me->{msgid}++,
    }, {
        jobid		=> $me->{jobid},
        server_id	=> my_server_id(),
        type		=> $type,
        msg		=> $msg,
    } );

    send $fd, $req, 0;
}

1;
