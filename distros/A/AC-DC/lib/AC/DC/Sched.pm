# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Mar-27 11:47 (EDT)
# Function: run things periodically
#
# $Id$

package AC::DC::Sched;
use AC::DC::Debug 'sched';
use Carp 'carp';
use strict;

our @ISA = qw(AC::DC::IO);

sub new {
    my $class = shift;
    my $p = { @_ };
    # { info, time, freq, phi, func, args }

    my $me = bless {
        sched	=> $p,
    }, $class;

    $p->{info} ||= 'scheduled function';
    $p->{phi} = rand($p->{freq}) if $p->{freq} && !defined($p->{phi});
    $p->{time} ||= $p->{freq} + $p->{phi} + $^T if $p->{freq} && !$p->{time};
    carp "cannot schedule, no time, no freq.\n" unless $p->{time};

    $me->{info} = $p->{info};

    debug("installing scheduled func ($me->{info})");
    $me->_sched();

    return $me;
}

sub _sched {
    my $me = shift;

    $me->timeout_abs( $me->{sched}{time} );
}

sub _resched {
    my $me = shift;
    while( $me->{sched}{time} < $^T ){ $me->{sched}{time} += $me->{sched}{freq} }
    $me->_sched();
}

sub _timeout {
    my $me = shift;

    # run specified func
    debug("running scheduled func ($me->{info})");
    $me->{sched}{func}->($me->{sched}{args});
    $me->_resched() if $me->{sched}{freq};
}


1;
