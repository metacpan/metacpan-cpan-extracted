# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Mar-27 10:41 (EDT)
# Function: event callback mixin
#
# $Id$

package AC::DC::Callback;
use AC::DC::Debug 'callback';
use AC::Import;
use strict;

our @EXPORT = qw(set_callback clear_callback run_callback);


sub set_callback {
    my $me  = shift;
    my $cb  = shift;
    my $fnc = shift;

    $me->{_callback}{$cb} = { func => $fnc, args => [@_] };
}

sub clear_callback {
    my $me  = shift;
    my $cb  = shift;

    delete $me->{_callback}{$cb};
}

# call the specified callback function
sub run_callback {
    my $me  = shift;
    my $cb  = shift;
    my $evt = shift;

    my $c = $me->{_callback}{$cb};
    unless( $c ){
        debug("no callback for $cb ($me->{info})");
        return;
    }
    debug("running callback $cb ($me->{info})");

    return $c->{func}->($me, $evt, @{$c->{args}});
}


1;
