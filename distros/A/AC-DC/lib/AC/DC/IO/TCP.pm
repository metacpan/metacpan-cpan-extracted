# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Mar-27 13:41 (EDT)
# Function: tcp
#
# $Id$

# callbacks:
#  error	=> shut()
#  read_eof	=> shut()
#  read


package AC::DC::IO::TCP;

use AC::DC::Debug 'tcp';
use AC::DC::IO::TCP::Server;
use AC::DC::IO::TCP::Client;

use strict;

our @ISA = 'AC::DC::IO';

my $BUFSIZ = 8192;

sub new {
    my $class = shift;

    my $me = bless {
        @_
    }, $class;

    debug("new tcp");

    return $me;
}

sub start {
    my $me = shift;
    my $fd = shift;

    $me->init($fd);
    $me->wantread(1);
    return $me;
}

sub _readable {
    my $me = shift;

    my $buf;
    my $bs = $me->{rbufsize} || $BUFSIZ;
    my $i = sysread($me->{fd}, $buf, $bs);

    # debug("tcp read $i bytes");

    unless( defined $i ){
        my $e = $!;
        debug("read error - $me->{info}");
        $me->run_callback('error', {
            cause	=> 'read',
            error	=> $e,
        });
        $me->shut();
        return ;
    }
    unless( $i ){
        debug("read eof - $me->{info}");
        $me->run_callback('read_eof', undef);
        $me->shut();
        return ;
    }

    $me->run_callback('read', { data => $buf, size => $i } );

}

1;
