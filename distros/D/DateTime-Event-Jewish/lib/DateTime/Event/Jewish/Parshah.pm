package DateTime::Event::Jewish::Parshah;

=head1 NAME

DateTime::Event::Jewish::Parshah - Calculate leyning for next
shabbat

=head1 SYNOPSIS

 use DateTime::Event::Jewish::Parshah qw(parshah);

 my $parshah	= parshah(DateTime->today, $israel);

=head1 DESCRIPTION

Returns either a parshah name or a yom tov name for the Shabbat
after the date supplied. The optional I<israel> flag specifies
whether to calculate the leyning for Israel or for the diaspora.


=cut

use strict;
use warnings;
use DateTime;
use DateTime::Duration;
use DateTime::Calendar::Hebrew;
use DateTime::Event::Jewish::Yomtov qw(@festival);
use DateTime::Event::Jewish::Sedrah qw(@sedrah);
use base qw(Exporter);
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(nextShabbat parshah);
our $VERSION = '0.01';

our %YomTovMap;
our %IsraelYomTovMap;
our %YomTovYear;

=head3 _initYomTov($year)

Internal function that initialises the yom tov table for the
year in question.

=cut

sub _initYomTov {
    my $year	= shift;
    return if $YomTovYear{$year};
    my $f	= DateTime::Calendar::Hebrew->today;
    foreach my $yt (@festival) 
    {
	my ($name, $day, $month, $diaspora)	= @$yt;
	$f->set(year=>$year, month=>$month, day=>$day);
	my $fDays	= $f->{rd_days};
	$YomTovMap{$fDays}	= $name;
	$IsraelYomTovMap{$fDays}	= $name unless $diaspora;
    }
    $YomTovYear{$year}	= 1;
}



# (C) Raphael Mankin 2009

# The algorithm for calculating the  weekly parshah is taken
# from http://individual.utoronto.ca/kalendis/hebrew/parshah.htm

=head3 nextShabbat($date)

Returns the next Shabbat which is strictly after $date. The
returned object is a Hewbrew date.

$date is some sort of DateTime object; it does not matter which.

=cut

sub nextShabbat {
    my $date	= DateTime->from_object(object=>shift)->add(days=>1);
    while ($date->day_of_week != 6) {
	$date->add(days=>1);
    }
    return DateTime::Calendar::Hebrew->from_object(object=>$date);
}

=head3 parshah($date ,[$israel])

Returns the parshah name or a yomtov name for the Shabbat
strictly after $date.

$date is some sort of DateTime object; it does not matter which.

$israel is an optional flag to indicate that we should use the
logic for Israel rather than the Diaspora.

See http://individual.utoronto.ca/kalendis/hebrew/parshah.htm for
the logic of this code.

=cut

sub parshah {
    my $today = shift;
    my $israel	= shift || 0;

    my $targetShabbat	= nextShabbat($today);
    my $thisYear        = $targetShabbat->year();
    _initYomTov($thisYear-1);
    _initYomTov($thisYear);
    _initYomTov($thisYear+1);
    if ($israel) {
	if (exists $IsraelYomTovMap{$targetShabbat->{rd_days}}) {
	    return $IsraelYomTovMap{$targetShabbat->{rd_days}};
	}
    } else {
	if (exists $YomTovMap{$targetShabbat->{rd_days}}) {
	    return $YomTovMap{$targetShabbat->{rd_days}};
	}
    }
    my $thisMonth       = $targetShabbat->month();
    my $thisDay         = $targetShabbat->day();
    # Get the date of last Simchat Torah, bearing in mind that
    # the year begins in Nissan.
    my $simchatTorah =
    DateTime::Calendar::Hebrew->new(month=>7,
	    day=>23-$israel,
	    year=>($thisMonth==7 && $thisDay<23-$israel )?  $thisYear-1: $thisYear);

    # The next few dates only matter if we are in the right part of the year.
    # Otherwise, the dates are not used and it is of no
    # consequence which year we calculate. The calculation is
    # relative to 'workingShabbat', not relative to
    # 'targetShabbat'.
    #
    # The date of Pesach
    my $pesach = DateTime::Calendar::Hebrew->new(month=>1, day=>15,
			    year=>($thisMonth==7 ? $thisYear-1: $thisYear));
    # The date of  9 Av
    my $tishaBAv = DateTime::Calendar::Hebrew->new(month=>5, day=>9, 
			year=>($thisMonth==7 ? $thisYear-1: $thisYear) );
    # The date of RoshHashanah
    my $RoshHashanah= DateTime::Calendar::Hebrew->new(month=>7, day=>1, 
			year=>($thisMonth==7 ? $thisYear : $thisYear+1));
    my $workingShabbat  =
    nextShabbat($simchatTorah)->subtract_duration(DateTime::Duration->new(days=>7));
    my $startDay	= $workingShabbat->{rd_days};
    my $endDay	= $targetShabbat->{rd_days};
    my $parshahNumber   = int(($endDay-$startDay)/7);


    #print "Next Shabbat: " , $targetShabbat->ymd, "\n";

    if ($parshahNumber < 22) {	# No special Shabbattot
	return $sedrah[$parshahNumber];
    }

    # From week 22 onwards there are special cases
    $parshahNumber	= 21;
    $workingShabbat->add_duration(DateTime::Duration->new(days=>21*7));
    my $leapYear        = DateTime::Calendar::Hebrew::_leap_year($simchatTorah->year);
    my $wDayPesach      = $pesach->day_of_week;
    my $combined        = 0;
    
    #print "leap year: $leapYear\tPesach $wDayPesach\n";
    

LOOP:
    while ($workingShabbat < $targetShabbat) {
        $workingShabbat->add_duration(DateTime::Duration->new(days=> 7));
        # If the Shabbat in question is yom tov or chol hamoed
        # it does not count towards the parshah count.
        if ($israel && exists $IsraelYomTovMap{$workingShabbat->{rd_days}}) {next;}
        if (!$israel && exists $YomTovMap{$workingShabbat->{rd_days}}) {next;}
	my $workingDays	= $workingShabbat->{rd_days};
	$parshahNumber++ if ($combined);
        $combined        = 0;
        $parshahNumber++;
        if($parshahNumber==22) {	#Vayakhel
		# Combine Vayakhel/Pekudei if there are fewer than 4 
		# Shabbatot *before* the first day of Pesach
		my $pesachDays	= $pesach->{rd_days};
		$combined =1 if ($pesachDays - $workingDays < 22);
		next LOOP;
            }
        if($parshahNumber ==27 ||       # Tazria
	      $parshahNumber ==29) {  	# Acharei Mot
		$combined     = 1 if (!$leapYear);
		next LOOP;
            }
        if($parshahNumber == 32) {        # Behar
		if ($israel) {
		    # In Israel we need to change the condition to
		    # not a leap year and Pesach not on Shabbat.
		    # Ths can only happen in a 354 day year that
		    # started on a thursday.
		    $combined = 1 if (!$leapYear && $wDayPesach != 7);
		} else {
		    # if Pesach falls on Shabbat then Pesach8 is
		    # also on Shabbat. This is not relevant in
		    # Israel.
		    $combined     = 1 if (!$leapYear);
		}
		next LOOP;
            }
        if($parshahNumber == 39) {        # Chukat
		# If Pesach falls on Thursday then Shavuot2 is Shabbat
		# In Israel never combine because Shavuot can never be Shabbat
		$combined = 1 if( $wDayPesach == 5 && !$israel);
		next LOOP;
            }
        if($parshahNumber == 42) {        # Mattot
		# Devraim is always read on the Shabbat before
		# Tisha B'Av. If 9 Av falls on Shabbat, then
		# we read Devarim actually on 9 Av.
		my $avDays	= $tishaBAv->{rd_days};
		$combined = 1 if (($avDays - $workingDays) < 14);
		next LOOP;
            }
        if(51 == $parshahNumber ) {        # Nitzavim
		# Is there a Shabbat between YC and Succot?
		my $roshDays	= $RoshHashanah->{rd_days};
		$combined = 1
		    if (($roshDays - $workingDays) > 3);
		next LOOP;
            }
    }

    my $parshah      = $sedrah[$parshahNumber];
    $parshah .= "/" . $sedrah[$parshahNumber+1] if ($combined);

    return $parshah;

}

=head1 BUGS

DateTime::Calendar::Hebrew is not a sub-class of DateTime. It
does not implement the all functionality of DateTime, and where it
does implement it, it uses different names and interfaces.
In particular, none of the arithmetic works.

=cut

1;

=head1 AUTHOR

Raphael Mankin, C<< <rapmankin at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-datetime-event-jewish at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DateTime-Event-Jewish>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DateTime::Event::Jewish


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Event-Jewish>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DateTime-Event-Jewish>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DateTime-Event-Jewish>

=item * Search CPAN

L<http://search.cpan.org/dist/DateTime-Event-Jewish/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Raphael Mankin.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of DateTime::Event::Parshah
