# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-14 15:32 (EST)
# Function: redirect filehandle to function
#
# $Id: TieIO.pm,v 1.1 2010/11/01 18:42:00 jaw Exp $

package AC::MrGamoo::Submit::TieIO;
use strict;

sub TIEHANDLE {
    my $class = shift;
    my $func  = shift;

    return bless{ func => $func }, $class;
}

sub PRINT {
    my $me = shift;

    return unless $me->{func};
    $me->{func}->( @_ );
}

sub PRINTF {
    my $me = shift;

    return unless $me->{func};
    my $fmt = shift;
    $me->{func}->( sprintf($fmt, @_) );
}

1;
