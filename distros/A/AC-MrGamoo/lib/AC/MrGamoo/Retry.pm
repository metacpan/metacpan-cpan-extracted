# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Dec-14 17:23 (EST)
# Function: 
#
# $Id: Retry.pm,v 1.1 2010/11/01 18:41:44 jaw Exp $

package AC::MrGamoo::Retry;
our @ISA = 'AC::DC::Callback';

use AC::MrGamoo::Debug 'retry';
use strict;

# newobj, newargs, tryeach
sub new {
    my $class = shift;

    my $me = bless { @_, tries => 0 }, $class;

    $me->{tryeach}  ||= [];
    $me->{maxtries} ||= @{ $me->{tryeach} };
    return $me;
}

sub start {
    my $me = shift;

    $me->_try();
}

################################################################

sub _try {
    my $me = shift;

    my $a = $me->{tryeach}[ $me->{tries} ];
    my $o = $me->{newobj}->( $a, @{$me->{newargs}} );
    $me->{tries} ++;

    debug("try $me->{tries}");
    return _on_failure(undef, undef, $me) unless $o;

    $o->set_callback( 'on_success', \&_on_success, $me );
    $o->set_callback( 'on_failure', \&_on_failure, $me );

    $o->start();
}

sub _on_success {
    my $x  = shift;
    my $e  = shift;
    my $me = shift;

    debug("all done!");
    return $me->run_callback( 'on_success' );
}

sub _on_failure {
    my $x  = shift;
    my $e  = shift;
    my $me = shift;

    if( $me->{tries} >= $me->{maxtries} ){
        debug("max tries reached. failing");
        return $me->run_callback( 'on_failure' );
    }
    $me->_try();
}




1;
