#!perl 

=head1 NAME

sample001.pl	- How to use this module

=head1 DESCRIPTION

This is a sample program that prints a Shabbat timetable for the
next few weeks.

=cut

use strict;
use warnings;

use lib qw(../lib);

use DateTime;
use DateTime::Duration;
use DateTime::Calendar::Hebrew;
use DateTime::Event::Jewish::Sunrise ;
use DateTime::Event::Jewish::Parshah qw(nextShabbat parshah);

my $place = [[51, 34, 57], [0,-13,-28], 'Europe/London']; # Actually, Hendon Central

my $location	= DateTime::Event::Jewish::Sunrise->new(@$place);

# If you want to use this in a CGI, you will
# probably want to lose this loop.
my $count = 0;
for (my $shabbat	= nextShabbat(DateTime->today);
	$count++ < 8;
	$shabbat	= nextShabbat($shabbat)) {

    my $friday	= $shabbat - DateTime::Duration->new(days=>1);

    my $candles	= $location->kabbalatShabbat($friday);
    my $night	= $location->motzeiShabbat($shabbat);

    # In Adar of a non-leap year this will print 'AdarI' instead of
    # just 'Adar'. This is a bug in DateTime::Calendar::Hebrew.
    printf "Shabbat %d %s %d %s\n", $shabbat->day,
	    $shabbat->month_name, $shabbat->year, parshah($friday);
    printf "Kabbalat Shabbat: %02d:%02d\n", $candles->hour, $candles->minute;
    printf "Motzei Shabbat: %02d:%02d\n", $night->hour, $night->minute;

    my $mevarchin	= $shabbat->day() > 22;
    # A day that is definitely in next month
    my $nextMonth	= $shabbat+DateTime::Duration->new(days=>8);
    # No Mevarchin HaCodesh for Tishrei
    if ($mevarchin && $nextMonth->month != 7) {
	print "Mevarchin hachodesh: ", $nextMonth->month_name, "\n";
    }

    # Which days is Rosh Chodesh?
    if ($mevarchin) {
	my $roshChodesh1	 =
	$shabbat->clone->set(day=>DateTime::Calendar::Hebrew::_LastDayOfMonth($shabbat->year,$shabbat->month));
	my $roshChodesh	= $roshChodesh1->day_name;
	if ($roshChodesh1->day == 30) {
	    my $roshChodesh2	=
	    $roshChodesh1+DateTime::Duration->new(days=>1);
	    $roshChodesh	.= "/". $roshChodesh2->day_name;
	}
	print "Rosh Chodesh: $roshChodesh\n";
    }

    print "\n";
}	# end of outer loop

exit 0;
