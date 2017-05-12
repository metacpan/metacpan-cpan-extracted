# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-14 12:46 (EST)
# Function: iterate over a file
#
# $Id: File.pm,v 1.1 2010/11/01 18:41:55 jaw Exp $

package AC::MrGamoo::Iter::File;
use AC::MrGamoo::Iter;
use JSON;
our @ISA = 'AC::MrGamoo::Iter';
use strict;

sub new {
    my $class = shift;
    my $fd    = shift;
    my $pf    = shift;

    return bless {
        fd	 => $fd,
        progress => $pf,
    }, $class;
}

sub _nextrow {
    my $me = shift;

    if( $me->{buf} ){
        my $r = $me->{buf};
        delete $me->{buf};
        return $r;
    }

    my $fd = $me->{fd};
    my $l  = scalar <$fd>;
    return unless $l;
    $me->{progress}->();
    return decode_json($l);
}


1;
