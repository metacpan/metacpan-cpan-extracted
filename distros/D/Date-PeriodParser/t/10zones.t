use Test::More;
use Time::Local;
use Date::PeriodParser;
use POSIX qw( strftime tzset );
use vars qw( $Date::PeriodParser::TestTime );

sub slt { scalar localtime timelocal @_ }
sub sl { scalar localtime shift }
sub tl { timelocal @_ }

# This version of the vague test runs the problematic one ("eleven days ago")
# in a large number of timezones to verify that the DST handling works properly
# in every time zone. (I had a weird bug in which the date was off an hour in
# New South Wales and New Zealand, but nowhere else. This was caused by a 
# missing dereference: the reference was being checked to see if it was a
# daylight savings time, not the time! This happened because the DST change is
# opposite to that for the Northern Hemisphere, and I had not tried South
# America or Africa yet.)

my @zones = qw(
   Africa/Nouakchott
   Africa/Lagos
   Africa/Cairo
   Africa/Khartoum
   Africa/Kinshasa
   Africa/Abidjan
   Africa/Windhoek
   Africa/Blantyre
   Africa/Mogadishu
   Pacific/Samoa
   Pacific/Fiji
   Pacific/Tahiti
   Pacific/Pitcairn
   Pacific/Honolulu
   America/Juneau
   America/Los_Angeles
   America/Phoenix
   America/Denver
   America/Chicago
   America/Indiana
   America/Indianapolis
   America/New_York
   America/Halifax
   America/St_Johns
   America/Glace_Bay
   America/Bogota
   America/Lima
   America/Manaus
   America/Sao_Paulo
   Atlantic/Cape Verde
   Atlantic/Azores
   Atlantic/South_Georgia
   Navajo
   Eire
   Brazil/East
   Brazil/West
   Brazil/Acre
   Brazil/DeNoronha
   CET
   EET
   Antarctica/Casey
   Antarctica/Davis
   Antarctica/Macquarie
   Antarctica/DumontDUrville
   Antarctica/Mawson
   Antarctica/McMurdo
   Antarctica/Palmer
   Antarctica/Rothera
   Antarctica/South_Pole
   Antarctica/Syowa
   Antarctica/Vostok
   Europe/London
   Europe/Paris
   Europe/Bucharest
   Europe/Moscow
   Asia/Yekaterinburg
   Asia/Aden
   Asia/Almaty
   Asia/Anadyr
   Asia/Aqtau
   Asia/Ashgabat
   Asia/Baku
   Asia/Bangkok
   Asia/Bishkek
   Asia/Brunei
   Asia/Karachi
   Asia/Kuching
   Asia/Dubai
   Asia/Ho_Chi_Minh
   Asia/Dili
   Asia/Chongqing
   Asia/Colombo
   Asia/Dhaka
   Asia/Dushanbe
   Asia/Irkutsk
   Asia/Vladivostok
   Asia/Yakutsk
   Asia/Magadan
   Pacific/Norfolk
   Australia/Perth
   Australia/Broken_Hill
   Australia/Brisbane
   Pacific/Noumea
   NZ
);

%tests = (
 "roughly eleven days ago" => [ sl( tl( '00', '00', '12', '30', '2', '102' ) ),
				sl( tl( '59', '59', '11', '3',  '3', '102' ) )
			      ], 
			      # Sat Mar 30 12:00:00 2002
			      # Wed Apr  3 11:59:59 2002
);

plan tests => 2 * (scalar @zones);
foreach my $zone (@zones) {
    $ENV{TZ} = $zone;
    tzset;
    # Set the base time we use for tests (Fri Apr 12 22:01:36 2002)
    # We must do this inside the loop, because we need it done relative to
    # what we just set the timezone to.
    $Date::PeriodParser::TestTime = $base = timelocal( qw(36 1 22 12 3 102 ) );
    my ($s, $mn, $h, $d, $m, $y, $wd, $yd, $dst) = localtime($base);
    my($from, $to);
    foreach $interval (keys %tests) {
      ($from, $to) = parse_period($interval);
      is(sl($from), $tests{$interval}->[0], "'$interval' start");
      is(sl($to),   $tests{$interval}->[1], "'$interval' end");
    }
}
