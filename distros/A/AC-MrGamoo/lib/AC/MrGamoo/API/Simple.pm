# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-12 18:15 (EST)
# Function: common to most API handlers
#
# $Id: Simple.pm,v 1.1 2010/11/01 18:41:52 jaw Exp $

package AC::MrGamoo::API::Simple;
use AC::MrGamoo::Protocol;
use AC::MrGamoo::Debug 'api';
use AC::Import;
use POSIX;

require 'AC/protobuf/std_reply.pl';
use strict;

our @EXPORT = qw(reply on_success on_failure in_background nbfd_reply);

sub reply {
    my $code    = shift;
    my $msg     = shift;
    my $io      = shift;
    my $proto   = shift;
    my $req     = shift;

    unless( $proto->{want_reply} ){
        $io->shut();
        return;
    }

    my $response = AC::MrGamoo::Protocol->encode_reply( {
        type            => $proto->{type},
        msgid           => $proto->{msgid},
        is_reply        => 1,
    }, {
        status_code	=> $code,
        status_message	=> $msg,
    } );

    debug("sending $code reply for $proto->{type} on $io->{info}");
    $io->write_and_shut( $response );
}

sub nbfd_reply {
    my $code    = shift;
    my $msg     = shift;
    my $fd      = shift;
    my $proto   = shift;
    my $req     = shift;

    return unless $proto->{want_reply};

    my $response = AC::MrGamoo::Protocol->encode_reply( {
        type            => $proto->{type},
        msgid           => $proto->{msgid},
        is_reply        => 1,
    }, {
        status_code	=> $code,
        status_message	=> $msg,
    } );

    debug("sending $code reply for $proto->{type} (from bkg)");
    syswrite( $fd, $response );
}

sub on_success {
    my $x  = shift;
    my $e  = shift;
    my $io      = shift;
    my $proto   = shift;
    my $req     = shift;

    reply( 200, 'OK', $io, $proto, $req );
}

sub on_failure {
    my $x  = shift;
    my $e  = shift;
    my $io      = shift;
    my $proto   = shift;
    my $req     = shift;

    reply( 500, 'Error', $io, $proto, $req );
}


sub in_background {
    my $func    = shift;
    my $io      = shift;
    my $proto   = shift;
    my $req     = shift;

    my $pid = fork();

    if( !defined($pid) ){
        problem("cannot fork: $!");
        reply( 500, 'Error', $io, $proto, $req );
        return ;
    }elsif( $pid ){
        # parent
        $io->shut();
        waitpid $pid, 0;
        return;
    }else{
        # child
        my $gpid = fork();

        if( $gpid ){
            # parent
            _exit(0);
        }else{
            # orphaned child
            eval {
                $func->($io, $proto, $req, @_);
            };
            if(my $e = $@){
                chomp $e;
                verbose("child error: $e");
                _exit(1);
            }
            _exit(0);
        }
    }
}

1;
