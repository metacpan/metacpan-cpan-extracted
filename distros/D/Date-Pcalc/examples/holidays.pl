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
use Date::Pcalendar::Year;
use Date::Pcalc::Object qw(:ALL);

sub print_holidays
{
    my($year) = shift_year(\@_);
    my($lang) = shift;
    my($prof) = shift;
    my($newl) = Decode_Language($lang);
    my($full,$half,$last,$oldl,$oldf,$i,$date,@labels,$dow,$day);

    die "No such language '$lang'" unless ($newl);

    die "No such calendar profile '$prof'"
        unless (exists $Profiles->{$prof});

    $year = Date::Pcalendar::Year->new( $year, $Profiles->{$prof} );

    $full = $year->vec_full();
    $half = $year->vec_half();
    $last = $year->val_days();

    $oldl = Language($newl);
    $oldf = Date::Pcalc->date_format(1);

    for ( $i = 0; $i < $last; $i++ )
    {
        $date = $year->index2date($i);
        @labels = $year->labels($date);
        if (@labels > 1)
        {
            $dow = substr(shift(@labels),0,3);
            $day = $full->contains($i) ? "+" : $half->contains($i) ? "#" : "-";
            print "$dow $date $day ", join(", ", @labels), "\n";
        }
    }

    Language($oldl);
    Date::Pcalc->date_format($oldf);
}

unless (@ARGV == 3)
{
    die "Usage: perl holidays.pl YEAR LANGUAGE PROFILE\n";
}

print_holidays( @ARGV );

__END__

