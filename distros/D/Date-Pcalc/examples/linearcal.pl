#!perl -w

###############################################################################
##                                                                           ##
##    Copyright (c) 2001 - 2009 by Steffen Beyer.                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This program is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

BEGIN { eval { require bytes; }; }
use strict;

use Date::Pcalendar::Profiles qw( $Profiles );
use Date::Pcalendar;
use Date::Pcalc::Object qw(:ALL);

sub print_linear_calendar
{
    my(@start) = shift_date(\@_);
    my(@stop)  = shift_date(\@_);
    my($lang)  = shift;
    my($prof)  = shift;
    my($newl)  = Decode_Language($lang);
    my($cal,$start,$stop,$oldl,$oldf,@labels,$dow,$day);

    die "No such language '$lang'" unless ($newl);

    die "No such calendar profile '$prof'"
        unless (exists $Profiles->{$prof});

    $cal   = Date::Pcalendar->new( $Profiles->{$prof} );
    $start = Date::Pcalc->new(@start);
    $stop  = Date::Pcalc->new(@stop);

    $oldl = Language($newl);
    $oldf = Date::Pcalc->date_format(1);

    while ($start <= $stop)
    {
        @labels = $cal->labels($start);
        $dow = substr(shift(@labels),0,3);
        $day = $cal->is_full($start) ? "+" : $cal->is_half($start) ? "#" : "-";
        print "$dow $start $day ", join(", ", @labels), "\n";
        $start++;
    }

    Language($oldl);
    Date::Pcalc->date_format($oldf);
}

unless (@ARGV == 8)
{
    die "Usage: perl linearcal.pl YEAR1 MONTH1 DAY1 YEAR2 MONTH2 DAY2 LANGUAGE PROFILE\n";
}

print_linear_calendar( @ARGV );

__END__

