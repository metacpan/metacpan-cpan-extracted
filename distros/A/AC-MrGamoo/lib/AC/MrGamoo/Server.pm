# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Mar-30 10:34 (EDT)
# Function: server side
#
# $Id: Server.pm,v 1.3 2011/01/07 22:34:00 jaw Exp $

package AC::MrGamoo::Server;
use AC::MrGamoo::Debug 'server';
use AC::MrGamoo::Protocol;
use AC::MrGamoo::Protocol;

use AC::MrGamoo::API::HB;
use AC::MrGamoo::API::Xfer;
use AC::MrGamoo::API::Del;
use AC::MrGamoo::API::Chk;
use AC::MrGamoo::API::Get;
use AC::MrGamoo::API::Put;
use AC::MrGamoo::API::JobCreate;
use AC::MrGamoo::API::JobAbort;
use AC::MrGamoo::API::TaskCreate;
use AC::MrGamoo::API::TaskAbort;
use AC::MrGamoo::API::TaskStatus;
use AC::MrGamoo::API::XferStatus;

use strict;

our @ISA = 'AC::DC::IO::TCP';

my $HDRSIZE = AC::MrGamoo::Protocol->header_size();
my $TIMEOUT = 2;

my %HANDLER = (
    heartbeat_request   => 'AC::MrGamoo::API::HB',
    scribl_get		=> 'AC::MrGamoo::API::Get',
    scribl_put		=> 'AC::MrGamoo::API::Put',
    scribl_del		=> 'AC::MrGamoo::API::Del',
    scribl_stat		=> 'AC::MrGamoo::API::Chk',

    mrgamoo_status	=> 'AC::MrGamoo::Kibitz::Server',
    mrgamoo_filexfer	=> 'AC::MrGamoo::API::Xfer',
    mrgamoo_filedel	=> 'AC::MrGamoo::API::Del',
    mrgamoo_jobcreate	=> 'AC::MrGamoo::API::JobCreate',
    mrgamoo_taskcreate	=> 'AC::MrGamoo::API::TaskCreate',
    mrgamoo_jobabort	=> 'AC::MrGamoo::API::JobAbort',
    mrgamoo_taskabort	=> 'AC::MrGamoo::API::TaskAbort',
    mrgamoo_taskstatus	=> 'AC::MrGamoo::API::TaskStatus',
    mrgamoo_xferstatus	=> 'AC::MrGamoo::API::XferStatus',

    http		=> \&http,
    # ...

);

my %HTTP = (
    loadave		=> \&AC::MrGamoo::Stats::http_load,
    stats		=> \&AC::MrGamoo::Stats::http_stats,
    status		=> \&AC::MrGamoo::Stats::http_status,
    peers		=> \&AC::MrGamoo::Kibitz::Peers::report,
    jobs		=> \&AC::MrGamoo::Job::report,
    tasks		=> \&AC::MrGamoo::Task::report,
    xfers		=> \&AC::MrGamoo::Xfer::report,
);

sub new {
    my $class = shift;
    my $fd    = shift;
    my $ip    = shift;

    unless( $AC::MrGamoo::CONF->check_acl( $ip ) ){
        verbose("rejecting connection from $ip");
        return;
    }

    my $me = $class->SUPER::new( info => 'tcp mrgamoo server', from_ip => $ip );

    $me->start($fd);
    $me->timeout_rel($TIMEOUT);
    $me->set_callback('read',    \&read);
    $me->set_callback('timeout', \&timeout);
}

sub timeout {
    my $me = shift;

    debug("connection timed out");
    $me->shut();
}

sub read {
    my $me  = shift;
    my $evt = shift;

    my($proto, $data, $content) = read_protocol_no_content( $me, $evt );
    return unless $proto;

    # dispatch request
    my $h = $HANDLER{ $proto->{type} };

    unless( $h ){
        verbose("unknown message type: $proto->{type}");
        $me->shut();
        return;
    }

    eval {
        $data = AC::MrGamoo::Protocol->decode_request($proto, $data) if $data && $proto->{type} ne 'http';
    };
    if(my $e = $@ ){
        problem("cannot decode request: $e");
        $me->shut();
        return;
    }

    debug("handling request - $proto->{type}");

    if( ref $h ){
        $h->( $me, $proto, $data, $content );
    }else{
        $h->handler( $me, $proto, $data, $content );
    }
}

sub http {
    my $me    = shift;
    my $proto = shift;
    my $url   = shift;

    $url =~ s|^/||;
    $url =~ s/%(..)/chr(hex($1))/eg;
    my($base) = split m|/|, $url;

    debug("http get $base");
    my $f = $HTTP{$base};
    $f ||= \&http_notfound;
    my( $content, $code, $text ) = $f->($url);
    $code ||= 200;
    $text ||= 'OK';

    my $res = "HTTP/1.0 $code $text\r\n"
      . "Server: AC/MrGamoo\r\n"
      . "Connection: close\r\n"
      . "Content-Type: text/plain; charset=UTF-8\r\n"
      . "Content-Length: " . length($content) . "\r\n"
      . "\r\n"
      . $content ;

    $me->write_and_shut($res);
}

################################################################

sub http_notfound {
    my $url = shift;

    return ("404 NOT FOUND\nThe requested url /$url was not found on this server.\nSo sorry.\n\n", 404, "Not Found");
}


1;
