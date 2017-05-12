# -*- perl -*-
# example readinput

# $Id: readinput.pm,v 1.1 2010/11/01 19:04:22 jaw Exp $

package Local::MrMagoo::ReadInput;
use AC::MrMagoo::User;
use JSON;
use strict;

our $R;		# exported by AC::MrMagoo::User

sub readinput {
    my $fd = shift;	# file handle

    # our file is newline delimted json data

    # read next line
    my $line = scalar <$fd>;
    # end of file?
    return (undef, 1) unless defined $line;

    my $d = json_decode($line);

    # filter input on date range. we could just as easily filter
    # in 'map', but doing it here, behind the scenes, keeps things
    # simpler for the jr. developers writing reports.

    return (undef, 0) if $d->{tstart} <  $R->config('start');
    return (undef, 0) if $d->{tstart} >= $R->config('end');

    return ($d, 0);
}

1;
