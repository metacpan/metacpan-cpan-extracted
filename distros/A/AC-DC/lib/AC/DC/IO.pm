# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Mar-27 10:36 (EDT)
# Function: async multiplexed io
#
# $Id$

# callbacks:
#  readable
#  writeable
#  write_buffer_empty
#  timeout
#  error	=> shut()
#  shutdown

package AC::DC::IO;

use AC::DC::Debug 'io';
use AC::DC::IO::TCP;
use AC::DC::IO::UDP;
use AC::DC::IO::Forked;
use AC::DC::Callback;
use AC::DC::Sched;
use Time::HiRes 'time';
use Socket;
use Fcntl;
use POSIX;
use bytes;
use strict;

my $BUFSIZ = 8192;

my $maxfn  = 0;
my $rvec   = "\0\0\0\0";
my $wvec   = "\0\0\0\0";
my @fileno;
my @timeout;
my $exitrequested = 0;


sub import {
    my $pkg   = shift;
    my $param = shift;

    # import a stats monitor?
    if( $param && $param->{monitor} ){
        *add_idle = \&{ $param->{monitor} .'::add_idle' };
    }
}

sub underway {
    return $maxfn;
}

sub closeall {

    for my $x (@fileno){
        close($x->{fd}) if $x && $x->{fd};
    }
}

sub _cleanup {

    for my $f (@fileno){
        next unless $f;
        $f->shut();
    }
    @fileno = ();
    @timeout = ();
}

sub report {

    my $txt;
    for my $x (@fileno){
        $txt .= fileno($x->{fd}) . "\t$x->{info}\n";
    }
    return $txt;
}

sub request_exit { $exitrequested = 1 }

sub init {
    my $me = shift;
    my $fd = shift;

    $me->{fd} = $fd;
    $me->_setnbio();
    my $n = fileno($fd);
    $fileno[ $n ] = $me;
    $maxfn = $n if $n > $maxfn;
    debug("init io fileno $n (/$maxfn) - $me->{info}");
}

sub shut {
    my $me = shift;

    $me->clear_timeout();

    my $fd = $me->{fd};
    return unless $fd;
    my $n  = fileno($fd);
    debug("shutting down fileno $n $me->{info}");
    $me->wantread(0);
    $me->wantwrite(0);

    delete $me->{fd};
    close $fd;
    $fileno[$n] = undef;

    $me->run_callback('shutdown', undef);
    delete $me->{_callback};

    if( $n >= $maxfn ){
        while( $maxfn && !$fileno[$maxfn] ){ $maxfn -- }
    }
}

sub wantread {
    my $me = shift;
    my $v  = shift;

    return unless defined $me->{fd};
    $me->{_wantread} = $v;
    my $n = fileno($me->{fd});
    vec($rvec,$n,1) = $v ? 1 : 0;
    return ;
}

sub wantwrite {
    my $me = shift;
    my $v  = shift;

    return unless defined $me->{fd};
    $me->{_wantwrite} = $v;
    my $n = fileno($me->{fd});
    vec($wvec,$n,1) = $v ? 1 : 0;
    return ;
}

sub timeout_abs {
    my $me = shift;
    my $t  = shift;

    $me->clear_timeout() if $me->{_timeout};
    return unless $t;

    $me->{_timeout} = $t;

    my $i = 0;
    foreach my $x (@timeout){
        last if $x && $x->{_timeout} > $t;
        $i++;
    }

    splice @timeout, $i, 0, $me;

    return ;
}

sub timeout_rel {
    my $me = shift;
    my $to = shift;

    $to += $^T if $to;
    $me->timeout_abs( $to );
}

sub clear_timeout {
    my $me = shift;

    delete $me->{_timeout};
    @timeout = grep { $_ != $me } @timeout;
    return ;
}

################################################################
# buffered writing

sub write {
    my $me   = shift;
    my $data = shift;

    $me->{_wbuffer} .= $data;
    $me->wantwrite(1);
}

sub write_and_shut {
    my $me = shift;

    $me->write(@_);
    $me->set_callback('write_buffer_empty', \&shut);
}


sub _writable {
    my $me = shift;

    return $me->run_callback('writeable', undef) unless $me->{_wbuffer};

    my $len = length($me->{_wbuffer});
    my $bs = $me->{wbufsize} || $BUFSIZ;
    $len = $bs if $len > $bs;
    my $buf = substr($me->{_wbuffer}, 0, $len);
    my $i = syswrite( $me->{fd}, $buf );

    if( defined $i ){
        # debug("wrote $i bytes to $me->{info}");
        substr($me->{_wbuffer}, 0, $i) = '';
        if( length($me->{_wbuffer}) ){
            $me->timeout_rel( $me->{writebuf_timeout} ) if $me->{writebuf_timeout};
        }else{
            $me->wantwrite(0);
            $me->run_callback('write_buffer_empty', undef);
        }
    }else{
        my $e = $!;
        debug( "write failed ($e) for $me->{info}");
        $me->run_callback('error', {
            cause	=> 'write',
            error	=> $e,
        });
        $me->shut();
    }
}

################################################################

sub _readable {
    my $me = shift;

    $me->run_callback('readable', undef);
}

sub _timeout {
    my $me = shift;

    debug("io - timeout $me->{info}");
    $me->run_callback('timeout', undef);
}

################################################################

sub _setnbio {
    my $me = shift;

    my $fd = $me->{fd};
    fcntl($fd, F_SETFL, O_NDELAY);
}

################################################################

sub _oneloop {

    my $t0 = time();
    $^T = $t0;
    my $r = $rvec;
    my $w = $wvec;

    my $t;
    if( @timeout ){
        $t = $timeout[0]{_timeout} - $^T;
        $t = 0 if $t < 0;
    }

    my $i = select($r, $w, undef, $t);

    if( $i == -1 ){
        return if $! == EINTR;
        fatal( "select failed: $!" );
    }

    my $t1 = time();
    $^T = $t1;

    # dispatch
    for my $n (0 .. $maxfn){
        if( vec($r, $n, 1) && vec($rvec, $n, 1) ){
            my $x = $fileno[$n];
            # debug("fileno $n ($x->{info}) is readable");
            $x->_readable();
        }
        if( vec($w, $n, 1) && vec($wvec, $n, 1) ){
            my $x = $fileno[$n];
            # debug("fileno $n ($x->{info}) is writeable");
            $x->_writable();
        }
    }

    # timeouts
    while(@timeout && $timeout[0]{_timeout} <= $^T){
        my $x = shift @timeout;
        debug("timed out $x->{info}");
        delete $x->{_timeout};
        $x->_timeout();
    }

    my $t2 = time();

    # track idle/busy time
    # debug("add idle? $t0, $t1, $t2 " . (defined &add_idle ? 'f' : '!'));
    add_idle( $t1 - $t0, $t2 - $t0 ) if defined &add_idle;
}

sub mainloop {

    while(1){
        _oneloop();
        last if $exitrequested;
    }
    _cleanup();
}

1;

