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
use Date::Pcalc::Object qw(:all);

Date::Pcalc->date_format(2);

$time = time;

$date = Date::Pcalc->new(Today_and_Now(0));
print "Today_and_Now(0)          = $date\n";

$date = Date::Pcalc->new(Today_and_Now(1));
print "Today_and_Now(1)          = $date\n";

$date = Date::Pcalc->new( 0, Add_Delta_DHMS( 1970,1,1, 0,0,0, 0,0,0,$time ) );
print "Add_Delta_DHMS($time) = $date\n";

$date = Date::Pcalc->gmtime(time);
print "gmtime($time)         = $date\n";

$date->localtime(time);
print "localtime($time)      = $date\n";

__END__

