# this class is autogenerated.  use make_zones to regenerate
package Data::ICal::TimeZone::Object::America::Scoresbysund;
use strict;
use base qw( Data::ICal::TimeZone::Object );

my $data = join '', <DATA>;
close DATA; # avoid leaking many many filehandles
__PACKAGE__->new->_load( $data );

1;
__DATA__
BEGIN:VCALENDAR
PRODID:-//My Organization//NONSGML My Product//EN
VERSION:2.0
BEGIN:VTIMEZONE
TZID:America/Scoresbysund
X-LIC-LOCATION:America/Scoresbysund
BEGIN:DAYLIGHT
TZOFFSETFROM:-0100
TZOFFSETTO:+0000
TZNAME:EGST
DTSTART:19700329T000000
RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU
END:DAYLIGHT
BEGIN:STANDARD
TZOFFSETFROM:+0000
TZOFFSETTO:-0100
TZNAME:EGT
DTSTART:19701025T010000
RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU
END:STANDARD
END:VTIMEZONE
END:VCALENDAR
