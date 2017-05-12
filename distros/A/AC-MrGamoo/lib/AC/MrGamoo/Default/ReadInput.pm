# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-26 12:01 (EST)
# Function: read input - line by line
#
# $Id: ReadInput.pm,v 1.1 2010/11/01 18:41:54 jaw Exp $

package AC::MrGamoo::Default::ReadInput;
use strict;

# return ( record, eof );

sub readinput {
    my $fd = shift;

    my $line = scalar <$fd>;
    return (undef, 1) unless defined $line;	# eof
    return ($line, 0);
}

1;
