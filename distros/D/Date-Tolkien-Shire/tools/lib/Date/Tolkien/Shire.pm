=head1 NAME

Date::Tolkien::Shire.pm

=head1 DESCRIPTION

This is an object-oriented module to convert dates into the Shire Calender
as presented in the Lord of the Rings by J. R. R. Tolkien.  It includes
converting epoch time to the Shire Calendar (you can also get epoch time back),
comparison operators, and a method to print a formatted string containing
that does something to the effect of on this date in history -- pulling 
events from the Lord of the Rings.

The biggest use I can see in this thing is in a startup script or possible
to keep yourself entertained in an otherwise boring app that includes a date.
If you have any other ideas/suggestions/uses, etc., please let me know.  I
am curious to see how this gets used (if it gets used that is).

=head1 AUTHOR

Tom Braun <tbraun@pobox.com>

C<on_date()> corrections backported by Thomas R. Wyant, III
F<wyant at cpan dot org>.

=head1 DATE

February 2001

=cut

package Date::Tolkien::Shire;

use strict;
use Time::Local;

use vars qw($VERSION $ERROR);

$VERSION = '1.13_01';

=head1 METHOD REFERENCE

Note:  I have tried to make these as friendly as possible when an error
occurs.  As a consequence, none of them die, croak, etc.  All of these
return 0 on error, but as 0 can be a valid output in a couple cases
(the day of the month for a holiday, for example), the error method should
always be checked to see if an error has occured.  As long as you set a
date before you try to use it, you should be ok.

=head2 new

    $shiredate = Date::Tolkien::Shire->new;
    $shiredate = Date::Tolkien::Shire->new(time);
    $shiredate = Date::Tolkien::Shire->new($another_shiredate);

The constructor new can take zero or one parameter.  Either a new object can be
created without setting a specific date (the zero parameter version), or an
object can be created and the date set to either a current shire date, or 
an epoch time such as is returned by the time function.  For specifics on
setting dates, see the 'set_date' function.

=cut

sub new {
    my $class = shift;
    my $self = {};
    $ERROR = '';
    bless($self, $class);
    $self->set_date($_[0]) if defined($_[0]);
    return $self;
} #end sub new

=head2 error

    $the_error = $shiredate->error;
    $the_error = Date::Tolkien::Shire->error;

This returns a null string if everything in the previous method call was
as it should be, and a string contain a description of what happened if an
error occurred.

=cut

sub error {
    return $ERROR;
} #end sub error

=head2 set_date

This method takes either the seconds from the start of the epoch (like what 
time returns) or another shire date object, and sets the date of the 
object in question equal to that date.  If the object previously contained
a date, it will be overwritten.  Localtime, rather than utc, is used in 
converting from epoch date.

Please see the note below on calculating the year if your curious how
I arrived by that.

=cut

sub set_date {
    my ($self, $date) = @_;
    my ($leap, $ourleap, $sec, $min, $hour, $year, $yday);
    $ERROR = '';

    $ERROR .= "You must pass in a date to set me equal to" 
	if not defined($date);
    return $self if $ERROR;

    if (ref($date) eq 'Date::Tolkien::Shire') {
	$self->{holiday} = $date->{holiday};
	$self->{weekday} = $date->{weekday};
	$self->{monthday} = $date->{monthday};
	$self->{month} = $date->{month};
	$self->{year} = $date->{year};
    } #end if (ref($date) eq 'Date::Tolkien::Shire')

    elsif(int $date) {
	($year, $yday) = (localtime($date))[5,7];
	$self->{year} = $year + 7364; #1900 + 5464
	$self->{holiday} = 0; #assume this unless we find otherwise

	$ourleap = 0;
	$ourleap = 1 if ($year % 4 == 0) and ($year % 100 != 0);
	$ourleap = 1 if $year % 400 == 0;

	#Now for year adjustments since "except every 100 except every
	#400 year rule applies to different years in the two calendars"
	$leap = 0;
	$year = $self->{year} % 400;  #don't need old value of $year anymore
	if ($year == 300) {  #Shire calendar goes ahead one day in our Feb.
	    if ((!$ourleap && $yday == 365) || ($ourleap && $yday == 366)) {
		$yday = 1;
		++$self->{year};
	    }
	} elsif (($year > 300) && ($year < 364)) { #shire ahead 1 day
	    if ((!$ourleap && $yday == 365) || ($ourleap && $yday == 366)) {
		$yday = 1;
		++$self->{year};
	    } else {
		++$yday
	    }
	} elsif ($year == 164) { #calendars together after Overlithe
	    ++$yday;
	} elsif ((($year > 64) && ($year < 100)) || (($year > 164) && ($year < 200))) { #shire behind 1 day
	    if ($yday == 1) {
		--$self->{year};
		$leap = 1 if ($self->{year} % 4 == 0) and ($self->{year} % 100 != 0);
		$leap = 1 if $self->{year} % 400 == 0;
		if ($leap) { $yday = 366; }
		else { $yday = 365; }
	    } else {
		--$yday;
	    }
	} elsif (($year == 100) || ($year == 200)) { #equal after Feb 29
	    if ($yday == 1) {
		--$self->{year};
		$yday = 365;
	    } else {
		--$yday;
	    }
	}
	$leap = 1 if ($self->{year} % 4 == 0) and ($self->{year} % 100 != 0);
	$leap = 1 if $self->{year} % 400 == 0;
	if ($leap and $yday > 356) { ++$self->{year}; }
	elsif ($yday > 355 and !$leap) { ++$self->{year}; }

	#Now start looking at holidays, starting with leap year only Overlithe
	if ($leap) {
	    $self->{holiday} = 4 if ($yday == 174); #Overlithe
	    --$yday if $yday > 174;
	}
	#leap year can now be ignored for the rest of this
	#now check for any of the other holidays
	unless ($self->{holiday}) {
	    if ($yday == 356) {$self->{holiday} = 1;} #2 Yule-first day of new year
	    elsif ($yday == 172) {$self->{holiday} = 2;} #1 Lithe
	    elsif ($yday == 173) {$self->{holiday} = 3;} #Midyear's day
	    elsif ($yday == 174) {$self->{holiday} = 5;} #2 Lithe
	    elsif ($yday == 355) {$self->{holiday} = 6;} #1 Yule
	} #end unless

	#now compute the day of the week.  
	#Midyear's day (and Overlithe when applicable) not in any week
	--$yday if $yday > 172; #we want only days that have a weeday now
	if ($self->{holiday} == 3 or $self->{holiday} == 4) {
	    $self->{weekday} = 0;
	} #end if
	else {
	    $self->{weekday} = (($yday + 2) % 7) + 1;
	} #end else

	#Now figure out the month and day of the month
	#Holidays are not part of any month
	if ($self->{holiday}) {
	    $self->{month} = 0;
	    $self->{monthday} = 0;
	} #end if
	else {
	    --$yday; #ignore 2 Yule
	    $yday -= 2 if $yday > 172; #ignore the Lithes (correct plural???)
	    $yday += 9; #account for different start of year
	    $yday -= 362 if ($yday > 361);		
	    $self->{monthday} = ($yday % 30) + 1;
	    $self->{month} = int($yday / 30) + 1;
	} #end else
    } #end elsif (int $date)
    
    else {
	$ERROR .= "The date you gave is invalid";
    } #end else 
    return $self;
} #end sub set_date

=head2 time_in_seconds

    $epoch_time = $shire_date->time_in_seconds

Returns the epoch time (with 0 for hours, minutes, and seconds) of
a given shire date.   This relies on the library Time::Local, so the
caveats and error handling with that module apply to this method as well.

=cut

sub time_in_seconds {
    my $self = shift;
    my (@monthlen, $leap, $prevleap, $ourleap, $year, $month, $day, $modyear);
    $ERROR = '';
    @monthlen = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

    if (not (defined ($self->{holiday}) and defined ($self->{weekday}) and
	     defined ($self->{month}) and defined ($self->{monthday}) and
	     defined ($self->{year}))) {
	$ERROR = "You must set a date first";
	return 0;
    } #end if

    $year = $self->{year} - 5464;
    #both $leap and $prevleap refer to shire calendar
    $leap = 0;
    $leap = 1 if (($self->{year} % 4 == 0) and ($self->{year} % 100 != 0));
    $leap = 1 if ($self->{year} % 400 == 0);
    $prevleap = 0;
    $prevleap = 1 if ((($self->{year} - 1) % 4 == 0)
		      and (($self->{year} - 1) % 100 != 0));
    $prevleap = 1 if (($self->{year} - 1) % 400 == 0);

    #compute the year-day in our calendar from the shire one, and set the year
    if ($self->{holiday}) {
	if ($leap) {
	    $day = (0, 357, 173, 174, 175, 176, 357)[$self->{holiday}]; 
	} #end if ($leap)
	elsif ($prevleap) {
	    $day = (0, 358, 173, 174, 0, 175, 356)[$self->{holiday}];
	} #end elsif ($prevleap)
	else {
	    $day = (0, 357, 173, 174, 0, 175, 356)[$self->{holiday}];
	} #end else
	--$year if $self->{holiday} == 1;
    } #end if ($self->{holiday})
    else {
	$day = ($self->{month} - 1) * 30 + $self->{monthday};
	$day += 3 if $day > 180; #Account for the Lithe and Midyear day
	++$day if $leap and $day > 182; #Account for Overlithe
	$day -= 8;  #Account for year starting on a different day
    } #end else

    #Now for adjustments for various years being off by a day
    $modyear = $self->{year} % 400;
    if (($modyear > 300) && ($modyear < 364)) {
	--$day unless ($modyear == 301) && ($self->{holiday} == 1);
    } elsif ((($modyear > 64) && ($modyear <= 100)) || (($modyear > 164) && ($modyear <= 200))) {
	++$day;
	$ourleap = 0;
	$ourleap = 1 if (($year % 4 == 0) and ($year % 100 != 0));
	$ourleap = 1 if ($year % 400 == 0);
	if ($day == 367) {
	    ++$year;
	    $day = 1;
	} elsif ($day == 366 and not $ourleap) {
	    ++$year;
	    $day = 1;
	}
    } elsif (($modyear == 101) || ($modyear == 201)) {
	++$day if ($self->{holiday} == 1);
    }

    if ($day < 1) {
	--$year;
	if ($year % 4 != 0) { $day += 365; }
	elsif (($year % 100 == 0) && ($year % 400 != 0)) { $day += 365; }
	else { $day += 366; }
    } #end if ($day < 1)

    #take our leap years into account
    $monthlen[1] = 29 if (($year % 4 == 0) and ($year %100 != 0));
    $monthlen[1] = 29 if ($year % 400 == 0);

    #now convert the year-day to the month and month-day
    $month = 0;
    while ($day > $monthlen[$month]) {
	$day -= $monthlen[$month];
	++$month;
    } #end while ($day > $monthlen[$month])

    return timelocal(0, 0, 0, $day, $month, $year);
} #end sub time_in_seconds 

=head2 weekday

    $day_of_week = $shiredate->weekday;

This function returns the day of the week using the more modern names 
in use during the War of the Ring and given in the Lord of the Rings 
Appendix D.  If the day in question is not part of any week (Midyear 
day and the Overlithe), then the null string is returned.

=cut

sub weekday {
    my $self = shift;
    my @days = ('', 'Sterday', 'Sunday', 'Monday', 'Trewsday', 'Hevensday',
		'Mersday', 'Highday');
    $ERROR = '';
    if (defined $self->{weekday}) {
	return $days[$self->{weekday}];
    } #end if
    else {
	$ERROR = "You must set a date first";
	return 0;
    } #end else 
} #end sub weekday

=head2 trad_weekday (for traditional weekday)

    $day_of_week = $shiredate->trad_weekday

This function returns the day of the week using the archaic forms, the
oldest forms found in the Yellowskin of Tuckborough (also given in Appendix
D).  If the day in question is not part of any week (Midyear day and the
Overlithe), then the null string is returned.

=cut 

sub trad_weekday {
    my $self = shift;
    my @days = ('', 'Sterrendei', 'Sunnendei', 'Monendei', 'Trewesdei',
		'Hevenesdei', 'Meresdei', 'Highdei');
    $ERROR = '';
    if (defined $self->{weekday}) {
	return $days[$self->{weekday}];
    } #end if
    else {
	$ERROR = "You must set a date first";
	return 0;
    } #end else 
} #end sub trad_weekday

=head2 month

    $month = $shiredate->month;

Returns the month of the date in question, or the null string if the day is
a holiday, since holidays are not part of any month.

=cut

sub month {
    my $self = shift;
    my @months = ('', 'Afteryule', 'Solmath', 'Rethe', 'Astron', 'Thrimidge',
		  'Forelithe', 'Afterlithe', 'Wedmath', 'Halimath', 
		  'Winterfilth', 'Blotmath', 'Foreyule');
    $ERROR = '';
    if (defined $self->{month}) {
	return $months[$self->{month}];
    } #end if
    else {
	$ERROR = "You must set a date first";
	return 0;
    } #end else 
} #end sub month

=head2 day

    $day_of_month = $self->{monthday};

returns the day of the month of the day in question, or 0 in the case of 
a holiday, since they are not part of any month

=cut

sub day {
    my $self = shift;
    $ERROR = '';
    if (defined $self->{monthday}) {
	return $self->{monthday};
    } #end if
    else {
	$ERROR = "You must set a date first";
	return 0;
    } #end else 
} #end sub  day

=head2 holiday

    $holiday = $shiredate->holiday;

If the day in question is a holiday, returns a string which holiday it is:
"1 Yule", "2 Yule" (first day of the new year), "1 Lithe", "Midyear's day",
"Overlithe", or "2 Lithe".  If the day is not a holiday, the null string
is returned

=cut

sub holiday {
    my $self = shift;
    my @holidays = ('', '2 Yule', '1 Lithe', "Midyear's day", 'Overlithe',
		    '2 Lithe', '1 Yule');
    $ERROR = '';
    if (defined $self->{holiday}) {
	return $holidays[$self->{holiday}];
    } #end if
    else {
	$ERROR = "You must set a date first";
	return 0;
    } #end else 
} #end sub holiday


=head2 year

    $shire_year = $shiredate->year;

Returns the year of the shire date in question.  See the note on year
calculaton below if you want to see how I figured this.

=cut

sub year {
    my $self = shift;
    $ERROR = '';
    if (defined $self->{year}) {
	return $self->{year};
    } #end if
    else {
	$ERROR = "You must set a date first";
	return 0;
    } #end else 
} #end sub year

=head2 Operators

The following comparison operators are available:
    $shiredate1 <  $shiredate2
    $shiredate1 lt $shiredate2
    $shiredate1 <= $shiredate2
    $shiredate1 le $shiredate2
    $shiredate1 >  $shiredate2
    $shiredate1 gt $shiredate2
    $shiredate1 >= $shiredate2
    $shiredate1 ge $shiredate2
    $shiredate1 == $shiredate2
    $shiredate1 eq $shiredate2
    $shiredate1 != $shiredate2
    $shiredate1 ne $shiredate2
    $shiredate1 <=> $shiredate2
    $shiredate1 cmp $shiredate2

You can only compare on shire date to another (no apples to oranges here).
In this context both the numeric and string operators perform the 
exact same function.  Like the standard operators, all but <=> and cmp return
1 if the condition is true and the null string if it is false.  <=> and
cmp return -1 if the left operand is less than the right one, 0 if the 
two operands are equal, and 1 if the left operand is greater than the 
right one.

Additionally, you can view a shire date as a string:

    # prints something like 'Monday 28 Rethe 7465'
    print $shiredate;

=cut

use overload('<=>' => \&spaceship,
	     'cmp' => \&spaceship,
             '""'  => \&as_string,
            );
#All the other operators come automatically once this one is defined

sub spaceship {
    my ($date1, $date2) = @_;
    $ERROR = '';
    my $time1 = $date1->time_in_seconds;
    $ERROR .= " on left operand" if $ERROR;
    my $time2 = $date2->time_in_seconds;
    $ERROR .= " on right operand" if $ERROR;
    return $time1 <=> $time2;
} #end sub spaceship


=head2 as_string

$shire_date_as_string = $shire_date->string;

Returns the given shire date as a string, similar in theory to
C<scalar localtime>

=cut

sub as_string {
    my $self = shift;
    my $returntext;

    if ($self->{holiday}) {
	if ($self->{weekday}) {
	    $returntext = $self->weekday . " " . $self->holiday . " " . $self->year;
	} #end if ($self->{holiday}
	else {
	    $returntext = $self->holiday . " " . $self->year;
	} #end else
    } #end if ($self->{holiday})
    else {
	$returntext = $self->weekday . " " . $self->day . " " . $self->month  . " " . $self->year;
    } #end else

    return $returntext;
}

=head2 on_date

    $historic_events = $shire_date->on_date

or you may want to try something like
my $shiredate = Date::Tolkien::Shire->new(time);
print "Today is " . $shiredate->on_date . "\n";

This method returns a string containing important events that happened 
on this day and month in history, as well as the day itself.  It does not
give much more usefullness as far as using dates go, but it should
be fun to run during a startup script or something.  At present the events are
limited to the crucial years at the end of the third age when the final war 
of the ring took place and Sauron was permanently defeated.  More dates 
will be added as I find them (if I find them maybe I should say).  All
the ones below come from Appendix B of the Lord of the Rings.  At this point,
these are only available in English.  

Note here that the string is formatted.  This is to keep things simple
when using it as in the second example above.  Note that in this second
example you are actually ending with a double space, as the first endline
is part of the return value.  

If you don't like how this is formatted, complain at me and if I like you
I'll consider changing it :-)

=cut

sub on_date {
    my $self = shift;
    my ($returntext, %events);
    $ERROR = '';
    if (not (defined ($self->{holiday}) and defined ($self->{weekday}) and
	     defined ($self->{month}) and defined ($self->{monthday}))) {
	$ERROR = "You must set a date first";
	return 0;
    } #end if

    # %events has the following structure.  It is a hash of hashes.
    # The top level hash is keyed by the numbers 0 - 12.  1-12 refer to 
    # the months and zero is reserved to holidays.  The second level hash
    # is keyed by the date 1-30 within the month, or 1-6 for the six holidays.
    # The values of the level 2 hashes are the events we want to return if
    # the day matches up
    $events{0} = { 3  => "Wedding of King Elessar and Arwen, 1419.\n"
		   };
    $events{1} = { 8  => "The Company of the Ring reaches Hollin, 1419.\n",
		   13 => "The Company of the Ring reaches the West-gate of Moria at nightfall, 1419.\n",
		   14 => "The Company of the Ring spends the night in Moria hall 21, 1419.\n",
		   15 => "The Bridge of Khazad-dum, and the fall of Gandalf, 1419.\n",
		   17 => "The Company of the Ring comes to Caras Galadhon at evening, 1419.\n",
		   23 => "Gandalf pursues the Balrog to the peak of Zirakzigil, 1419.\n",
		   25 => "Gandalf casts down the Balrog, and passes away.\n" .
		       "His body lies on the peak of Zirakzigil, 1419.\n"
		   };
    $events{2} = { 14 => "Frodo and Sam look in the Mirror of Galadriel, 1419.\n" .
		       "Gandalf returns to life, and lies in a trance, 1419.\n",
		   16 => "Company of the Ring says farewell to Lorien --\n" . 
		       "Gollum observes departure, 1419.\n",
		   17 => "Gwaihir the eagle bears Gandalf to Lorien, 1419.\n",
		   25 => "The Company of the Ring pass the Argonath and camp at Parth Galen, 1419.\n" .
		       "First battle of the Fords of Isen -- Theodred son of Theoden slain, 1419.\n",
		   26 => "Breaking of the Fellowship, 1419.\n" .
		       "Death of Boromir; his horn is heard in Minas Tirith, 1419.\n" .
		       "Meriadoc and Peregrin captured by Orcs -- Aragorn pursues, 1419.\n" .
		       "Eomer hears of the descent of the Orc-band from Emyn Muil, 1419.\n" .
		       "Frodo and Samwise enter the eastern Emyn Muil, 1419.\n",
		   27 => "Aragorn reaches the west-cliff at sunrise, 1419.\n" .
		       "Eomer sets out from Eastfold against Theoden's orders to pursue the Orcs, 1419.\n",
		   28 => "Eomer overtakes the Orcs just outside of Fangorn Forest, 1419.\n",
		   29 => "Meriodoc and Pippin escape and meet Treebeard, 1419.\n" .
		       "The Rohirrim attack at sunrise and destroy the Orcs, 1419.\n" .
		       "Frodo descends from the Emyn Muil and meets Gollum, 1419.\n" .
		       "Faramir sees the funeral boat of Boromir, 1419.\n",
		   30 => "Entmoot begins, 1419.\n" .
		       "Eomer, returning to Edoras, meets Aragorn, 1419.\n"
		   };
    $events{3} = { 1  => "Aragorn meets Gandalf the White, and they set out for Edoras, 1419.\n" .
		       "Faramir leaves Minas Tirith on an errand to Ithilien, 1419.\n",
		   2  => "The Rohirrim ride west against Saruman, 1419.\n" .
		       "Second battle at the Fords of Isen; Erkenbrand defeated, 1419.\n" .
		       "Entmoot ends.  Ents march on Isengard and reach it at night, 1419.\n",
		   3  => "Theoden retreats to Helm's Deep; battle of the Hornburg begins, 1419.\n" .
		       "Ents complete the destruction of Isengard.\n",
		   4  => "Theoden and Gandalf set out from Helm's Deep for Isengard, 1419.\n" .
		       "Frodo reaches the slag mound on the edge of the of the Morannon, 1419.\n",
		   5  => "Theoden reaches Isengard at noon; parley with Saruman in Orthanc, 1419.\n" . 
		       "Gandalf sets out with Peregrin for Minas Tirith, 1419.\n",
		   6  => "Aragorn overtaken by the Dunedain in the early hours, 1419.\n", 
		   7  => "Frodo taken by Faramir to Henneth Annun, 1419.\n" .
		       "Aragorn comes to Dunharrow at nightfall, 1419.\n", 
		   8  => "Aragorn takes the \"Paths of the Dead\", and reaches Erech at midnight, 1419.\n".
		       "Frodo leaves Henneth Annun, 1419.\n",
		   9  => "Gandalf reaches Minas Tirith, 1419.\n" .
		       "Darkness begins to flow out of Mordor, 1419.\n",
		   10 => "The Dawnless Day, 1419.\n" .
		       "The Rohirrim are mustered and ride from Harrowdale, 1419.\n" .
		       "Faramir rescued by Gandalf at the gates of Minas Tirith, 1419.\n" .
		       "An army from the Morannon takes Cair Andros and passes into Anorien, 1419.\n",
		   11 => "Gollum visits Shelob, 1419.\n" . 
		       "Denethor sends Faramir to Osgiliath, 1419.\n" .
		       "Eastern Rohan is invaded and Lorien assaulted, 1419.\n",
		   12 => "Gollum leads Frodo into Shelob's lair, 1419.\n" .
		       "Ents defeat the invaders of Rohan, 1419.\n",
		   13 => "Frodo captured by the Orcs of Cirith Ungol, 1419.\n" .
		       "The Pelennor is overrun and Faramir is wounded, 1419.\n" .
		       "Aragorn reaches Pelargir and captures the fleet of Umbar, 1419.\n",
		   14 => "Samwise finds Frodo in the tower of Cirith Ungol, 1419.\n" .
		       "Minas Tirith besieged, 1419.\n",
		   15 => "Witch King breaks the gates of Minas Tirith, 1419.\n" .
		       "Denethor, Steward of Gondor, burns himself on a pyre, 1419.\n" .
		       "The battle of the Pelennor occurs as Theoden and Aragorn arrive, 1419.\n" .
		       "Thranduil repels the forces of Dol Guldur in Mirkwood, 1419.\n" .
		       "Lorien assaulted for second time, 1419.\n",
		   17 => "Battle of Dale, where King Brand and King Dain Ironfoot fall, 1419.\n" .
		       "Shagrat brings Frodo's cloak, mail-shirt, and sword to Barad-dur, 1419.\n",
		   18 => "Host of the west leaves Minas Tirith, 1419.\n" .
		       "Frodo and Sam overtaken by Orcs on the road from Durthang to Udun, 1419.\n",
		   19 => "Frodo and Sam escape the Orcs and start on the road toward Mount Doom, 1419.\n",
		   22 => "Lorien assaulted for the third time, 1419.\n",
		   24 => "Frodo and Sam reach the base of Mount Doom, 1419.\n",
		   25 => "Battle of the Host of the West on the slag hill of the Morannon, 1419.\n" .
		       "Gollum siezes the Ring of Power and falls into the Cracks of Doom, 1419.\n" .
		       "Downfall of Barad-dur and the passing of Sauron!, 1419.\n" .
		       "Birth of Elanor the Fair, daughter of Samwise, 1421.\n" .
		       "Fourth age begins in the reckoning of Gondor, 1421.\n",
		   27 => "Bard II and Thorin III Stonehelm drive the enemy from Dale, 1419.\n",
		   28 => "Celeborn crosses the Anduin and begins destruction of Dol Guldur, 1419.\n"
		   };
    $events{4} = { 6  => "The mallorn tree flowers in the party field, 1420.\n",
	           8  => "Ring bearers are honored on the fields of Cormallen, 1419.\n",
	           12 => "Gandalf arrives in Hobbiton, 1418\n"
	           };
    $events{5} = { 1  => "Crowning of King Elessar, 1419.\n" .
		       "Samwise marries Rose, 1420.\n"
		   };
    $events{6} = { 20 => "Sauron attacks Osgiliath, 1418.\n" . 
		       "Thranduil is attacked, and Gollum escapes, 1418.\n"
		   };
    $events{7} = { 4  => "Boromir sets out from Minas Tirith, 1418\n",
		   10 => "Gandalf imprisoned in Orthanc, 1418\n",
		   19 => "Funeral Escort of King Theoden leaves Minas Tirith, 1419.\n"
		   };
    $events{8} = { 10 => "Funeral of King Theoden, 1419.\n"
		   };
    $events{9} = { 18 => "Gandalf escapes from Orthanc in the early hours, 1418.\n",
		   19 => "Gandalf comes to Edoras as a beggar, and is refused admittance, 1418\n",
		   20 => "Gandalf gains entrance to Edoras.  Theoden commands him to go:\n" .
		       "\"Take any horse, only be gone ere tomorrow is old\", 1418.\n",
		   21 => "The hobbits return to Rivendell, 1419.\n",
		   22 => "Birthday of Bilbo and Frodo.\n" .  
		       "The Black Riders reach Sarn Ford at evening;\n" . 
		       "  they drive off the guard of Rangers, 1418.\n" .
		       "Saruman comes to the Shire, 1419.\n",   
		   23 => "Four Black Riders enter the shire before dawn.  The others pursue \n" .
		       "the Rangers eastward and then return to watch the Greenway, 1418.\n" .
		       "A Black Rider comes to Hobbiton at nightfall, 1418.\n" . 
		       "Frodo leaves Bag End, 1418.\n" .
		       "Gandalf having tamed Shadowfax rides from Rohan, 1418.\n",
		   26 => "Frodo comes to Bombadil, 1418\n",
		   28 => "The Hobbits are captured by a barrow-wight, 1418.\n",
		   29 => "Frodo reaches Bree at night, 1418.\n" .
		       "Frodo and Bilbo depart over the sea with the three Keepers, 1421.\n" .
		       "End of the Third Age, 1421.\n",
		   30 => "Crickhollow and the inn at Bree are raided in the early hours, 1418.\n" .
		       "Frodo leaves Bree, 1418.\n",
            	   };
    $events{10} = { 3  => "Gandalf attacked at night on Weathertop, 1418.\n",
		    5  => "Gandalf and the Hobbits leave Rivendell, 1419.\n",
		    6  => "The camp under Weathertop is attacked at night and Frodo is wounded, 1418.\n",
		    11 => "Glorfindel drives the Black Riders off the Bridge of Mitheithel, 1418.\n",
		    13 => "Frodo crosses the Bridge of Mitheithel, 1418.\n",
		    18 => "Glorfindel finds Frodo at dusk, 1418.\n" . 
			"Gandalf reaches Rivendell, 1418.\n",
		    20 => "Escape across the Ford of Bruinen, 1418.\n",
		    24 => "Frodo recovers and wakes, 1418.\n" .
			"Boromir arrives at Rivendell at night, 1418.\n",
		    25 => "Council of Elrond, 1418.\n",
		    30 => "The four Hobbits arrive at the Brandywine Bridge in the dark, 1419.\n"
		    }; 
    $events{11} = { 3  => "Battle of Bywater and passing of Saruman, 1419.\n" .
			"End of the War of the Ring, 1419.\n"
		  };
    $events{12} = { 25 => "The Company of the Ring leaves Rivendell at dusk, 1418.\n"
		    };

    if ($self->{holiday} and defined($events{0}->{$self->{holiday}})) {
	$returntext .= "$self\n\n" . $events{0}->{$self->{holiday}};
    } #end if ($self->{holiday} and defined($events{0}->{$self->{holiday}}))
    elsif (defined($events{$self->{month}}->{$self->{monthday}})) {
	$returntext .= "$self\n\n" . $events{$self->{month}}->{$self->{monthday}};
    } #end elsif (defined($events{$self->{month}}->{$self->{monthday}}))
    else {
	$returntext = "$self\n";
    } #end else

    return $returntext;
} #end sub on_date

=head1 NOTE: YEAR CALCULATION

http://www.glyhweb.com/arda/f/fourthage.html references a letter sent by
Tolkien in 1958 in which he estimates approxiimately 6000 years have passed
since the War of the Ring and the end of the Third Age.  (Thanks to Danny
O'Brien from sending me this link).  I took this approximate as an exact
and calculated back 6000 years from 1958 and set this as the start of the 
4th age (1422).  Thus the fourth age begins in our B.C 4042.

According to Appendix D of the Lord of the Rings, leap years in hobbit
calendar are every 4 years unless its the turn of the century, in which
case it's not a leap year.  Our calendar uses every 4 years unless it's 
100 years unless its 400 years.  So, if no changes have been made to 
the hobbit's calendar since the end of the third age, their calendar would
be about 15 days further behind ours now then when the War of the Ring took
place.  Implementing this seemed to me to go against Tolkien's general habit
of converting dates in the novel to our equivalents to give us a better
sense of time.  My thoughts, at least right now, is that it is truer to the
spirit of things for March 25 today to be about the same as March 25 was back
then.  So instead, I have modified Tolkien's description of the hobbit 
calendar so that leap years occur once every 4 years unless it's 100
years unless it's 400 years, so as it matches our calendar in that
regard.  These 100 and 400 year intervals occur at different times in
the two calendars, however.  Thus the last day of our year is sometimes
7 Afteryule, sometimes 8, and sometimes 9.

=head1 BIBLIOGRAPHY

Tolkien, J. R. R. <i>Return of the King<i>.  New York: Houghton Mifflin Press,
1955.

http://www.glyphweb.com/arda/f/fourthage.html

=head1 BUGS

Epoch time.  Since epoch time was used as the base for this module, and the
only way to currently set a date is from epoch time, it borks on values that
epoch time doesn't support (currently values before 1902 or after 2037).  The
module should automatically expand in available dates directly with epoch time
support on your system.

=cut

1;
