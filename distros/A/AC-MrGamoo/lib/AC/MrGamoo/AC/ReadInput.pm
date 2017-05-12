# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-26 12:04 (EST)
# Function: read input - dancr log format
#
# $Id: ReadInput.pm,v 1.1 2010/11/01 18:41:49 jaw Exp $

package AC::MrGamoo::AC::ReadInput;
use AC::Logfile;
use AC::Daemon;
use AC::MrGamoo::User;
use strict;

our $R;		# exported by AC::MrGamoo::User

sub readinput {
    my $fd = shift;

    my $line = scalar <$fd>;
    return (undef, 1) unless defined $line;

    my $d;
    eval { $d = parse_dancr_log($line); };
    if( $@ ){
        problem("cannot parse data in (" . $R->config('current_file') . "). cannot process\n");
        return ;
    }

    # filter input on date range. we could just as easily filter
    # in 'map', but doing here, behind the scenes, keeps things
    # simpler for the jr. developers writing reports.
    return if $d->{tstart} <  $R->config('start');
    return if $d->{tstart} >= $R->config('end');

    return ($d, 0);
}

1;
