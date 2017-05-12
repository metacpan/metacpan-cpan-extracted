# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Mar-27 11:40 (EDT)
# Function: debugging + log msgs
#
# $Id$

package AC::DC::Debug;
use AC::Daemon;
use strict;

my $config;
my $debugall;

sub init {
    shift;
    $debugall = shift;
    $config   = shift;
}

sub _tagged_debug {
    my $tag = shift;
    my $msg = shift;

    if( $config && $config->{config} ){
        return unless $config->{config}{debug}{$tag} || $config->{config}{debug}{all} || $debugall;
    }else{
        return unless $debugall;
    }

    debugmsg( "$tag - $msg" );
}

sub import {
    my $class  = shift;
    my $tag    = shift;		# use AC::DC::Debug 'tag';
    my $caller = caller;

    no strict;
    if( $tag ){
        # export a curried debug (with the specified tag) to the caller
        *{$caller . '::debug'} = sub { _tagged_debug($tag, @_) };
    }

    for my $f qw(verbose problem fatal){
        no strict;
        *{$caller . '::' . $f} = $class->can($f);
    }
}

1;
