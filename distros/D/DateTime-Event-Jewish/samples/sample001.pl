#!perl 

=head1 NAME

sample001.pl	- How to use this module

=head1 DESCRIPTION

This is a sample program that prints out a full-year timetable,
at 3-day intervals, for four places in the world.

=cut

use strict;
use warnings;

use lib qw(../lib);

use DateTime;
use DateTime::Duration;
use DateTime::Calendar::Hebrew;
use DateTime::Event::Jewish::Declination qw(%Declination);
use DateTime::Event::Jewish::Sunrise qw(@months);


    # The fields are: latitude, longitude, timezone
    my %places= (
#	'London' => [[51, 34, 57], [0,-13,-28], 'Europe/London'], # Actually, Hendon Central
#	'Jerusalem' => [[31, 47, 00], [35, 13,0], 'Asia/Jerusalem'],
#	'State College' => [[40,47,29],[-77, -51, -31], 'America/New_York'],
#	'Vancouver, BC' => [[49,16,0], [-123,-7,0], 'America/Vancouver'],
#	"Umea, Sweden"=>  [[63, 50, 0], [20,15, 0], "Europe/Stockholm"],
	"Lisbon, Portugal"=>[[39,0,0],[-9,-12,0], "Europe/Lisbon"],
	"Porto Alegre, Brazil"=>[[-31, -5,0],[-51, -10,0], "Brazil/East"],
    );


# Testing code
    foreach my $p (keys(%places)) {
	my $phi	= $places{$p}[0];		# arrayref
	my $lambda	= $places{$p}[1];	# arrayref
	my $standardMeridian= $places{$p}[2];	# zone name
	my $place	=
	DateTime::Event::Jewish::Sunrise->new($phi, $lambda, $standardMeridian);
	my ($longdeg, $longmin, $longsec)	= @{$places{$p}[1]};
	printf "\n%s\t%d:%d:%d  %d:%d:%d\n" , $p, $phi->[0],
		$phi->[1], $phi->[2], $longdeg, $longmin, $longsec ;
	print "\tSunrise\tNoon\tShkia\tCandles\tMotzei Shabbat\n";


	my $count	= 2;
	foreach my $mon ( 1 .. 12) {

	    my $M = $months[$mon-1];
	    # The size of each array tells us, indirectly, the
	    # number of days in the month (except February).
	    my $limit	= @{$Declination{$M}};
	    foreach my $d (1 .. $limit) {
		next if $mon==2 && $d>28;
		$count++;
		next if ($count%3);
		my $date	= DateTime->today;
		$date->set_month($mon);
		$date->set_day($d);
		my $halfDay	= $place->halachicHalfDay($date);
		my $rise = $place->netzHachama($date);
		my $noon	= $place->localnoon($date);
		my $set	= $place->shkia($date)   ;
		my $shabbat	= $place->kabbalatShabbat($date) ;
		my $night	= $place->motzeiShabbat($date) ;
		printf "%2d/%s" , $d,$M;
		foreach my $t ($rise, $noon, $set, $shabbat, $night){
		    my ($h, $m) 	= ($t->hour, $t->min);
		    printf "\t%02d:%02d" , $h, $m;
		}
		printf("\t%d", $halfDay);
		print "\n";
	    }		# end of day
	}		# end of month
	print "\f";
    }			# end of place

exit 0;
