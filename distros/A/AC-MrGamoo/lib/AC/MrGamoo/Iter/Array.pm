# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-14 12:50 (EST)
# Function: 
#
# $Id: Array.pm,v 1.1 2010/11/01 18:41:55 jaw Exp $

package AC::MrGamoo::Iter::Array;
use AC::MrGamoo::Iter;
our @ISA = 'AC::MrGamoo::Iter';
use strict;

sub new {
    my $class = shift;
    my $array = shift;  # [ [key, data], ...]

    return bless {
        src	=> $array,
    }, $class;
}

sub _nextrow {
    my $me = shift;

    if( $me->{buf} ){
        my $r = $me->{buf};
        delete $me->{buf};
        return $r;
    }
    return unless @{$me->{src}};
    return shift @{$me->{src}};
}


1;
