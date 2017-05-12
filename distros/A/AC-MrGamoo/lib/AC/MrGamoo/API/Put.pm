# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-19 18:21 (EST)
# Function: 
#
# $Id: Put.pm,v 1.1 2010/11/01 18:41:52 jaw Exp $

package AC::MrGamoo::API::Put;
use AC::MrGamoo::Debug 'api_put';
use AC::MrGamoo::Config;
use AC::MrGamoo::API::Simple;
use AC::SHA1File;
use AC::MrGamoo::Protocol;
use AC::MrGamoo::Scriblr;
use File::Path;
use POSIX;

use strict;

sub handler {
    my $class   = shift;
    my $io      = shift;
    my $proto   = shift;
    my $req     = shift;
    my $content = shift;

    if( conf_value('scriblr') =~ /no|off/i ){
        reply( 500, 'Error', $io, $proto, $req );
        return;
    }

    in_background( \&_put_file, $io, $proto, $req, $content );
}

sub _put_file {
    my $io      = shift;
    my $proto   = shift;
    my $req     = shift;
    my $content = shift;

    my $file = filename($req->{filename});
    my $fd = $io->{fd};
    fcntl($fd, F_SETFL, 0);	# unset nbio

    my($dir) = $file =~ m|^(.+)/[^/]+$|;

    # mkpath
    eval{ mkpath($dir, undef, 0755) };

    # open tmp
    my $tmp = "$file.tmp";
    unless( open(F, "> $tmp") ){
        problem("open file failed: $!");
        return nbfd_reply(500, 'error', $fd, $proto, $req);
    }

    # read + write
    my $size = $proto->{content_length};
    my $sha1 = $req->{hash_sha1};

    verbose("put file '$file' size $size");

    if( $content ){
        syswrite( F, $content );
        $size -= length($content);
    }

    eval {
        my $chk = AC::MrGamoo::Protocol->sendfile(\*F, $fd, $size, 10);
        close F;
        die "file size mismatch\n" unless (stat($tmp))[7] == $proto->{content_length};
        die "SHA1 check failed\n" if $sha1 && $sha1 ne $chk;
    };
    if(my $e = $@){
        unlink $tmp;
        verbose("error: $e");
        nbfd_reply(500, 'error', $fd, $proto, $req);
        return;
    }

    rename $tmp, $file;

    nbfd_reply(200, 'OK', $fd, $proto, $req);
}

1;
