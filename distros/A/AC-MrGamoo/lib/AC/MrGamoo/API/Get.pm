# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-19 18:21 (EST)
# Function: 
#
# $Id: Get.pm,v 1.1 2010/11/01 18:41:51 jaw Exp $

package AC::MrGamoo::API::Get;
use AC::MrGamoo::Debug 'api_get';
use AC::MrGamoo::Config;
use AC::MrGamoo::API::Simple;
use AC::MrGamoo::Protocol;
use AC::MrGamoo::Scriblr;
use AC::SHA1File;
use Fcntl;
use POSIX;

use strict;

sub handler {
    my $class   = shift;
    my $io      = shift;
    my $proto   = shift;
    my $req     = shift;
    my $content = shift;

    return unless $proto->{want_reply};
    in_background( \&_get_file, $io, $proto, $req, $content );
}

sub _get_file {
    my $io      = shift;
    my $proto   = shift;
    my $req     = shift;
    my $content = shift;

    my $file = filename($req->{filename});
    my $fd = $io->{fd};
    fcntl($fd, F_SETFL, 0);	# unset nbio

    return nbfd_reply(404, "not found", $fd, $proto, $req) unless -f $file;
    open(F, $file) || return nbfd_reply(500, 'error', $fd, $proto, $req);
    my $size = (stat($file))[7];
    my $sha1 = sha1_file($file);

    debug("get file '$file' size $size");

    # send header
    my $gb  = ACPScriblReply->encode( { status_code => 200, status_message => 'OK', hash_sha1 => $sha1 } );
    my $hdr = AC::MrGamoo::Protocol->encode_header(
        type		=> $proto->{type},
        msgidno		=> $proto->{msgidno},
        is_reply	=> 1,
        data_length	=> length($gb),
        content_length	=> $size,
       );
    my $buf = $hdr . $gb;

    syswrite( $fd, $buf );

    # stream
    AC::MrGamoo::Protocol->sendfile($fd, \*F, $size);
}


1;
