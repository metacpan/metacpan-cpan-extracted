
package Date::Convert;

use Carp;

$VERSION="0.16";


$VERSION=$VERSION; # to make -w happy.  :)

# methods that every class should have:
# initialize, day, date, date_string

# methods that are recommended if applicable:
# year, month, day, is_leap


$BEGINNING=1721426; # 1 Jan 1 in the Gregorian calendar, although technically, 
                    # the Gregorian calendar didn't exist at the time.
$VERSION_TODAY=2450522; # today in JDN, when I wrote this.


sub new { # straight out of the perlobj manpage:
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->initialize(@_);
    return $self;
}


sub initialize {
    my $self = shift;
    my $val  = shift || $VERSION_TODAY;
    carp "Date::Convert is not reliable before Absolute $BEGINNING" 
	if $val < $BEGINNING;
    $$self{absol}=$val;
}



sub clean {
    my $self  = shift;
    my $key;
    foreach $key (keys %$self) {
	delete $$self{$key} unless $key eq 'absol';
    }
}



sub convert {
    my $class = shift;
    my $self  = shift;
    $self->clean;
    bless $self, $class;
}




sub absol {
    my $self = shift;
    return $$self{absol};
}





package Date::Convert::Gregorian;

use Carp;
@ISA = qw ( Date::Convert );

$GREG_BEGINNING=1721426; # 1 Jan 1 in the Gregorian calendar, although
                    # technically, the Gregorian calendar didn't exist at
                    # the time.
@MONTHS_SHORT  = qw ( nil Jan Feb Mar Apr May Jun July Aug Sep Oct Nov Dec );
@MONTH_ENDS    = qw ( 0   31  59  90  120 151 181  212 243 273 304 334 365 );
@LEAP_ENDS     = qw ( 0   31  60  91  121 152 182  213 244 274 305 335 366 );

$NORMAL_YEAR    = 365;
$LEAP_YEAR      = $NORMAL_YEAR + 1;
$FOUR_YEARS     = 4 * $NORMAL_YEAR + 1; # one leap year every four years
$CENTURY        = 25 * $FOUR_YEARS - 1; # centuries aren't leap years . . .
$FOUR_CENTURIES = 4 * $CENTURY + 1;     # . . .except every four centuries.


sub year {
    my $self = shift;
    return $$self{year} if exists $$self{year}; # no point recalculating.
    my $days;
    my $year;
    # note:  years and days are initially days *before* today, rather than
    # today's date.  This is because of fenceposts.  :)
    $days =  $$self{absol} - $GREG_BEGINNING;
    if (($days+1) % $FOUR_CENTURIES) { # normal case
	$year =  int ($days / $FOUR_CENTURIES) * 400;
	$days %= $FOUR_CENTURIES;
	$year += int ($days / $CENTURY) * 100; # years.
	$days %= $CENTURY;
	$year += int ($days / $FOUR_YEARS) * 4;
	$days %= $FOUR_YEARS;
	if (($days+1) % $FOUR_YEARS) {
	    $year += int ($days / $NORMAL_YEAR); # fence post from year 1
	    $days %= $NORMAL_YEAR; 
	    $days += 1; # today
	    $year += 1;
	} else {
	    $year += int ($days / $NORMAL_YEAR + 1) - 1;
	    $days =  $LEAP_YEAR;
	}
    } else { # exact four century boundary.  Uh oh. . .
	$year =  int ($days / $FOUR_CENTURIES + 1) * 400;
	$days =  $LEAP_YEAR; # correction for later.
    }
    $$self{year}=$year;
    $$self{days_into_year}=$days;
    return $year;
}




sub is_leap {
    my $self = shift;
    my $year = shift || $self->year; # so is_leap can be static or method
    return 0 if (($year %4) || (($year % 400) && !($year % 100)));
    return 1;
}


sub month {
    my $self = shift;
    return $$self{month} if exists $$self{month};
    my $year = $self -> year;
    my $days = $$self{days_into_year};
    my $MONTH_REF = \@MONTH_ENDS;
    $MONTH_REF = \@LEAP_ENDS if ($self->is_leap);
    my $month= 13 - (grep {$days <= $_} @$MONTH_REF);
    $$self{month} = $month;
    $$self{day}   = $days-@$MONTH_REF[$month-1];
    return $month;
}



sub day {
    my $self = shift;
    return $$self{day} if exists $$self{day};
    $self->month; # calculates day as a side-effect
    return $$self{day};
}



sub date {
    my $self = shift;
    return ($self->year, $self->month, $self->day);
}



sub date_string {
    my $self  = shift;
    my $year  = $self->year;
    my $month = $self->month;
    my $day   = $self->day;
    return "$year $MONTHS_SHORT[$month] $day";
}




sub initialize {
    my $self = shift;
    my $year = shift || return Date::Convert::initialize;
    my $month= shift ||
	croak "Date::Convert::Gregorian::initialize needs more args";
    my $day  = shift ||
	croak "Date::Convert::Gregorian::initialize needs more args";
    warn "These routines don't work well for Gregorian before year 1"
	if $year<1;
    my $absol = $GREG_BEGINNING;
    $$self{'year'} = $year;
    $$self{'month'}= $month;
    $$self{'day'}  = $day;
    my $is_leap = is_leap Date::Convert::Gregorian $year;
    $year --;  #get years *before* this year.  Makes math easier.  :)
    # first, convert year into days. . .
    $absol += int($year/400)*$FOUR_CENTURIES;
    $year  %= 400;
    $absol += int($year/100)*$CENTURY;
    $year  %= 100;
    $absol += int($year/4)*$FOUR_YEARS;
    $year  %= 4;
    $absol += $year*$NORMAL_YEAR;
    # now, month into days.
    croak "month number $month out of range" 
	if $month < 1 || $month >12;
    my $MONTH_REF=\@MONTH_ENDS;
    $MONTH_REF=\@LEAP_ENDS if $is_leap;
    croak "day number $day out of range for month $month"
	if $day<1 || $day+$$MONTH_REF[$month-1]>$$MONTH_REF[$month];
    $absol += $day+$$MONTH_REF[$month-1]-1;
    $$self{absol}=$absol;
}





package Date::Convert::Hebrew;
use Carp;
@ISA = qw ( Date::Convert );

$HEBREW_BEGINNING = 347996; # 1 Tishri 1

                                # @MONTH       = (29,   12, 793);
@NORMAL_YEAR = (354,   8, 876); # &part_mult(12,  @MONTH);
@LEAP_YEAR   = (383,  21, 589); # &part_mult(13,  @MONTH);
@CYCLE_YEARS = (6939, 16, 595); # &part_mult(235, @MONTH);
@FIRST_MOLAD = ( 1,  5, 204);
@LEAP_CYCLE  = qw ( 3 6 8 11 14 17 0 );

@MONTHS = ('Nissan', 'Iyyar', 'Sivan', 'Tammuz', 'Av',
	'Elul', 'Tishrei', 'Cheshvan', 'Kislev', 'Teves',
	'Shevat', 'Adar', 'Adar II' );

# In the Hebrew calendar, the year starts in the seventh month, there can
# be a leap month, and there are two months with a variable number of days.
# Rather than calculate do the actual math, let's set up lookup tables based
# on year length.  :)

%MONTH_START=
    ('353' => [177, 207, 236, 266, 295, 325, 1, 31, 60, 89, 118, 148],
     '354' => [178, 208, 237, 267, 296, 326, 1, 31, 60, 90, 119, 149],
     '355' => [179, 209, 238, 268, 297, 327, 1, 31, 61, 91, 120, 150],
     '383' => [207, 237, 266, 296, 325, 355, 1, 31, 60, 89, 118, 148, 178],
     '384' => [208, 238, 267, 297, 326, 356, 1, 31, 60, 90, 119, 149, 179],
     '385' => [209, 239, 268, 298, 327, 357, 1, 31, 61, 91, 120, 150, 180]);

sub is_leap {
    my $self = shift;
    my $year = shift;
    $year=$self->year if ! defined $year;
    my $mod=$year % 19;
    return scalar(grep {$_==$mod} @LEAP_CYCLE);
}


sub initialize {
    my $self = shift;
    my $year = shift || return Date::Convert::initialize;
    my $month= shift ||
	croak "Date::Convert::Hebrew::initialize needs more args";
    my $day  = shift ||
	croak "Date::Convert::Hebrew::initialize needs more args";
    warn "These routines don't work well for Hebrew before year 1"
	if $year<1;
    $$self{year}=$year; $$self{$month}=$month; $$self{day}=$day;
    my $rosh=$self->rosh;
    my $year_length=(rosh Date::Convert::Hebrew ($year+1))-$rosh;
    carp "Impossible year length" unless defined $MONTH_START{$year_length};
    my $months_ref=$MONTH_START{$year_length};
    my $days=$$months_ref[$month-1]+$day-1;
    $$self{days}=$days;
    my $absol=$rosh+$days-1;
    $$self{absol}=$absol;
}



sub year {
    my $self = shift;
    return $$self{year} if exists $$self{year};
    my $days=$$self{absol};
    my $year=int($days/365)-3*365; # just an initial guess, but a good one.
    warn "Date::Convert::Hebrew isn't reliable before the beginning of\n".
	"\tthe Hebrew calendar" if $days < $HEBREW_BEGINNING;
    $year++ while rosh Date::Convert::Hebrew ($year+1)<=$days;
    $$self{year}=$year;
    $$self{days}=$days-(rosh Date::Convert::Hebrew $year)+1;
    return $year;
}


sub month {
    my $self = shift;
    return $$self{month} if exists $$self{month};
    my $year_length=
	rosh Date::Convert::Hebrew ($self->year+1) - 
	    rosh Date::Convert::Hebrew $self->year;
    carp "Impossible year length" unless defined $MONTH_START{$year_length};
    my $months_ref=$MONTH_START{$year_length};
    my $days=$$self{days};
    my ($n, $month)=(1);
    my $day=31; # 31 is too large.  Good.  :)
    grep {if ($days>=$_ && $days-$_<$day) 
	  {$day=$days-$_+1;$month=$n}
	  $n++} @$months_ref;
    $$self{month}=$month;
    $$self{day}=$day;
    return $month;
}




sub day {
    my $self = shift;
    return $$self{day} if exists $$self{day};
    $self->month; # calculates day as a side-effect.
    return $$self{day};
}


sub date {
    my $self = shift;
    return ($self->year, $self->month, $self->day);
}


sub date_string {
    my $self=shift;
    return $self->year." $MONTHS[$self->month-1] ".$self->day;
}


sub rosh {
    my $self = shift;
    my $year = shift || $self->year;    
    my @molad= @FIRST_MOLAD;
    @molad = &part_add(@molad, &part_mult(int(($year-1)/19),@CYCLE_YEARS));
    my $offset=($year-1)%19;
    my $num_leaps=(grep {$_<=$offset} @LEAP_CYCLE) - 1;
    @molad = &part_add(@molad, &part_mult($num_leaps, @LEAP_YEAR));
    @molad = &part_add(@molad, &part_mult($offset-$num_leaps, 
					      @NORMAL_YEAR));
    my $day=shift @molad;
    my $hour=shift @molad;
    my $part= shift @molad;
    my $guess=$day%7;
    if (($hour>=18)                              # molad zoken al tidrosh
	or
	((is_leap Date::Convert::Hebrew $year) and   # gatrad b'shanah
	 ($guess==2) and                         #      p'shutah g'rosh
	 (($hour>9)or($hour==9 && $part>=204)))
        or
        ((is_leap Date::Convert::Hebrew $year-1) and # b'to takfat achar
	 ($guess==1) and                         #      ha'ibur akor
	 (($hour>15)or($hour==15&&$part>589)))){ #      mi-lishorsh
	$guess++;
	$day++;
    }
    $guess%=7;
    if (scalar(grep {$guess==$_} (0, 3, 5))) {   # lo ad"o rosh
	$guess++;
	$day++;
    }
    $guess%=7;
    return ($day+1+$HEBREW_BEGINNING);
}




sub part_add {
    my ($day1, $hour1, $part1)=(shift, shift, shift);
    my ($day2, $hour2, $part2)=(shift, shift, shift);
    my $part=$part1+$part2;
    my $hour=$hour1+$hour2;
    my $day =$day1 +$day2;
    if ($part>1080) {
	$part-=1080;
	$hour++;
    }
    if ($hour>24) {
	$hour-=24;
	$day++;
    }
    return ($day, $hour, $part);
}


sub part_mult {
    my $scalar = shift;
    my $day= ((0+ shift) * $scalar);
    my $hour=((0+ shift) * $scalar);
    my $part=((0+ shift) * $scalar);
    my $tmp;
    if ($part>1080) {
	$tmp=int($part/1080);
	$part%=1080;
	$hour+=$tmp;
    }
    if ($hour>24) {
	$tmp=int($hour/24);
	$hour%=24;
	$day+=$tmp;
    }
    return($day, $hour, $part);
}


# Here's a quickie, based on the base class.

package Date::Convert::Absolute;
use Date::Convert;
@ISA = qw ( Date::Convert );

sub initialize {
    return Date::Convert::initialize @_;
}


sub date {
    my $self=shift;
    return $$self{'absol'};
}

sub date_string {
    my $self=shift;
    my $date=$self->date; # just a scalar
    return "$date";
}



# Julian is kinda like Gregorian, but the leap year rule is easier.

package Date::Convert::Julian;  

use Carp;
@ISA = qw ( Date::Convert::Gregorian Date::Convert );  
# we steal useful constants from Gregorian
$JULIAN_BEGINNING=$Date::Convert::Gregorian::GREG_BEGINNING - 2;
$NORMAL_YEAR=     $Date::Convert::Gregorian::NORMAL_YEAR;
$LEAP_YEAR=       $Date::Convert::Gregorian::LEAP_YEAR;
$FOUR_YEARS=      $Date::Convert::Gregorian::FOUR_YEARS;

@MONTH_ENDS    = @Date::Convert::Gregorian::MONTH_ENDS;
@LEAP_ENDS     = @Date::Convert::Gregorian::LEAP_ENDS;

sub initialize {
    my $self=shift ||
	croak "Date::Convert::Julian::initialize needs more args";
    my $year=shift || return Date::Convert::initialize;
    my $month=shift ||
	croak "Date::Convert::Julian::initialize needs more args";
    my $day=shift ||
	croak "Date::Convert::Julian::initialize needs more args";

    warn "These routines don't work well for Julian before year 1"
	if $year<1;
    my $absol = $JULIAN_BEGINNING;
    $$self{'year'} = $year;
    $$self{'month'}= $month;
    $$self{'day'}  = $day;
    my $is_leap = is_leap Date::Convert::Gregorian $year;
    $year --;  #get years *before* this year.  Makes math easier.  :)
    # first, convert year into days. . .
    $absol += int($year/4)*$FOUR_YEARS;
    $year  %= 4;
    $absol += $year*$NORMAL_YEAR;
    # now, month into days.
    croak "month number $month out of range" 
	if $month < 1 || $month >12;
    my $MONTH_REF=\@MONTH_ENDS;
    $MONTH_REF=\@LEAP_ENDS if $is_leap;
    croak "day number $day out of range for month $month"
	if $day<1 || $day+$$MONTH_REF[$month-1]>$$MONTH_REF[$month];
    $absol += $day+$$MONTH_REF[$month-1]-1;
    $$self{absol}=$absol;
}


sub year {
    my $self = shift;
    return $$self{year} if exists $$self{year};
    my ($days, $year);
    # To avoid fenceposts, year and days are initially *before* today.
    # the next code is stolen directly form the ::Gregorian code.  Good thing
    # I'm the one who wrote it. . .
    $days=$$self{absol}-$JULIAN_BEGINNING;
    $year =  int ($days / $FOUR_YEARS) * 4;
    $days %= $FOUR_YEARS;
    if (($days+1) % $FOUR_YEARS) { # Not on a four-year boundary.  Good!
	$year += int ($days / $NORMAL_YEAR); # fence post from year 1
	$days %= $NORMAL_YEAR; 
	$days += 1; # today
	$year += 1;
    } else {
	$year += int ($days / $NORMAL_YEAR + 1) - 1;
	$days =  $LEAP_YEAR;
    }
    $$self{year}=$year;
    $$self{days_into_year}=$days;
    return $year;
}



sub is_leap {
    my $self = shift;
    my $year = shift || $self->year; # so is_leap can be static or method
    return 0 if ($year %4);
    return 1;
}


# OK, we're done.  Everything else just gets inherited from Gregorian.


1;

__END__

=head1 NAME

Date::Convert - Convert Between any two Calendrical Formats

=head1 SYNOPSIS

	use Date::DateCalc;

	$date=new Date::Convert::Gregorian(1997, 11, 27);
	@date=$date->date;
	convert Date::Convert::Hebrew $date;
	print $date->date_string, "\n";

Currently defined subclasses:

	Date::Convert::Absolute
	Date::Convert::Gregorian
	Date::Convert::Hebrew
	Date::Convert::Julian

Date::Convert is intended to allow you to convert back and forth between
any arbitrary date formats (ie. pick any from: Gregorian, Julian, Hebrew,
Absolute, and any others that get added on).  It does this by having a
separate subclass for each format, and requiring each class to provide
standardized methods for converting to and from the date format of the base
class.  In this way, instead of having to code a conversion routine for
going between and two arbitrary formats foo and bar, the function only
needs to convert foo to the base class and the base class to bar.  Ie:

	Gregorian <--> Base class <--> Hebrew

The base class includes a B<Convert> method to do this transparently.

Nothing is exported because it wouldn't make any sense to export.  :)


=head1 DESCRIPTION

Fucntion can be split into several categories:

=over 4

=item * 

Universal functions available for all subclasses (ie. all formats).  The
fundamental conversion routines fit this category.

=item *

Functions that are useful but don't necessarily make sense for all
subclasses.  The overwhelming majority of functions fall into this
category.  Even such seemingly universal concepts as year, for instance,
don't apply to all date formats.

=item *

Private functions that are required of all subclasses, ie. B<initialize>.
These should I<not> be called by users.

=back

Here's the breakdown by category:

=head2 Functions Defined for all Subclasses

=over 4

=item new

Create a new object in the specified format with the specified start
paramaters, ie. C<$date = new Date::Convert::Gregorian(1974, 11, 27)>.  The
start parameters vary with the subclass.  My personal preference is to
order in decreasing order of generality (ie. year first, then month, then
day, or year then week, etc.)

This can have a default date, which should probably be "today".

=item date

Extract the date in a format appropriate for the subclass.  Preferably this
should match the format used with B<new>, so

	(new date::Convert::SomeClass(@a))->date;

should be an identity function on @a if @a was in a legitmate format.

=item date_string

Return the date in a pretty format.

=item convert

Change the date to a new format.

=back

=head2 Non-universal functions

=over 4

=item year

Return just the year element of date.

=item month

Just like year.

=item day

Just like year and month.

=item is_leap

Boolean.  Note that (for B<::Hebrew> and B<::Gregorian>, at least!) this
can be also be used as a static.  That is, you can either say
	$date->is_leap
or
	is_leap Date::Convert::Hebrew 5757

=back

=head2 Private functions that are required of all subclasses

You shouldn't call these, but if you want to add a class, you'll need to
write them!  Or it, since at the moment, there's only one.

=over 4

=item initialize

Read in args and initialize object based on their values.  If there are no
args, initialize with the base class's initialize (which will initialize in
the default way described above for B<new>.)  Note the American spelling of
"initialize": "z", not "s".

=back


=head1 SUBCLASS SPECIFIC NOTES

=head2 Absolute

The "Absolute" calendar is just the number of days from a certain reference
point.  Calendar people should recognize it as the "Julian Day Number" with
one minor modification:  When you convert a Gregorian day n to absolute,
you get the JDN of the Gregorian day from noon on.

Since "absolute" has no notion of years it is an extremely easy calendar
for conversion purposes.  I stole the "absolute" calendar format from
Reingold's emacs calendar mode, for debugging purposes.

The subclass is little more than the base class, and as the lowest common
denominator, doesn't have any special functions.

=head2 Gregorian

The Gregorian calendar is a purely solar calendar, with a month that is
only an approximation of a lunar month.  It is based on the old Julian
(Roman) calendar.  This is the calendar that has been used by most of the
Western world for the last few centuries.  The time of its adoption varies
from country to country.  This B<::Gregorian> allows you to extrapolate
back to 1 A.D., as per the prorgamming tradition, even though the calendar
definitely was not in use then.

In addition to the required methods, B<Gregorian> also has B<year>,
B<month>, B<day>, and B<is_leap> methods.  As mentioned above, B<is_leap>
can also be used statically.

=head2 Hebrew

This is the traditional Jewish calendar.  It's based on the solar year, on
the lunar month, and on a number of additional rules created by Rabbis to
make life tough on people who calculate calendars.  :)  If you actually wade
through the source, you should note that the seventh month really does come
before the first month, that's not a bug.

It comes with the following additional methods: B<year>, B<month>, B<day>,
B<is_leap>, B<rosh>, B<part_add>, and B<part_mult>.  B<rosh> returns the
absolute day corresponding to "Rosh HaShana" (New year) for a given year,
and can also be invoked as a static.  B<part_add> and B<part_mult> are
useful functions for Hebrew calendrical calculations are not for much else;
if you're not familiar with the Hebrew calendar, don't worry about them.


=head2 Islamic

The traditional Muslim calendar, a purely lunar calendar with a year that
is a rough approximation of a solar year.  Currently unimplemented.

=head2 Julian

The old Roman calendar, allegedly named for Julius Caesar.  Purely solar,
with a month that is a rough approximation of the lunar month.  Used
extensively in the Western world up to a few centuries ago, then the West
gradually switched over to the more accurate Gregorian.  Now used only by
the Eastern Orthodox Church, AFAIK.


=head1 ADDING NEW SUBCLASSES

This section describes how to extend B<Date::Convert> to add your favorite
date formats.  If you're not interested, feel free to skip it.  :)

There are only three function you I<have> to write to add a new subclass:
you need B<initialize>, B<date>, and B<date_string>.  Of course, helper
functions would probably help. . .  You do I<not> need to write a B<new> or
B<convert> function, since the base class handles them nicely.

First, a quick conceptual overhaul: the base class uses an "absolute day
format" (basically "Julian day format") borrowed from B<emacs>.  This is
just days numbered absolutely from an extremely long time ago.  It's really
easy to use, particularly if you have emacs and emacs' B<calendar mode>.
Each Date::Convert object is a reference to a hash (as in all OO perl) and
includes a special "absol" value stored under a reserved "absol" key.  When
B<initialize> initializes an object, say a Gregorian date, it stores
whatever data it was given in the object and it also calculates the "absol"
equivalent of the date and stores it, too.  If the user converts to another
date, the object is wiped clean of all data except "absol".  Then when the
B<date> method for the new format is called, it calculates the date in the
new format from the "absol" data.

Now that I've thoroughly confused you, here's a more compartmentalized
version:

=over 4

=item initialize

Take the date supplied as argument as appropriate to the format, and
convert it to "absol" format.  Store it as C<$$self{'absol'}>.  You might
also want to store other data, ie. B<::Gregorian> stores C<$$self{'year'}>,
C<$$self{'month'}>, and C<$$self{'day'}>.  If no args are supplied,
explicitly call the base class's initialize,
ie. C<Date::Convert::initialize>, to initialize with a default 'absol' date
and nothing else.

I<NOTE:>  I may move the default behavior into the new constructor.

=item date

Return the date in a appropriate format.  Note that the only fact that
B<date> can take as given is that C<$$self{'absol'}> is defined, ie. this
object may I<not> have been initialized by the B<initialize> of this
object's class.  For instance, you might have it check if C<$$self{'year'}>
is defined.  If it is, then you have the year component, otherwise, you
calculate year from C<$$self{'absol'}>.

=item date_string

This is the easy part.  Just call date, then return a pretty string based
on the values.

=back


I<NOTE:> The B<::Absolute> subclass is a special case, since it's nearly an
empty subclass (ie. it's just the base class with the required methods
filled out).  Don't use it as an example!  The easiest code to follow would
have been B<::Julian> except that Julian inherits from B<::Gregorian>.
Maybe I'll reverse that. . .


=head1 EXAMPLES

	#!/usr/local/bin/perl5 -w

	use Date::Convert;

	$date=new Date::Convert::Gregorian(1974, 11, 27);
	convert Date::Convert::Hebrew $date;
	print $date->date_string, "\n";

My Gregorian birthday is 27 Nov 1974.  The above prints my Hebrew birthday.

	convert Date::Convert::Gregorian $date;
	print $date->date_string, "\n";

And that converts it back and prints it in Gregorian.

	$guy = new Date::Convert::Hebrew (5756, 7, 8);
	print $guy->date_string, " -> ";
	convert Date::Convert::Gregorian $guy;
	print $guy->date_string, "\n";

Another day, done in reverse.

	@a=(5730, 3, 2);
	@b=(new Date::Convert::Hebrew @a)->date;
	print "@a\n@b\n";

The above should be an identity for any list @a that represents a
legitimate date.

	#!/usr/local/bin/perl -an

	use Date::Convert;

	$date = new Date::Convert::Gregorian @F;
	convert Date::Convert::Hebrew $date;
	print $date->date_string, "\n";

And that's a quick Greg -> Hebrew conversion program, for those times when
people ask.

=head1 SEE ALSO

perl(1), Date::DateCalc(3)

=head1 VERSION

Date::Convert 0.15 (pre-alpha)

=head1 AUTHOR

Mordechai T. Abzug <morty@umbc.edu>

=head1 ACKNOWLEDGEMENTS AND FURTHER READING

The basic idea of using astronomical dates as an intermediary between all
calculations comes from Dershowitz and Reingold.  Reingold's code is the
basis of emacs's calendar mode.  Two papers describing their work (which I
used to own, but lost!  Darn.) are:

``Calendrical Calculations'' by Nachum Dershowitz and Edward M. Reingold,
I<Software--Practice and Experience>, Volume 20, Number 9 (September,
1990), pages 899-928.  ``Calendrical Calculations, Part II: Three
Historical Calendars'' by E. M. Reingold, N. Dershowitz, and S. M. Clamen,
I<Software--Practice and Experience>, Volume 23, Number 4 (April, 1993),
pages 383-404.

They were also scheduled to come out with a book on calendrical
calculations in Dec. 1996, but as of March 1997, it still isn't out yet.

The Hebrew calendrical calculations are largely based on a cute little
English book called I<The Hebrew Calendar> (I think. . .)  in a box
somewhere at my parents' house.  (I'm organized, see!)  I'll have to dig
around next time I'm there to find it.  If you want to access the original
Hebrew sources, let me give you some advice: Hilchos Kiddush HaChodesh in
the Mishneh Torah is not the Rambam's most readable treatment of the
subject.  He later wrote a little pamphlet called "MaAmar HaEibur" which is
both more complete and easier to comprehend.  It's included in "Mich't'vei
HaRambam" (or some such; I've I<got> to visit that house), which was
reprinted just a few years ago.

Steffen Beyer's Date::DateCalc showed me how to use MakeMaker and write POD
documentation.  Of course, any error is my fault, not his!

=head1 COPYRIGHT

Copyright 1997 by Mordechai T. Abzug

=head1 LICENSE STUFF

You can distribute, modify, and otherwise mangle Date::Convert under the
same terms as perl.

