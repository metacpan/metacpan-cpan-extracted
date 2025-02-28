package DateTime::Fiction::JRRTolkien::Shire;

use vars qw($VERSION);
use strict;
use DateTime;
our $VERSION = '0.900_04';

# This assumes all the values in the info hashref are valid, and doesn't do validation
# However, the day and month parameters will be given defaults if not present
sub _recalc_DateTime {
    my ($self, %dt_args) = @_;
    my ($prevleap, $gregleap, $modyear, $yday, $arg);
    my @monthlen = (0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

    $dt_args{year} = $self->{year} - 5464;
    # $prevleap refers to shire calendar
    $prevleap = 0;
    $prevleap = 1 if ((($self->{year} - 1) % 4 == 0) and (($self->{year} - 1) % 100 != 0));
    $prevleap = 1 if (($self->{year} - 1) % 400 == 0);

    if ($self->{holiday}) {
	if ($self->{leapyear}) {
	    $yday = (0, 1, 182, 183, 184, 185, 366)[$self->{holiday}];
	} else {
	    $yday = (0, 1, 182, 183, 0, 184, 365)[$self->{holiday}];
	}
    } else {
	$yday = ($self->{month} - 1) * 30 + $self->{day} + 1; # The +1 is for 2 Yule
	$yday += 3 if $yday > 181; #Account for the Lithe and Midyear day
	++$yday if $self->{leapyear} and $yday > 183; #Account for Overlithe
    }
    $yday -= 9; # Different Start of years.  We'll adjust this based on the year momentarily

    #Now for adjustments for various years being off by a day
    $modyear = $self->{year} % 400;
    if (($modyear > 300) && ($modyear < 364)) {
	--$yday;
    } elsif ($modyear == 364) {
	--$yday;
    } elsif ((($modyear > 64) && ($modyear < 100)) || (($modyear > 164) && ($modyear < 200))) {
	++$yday;
    } elsif (($modyear == 100) || ($modyear == 200)) {
	++$yday;
    }

    if ($yday < 1) {
	--$dt_args{year};
	$gregleap = 0;
	$gregleap = 1 if (($dt_args{year} % 4 == 0) and ($dt_args{year} % 100 != 0));
	$gregleap = 1 if ($dt_args{year} % 400 == 0);
	if ($gregleap) { 
	    $yday += 366;
	} else { 
	    $yday += 365; 
	}
    } else {
	$gregleap = 0;
	$gregleap = 1 if (($dt_args{year} % 4 == 0) and ($dt_args{year} % 100 != 0));
	$gregleap = 1 if ($dt_args{year} % 400 == 0);
	if ($gregleap and $yday > 366) {
	    ++$dt_args{year};
	    $yday -= 366;
	    $gregleap = 0;
	} elsif ($yday > 365) {
	    ++$dt_args{year};
	    $yday -= 365;
	    $gregleap = 0;
	    $gregleap = 1 if (($dt_args{year} % 4 == 0) and ($dt_args{year} % 100 != 0));
	    $gregleap = 1 if ($dt_args{year} % 400 == 0);
	}
    }

    #now convert the year-day to the month and month-day
    $monthlen[2] = 29 if $gregleap;
    $dt_args{month} = 1;
    while ($yday > $monthlen[$dt_args{month}] and $dt_args{month} < 12) {
	$yday -= $monthlen[$dt_args{month}];
	++$dt_args{month};
    }
    $dt_args{day} = $yday;

    # Now for time parameters, if any
    if ($self->{dt}) {
	foreach $arg (qw(hour minute second nanosecond time_zone locale)) {
	    $dt_args{$arg} = $self->{dt}->$arg if not defined $dt_args{$arg};
	}
    }

    $self->{dt} = new DateTime(%dt_args);
} # end sub _recalc_DateTime

sub _recalc_Shire {
    my $self = shift;
    my ($yday, $modyear);

    $self->{year} = $self->{dt}->year + 5464;
    $self->{holiday} = 0; #assume this unless we find otherwise
    $yday = $self->{dt}->day_of_year + 9; # + 9 to account fora different year starting points

    # year adjustments are needed since "except every 100 except every
    # 400 year rule applies to different years in the two calendars"
    $modyear = $self->{year} % 400;
    if (($modyear > 300) && ($modyear < 364)) {
	++$yday;
    } elsif ($modyear == 364) {
	++$yday;
    } elsif ((($modyear > 64) && ($modyear < 100)) || (($modyear > 164) && ($modyear < 200))) {
	--$yday;
    } elsif (($modyear == 100) || ($modyear == 200)) {
	--$yday;
    }
    $self->{leapyear} = 0;
    $self->{leapyear} = 1 if ($self->{year} % 4 == 0) and ($self->{year} % 100 != 0);
    $self->{leapyear} = 1 if $self->{year} % 400 == 0;
    if ($self->{leapyear} and $yday > 366) {
	++$self->{year};
	$yday -= 366;
	$self->{leapyear} = 0;
    } elsif (! $self->{leapyear} and $yday > 365) { 
	++$self->{year};
	$yday -= 365;
	$self->{leapyear} = 0;
	$self->{leapyear} = 1 if ($self->{year} % 4 == 0) and ($self->{year} % 100 != 0);
	$self->{leapyear} = 1 if $self->{year} % 400 == 0;
    }

    # The overlithe only occurs on a leapyear.  By checking for it first, we can ignore leap years after this point
    if ($self->{leapyear}) {
	$self->{holiday} = 4 if ($yday == 184); #Overlithe
	--$yday if $yday > 184;
    }
    unless ($self->{holiday}) { # this will only be true if its the Overlithe
	if ($yday == 1) {$self->{holiday} = 1;} #2 Yule-first day of new year
	elsif ($yday == 182) {$self->{holiday} = 2;} #1 Lithe
	elsif ($yday == 183) {$self->{holiday} = 3;} #Midyear's day
	elsif ($yday == 184) {$self->{holiday} = 5;} #2 Lithe
	elsif ($yday == 365) {$self->{holiday} = 6;} #1 Yule
    }

    # Midyear's day (and Overlithe when applicable) are not in any week, while every other day is
    # Therefore, subtract out midyear's day to make the calculations nice
    --$yday if $yday > 183;
    if ($self->{holiday} == 3 or $self->{holiday} == 4) {
	$self->{wday} = 0;
    } else {
	$self->{wday} = (($yday - 1) % 7) + 1;
    }

    if ($self->{holiday}) { # holidays are not part of any month
	$self->{month} = 0;
	$self->{day} = 0;
    } else {
	--$yday; #ignore 2 Yule
	$yday -= 2 if $yday > 180; #ignore the Lithes (correct plural???) -- Midyear's day already subtracted out
	$self->{day} = (($yday - 1) % 30) + 1;
	$self->{month} = int(($yday - 1) / 30) + 1;
    }

    $self->{recalc} = 0;
} #end sub _date_info

# Constructors

sub new {
    my ($class, %args) = @_;
    my ($self, $arg, %dt_args, $itr);
    my @months = ('', 'Afteryule', 'Solmath', 'Rethe', 'Astron', 'Thrimidge', 'Forelithe', 'Afterlithe', 
		  'Wedmath', 'Halimath', 'Winterfilth', 'Blotmath', 'Foreyule');
    my @holidays = ('', '2 Yule', '1 Lithe', "Midyear's day", 'Overlithe', '2 Lithe', '1 Yule');

    if ($args{month}) {
	foreach $itr (1..12) {
	    $args{month} = $itr if $args{month} eq $months[$itr];
	}
    }
    if ($args{holiday}) {
	foreach $itr (1..6) {
	    $args{holiday} = $itr if $args{holiday} eq $holidays[$itr];
	}
    }

    die "DateTime::Fiction::JRRTolkien::Shire: Invalid year given to new constructor\n" if not int($args{year});
    $self->{year} = $args{year};
    $self->{leapyear} = 0;
    $self->{leapyear} = 1 if $self->{year} % 4 == 0 and $self->{year} % 100 != 0;
    $self->{leapyear} = 1 if $self->{year} % 400 == 0;
    if ($args{holiday}) {
	die "DateTime::Fiction::JRRTolkien::Shire: Invalid holiday given to new constructor\n" 
	    if (int($args{holiday}) < 0) || (int($args{holiday}) > 6);
	die "DateTime::Fiction::JRRTolkien::Shire: Overlithe is only valid on leap years\n"
	    if $args{holiday} == 4 and not $self->{leapyear};
	$self->{holiday} = $args{holiday};
    } elsif ($args{month}) {
	die "DateTime::Fiction::JRRTolkien::Shire: Invalid month given to new constructor\n" 
	  if (int($args{month}) < 1) || (int($args{month}) > 12);
	die "DateTime::Fiction::JRRTolkien::Shire: Invalid day given to new constructor\n" 
	  if $args{day} and (int($args{day}) < 1) || (int($args{day}) > 30);
	$self->{month} = $args{month};
	$self->{day} = $args{day} || 1;
    } else {
	$self->{holiday} = 1;
    }

    foreach $arg (qw(hour minute second nanosecond time_zone locale)) { # for DateTime compatibility
	$dt_args{$arg} = $args{$arg} if defined $args{$arg};
    }
    $self->{recalc} = 1; # for weekday

    bless $self, $class;
    $self->_recalc_DateTime(%dt_args);

    return $self;
} # end sub new

sub from_epoch {
    my ($class, %args) = @_;
    my $self;

    $self->{dt} = DateTime->from_epoch(%args);
    $self->{recalc} = 1;

    return bless $self, $class;
} # end sub from_epoch

sub now {
    my ($class, %args) = @_;
    my $self;

    $self->{dt} = DateTime->now(%args);
    $self->{recalc} = 1;

    return bless $self, $class;
} # end sub now

sub today {
    my ($class, %args) = @_;
    my $self;

    $self->{dt} = DateTime->today(%args);
    $self->{recalc} = 1;

    return bless $self, $class;
} # end sub today

sub from_object {
    my ($class, %args) = @_;
    my $self;

    $self->{dt} = DateTime->from_object(%args);
    $self->{recalc} = 1;

    return bless $self, $class;
} # end sub from_object

sub last_day_of_month {
    my ($class, %args) = @_;
    $args{day} = 30; # The shire calendar is nice this way
    return $class->new(%args);
} # end sub last_day_of_month

sub from_day_of_year {
    my ($class, %args) = @_;
    my ($doy, $self, $leap);

    $doy = $args{day_of_year};
    delete $args{day_of_year};

    die "DateTime::Fiction::JRRTolkien::Shire: No year given to from_day_of_year constructor.\n" if not $args{year};
    $leap = 1 if $args{year} % 4 == 0 and $args{year} % 100 != 0;
    $leap = 1 if $args{year} % 400 == 0;
    if ($leap) {
	die "DateTime::Fiction::JRRTolkien::Shire: Invalid day given to from_day_of_year constructor.\n" if $doy > 366 or $doy < 1;
	if ($doy == 1) {
	    $args{holiday} = 1;
	} elsif ($doy == 182) {
	    $args{holiday} = 2;
	} elsif ($doy == 183) {
	    $args{holiday} = 3;
	} elsif ($doy == 184) {
	    $args{holiday} = 4;
	} elsif ($doy == 185) {
	    $args{holiday} = 5;
	} elsif ($doy == 366) {
	    $args{holiday} = 6;
	} else {
	    $doy -= 4 if $doy > 185; # Lithe's, midyear's day, and Overlithe
	    --$doy; # 2 Yule
	    $args{month} = int(($doy - 1) / 30) + 1;
	    $args{day} = (($doy - 1) % 30) + 1;
	}
    } else {
	die "DateTime::Fiction::JRRTolkien::Shire: Invalid day given to from_day_of_year constructor.\n" if $doy > 365 or $doy < 1;
	if ($doy == 1) {
	    $args{holiday} = 1;
	} elsif ($doy == 182) {
	    $args{holiday} = 2;
	} elsif ($doy == 183) {
	    $args{holiday} = 3;
	} elsif ($doy == 184) {
	    $args{holiday} = 5;
	} elsif ($doy == 365) {
	    $args{holiday} = 6;
	} else {
	    $doy -= 3 if $doy > 184; # Lithe's and midyear's day
	    --$doy; # 2 Yule
	    $args{month} = int(($doy - 1) / 30) + 1;
	    $args{day} = (($doy - 1) % 30) + 1;
	}
    }

    return $class->new(%args);
} # end sub from_day_of_year

sub clone { bless { %{ $_[0] } }, ref $_[0] } # Stolen from DateTime.pm

# Get methods
sub year { 
    my $self = shift;  
    $self->_recalc_Shire if $self->{recalc}; 
    return $self->{year}; 
} # end sub year

sub month { 
    my $self = shift;  
    $self->_recalc_Shire if $self->{recalc}; 
    return $self->{month}; 
} # end sub month

sub month_name {
    my $self = shift;
    my @months = ('', 'Afteryule', 'Solmath', 'Rethe', 'Astron', 'Thrimidge', 'Forelithe', 'Afterlithe', 
		  'Wedmath', 'Halimath', 'Winterfilth', 'Blotmath', 'Foreyule');
    return $months[$self->month];
} #end sub month_name

sub day_of_month {
    my $self = shift;  
    $self->_recalc_Shire if $self->{recalc}; 
    return $self->{day};
} # end sub day_of_month

sub day { return $_[0]->day_of_month; }
sub mday { return $_[0]->day_of_month; }

sub day_of_week {
    my $self = shift;  
    $self->_recalc_Shire if $self->{recalc}; 
    return $self->{wday};
} # end sub day_of_week

sub wday { return $_[0]->day_of_week; }
sub dow { return $_[0]->day_of_week; }

sub day_name {
    my $self = shift;
    my @days = ('', 'Sterday', 'Sunday', 'Monday', 'Trewsday', 'Hevensday', 'Mersday', 'Highday');
    return $days[$self->day_of_week];
} # end sub day_name

sub day_name_trad {
    my $self = shift;
    my @days = ('', 'Sterrendei', 'Sunnendei', 'Monendei', 'Trewesdei', 'Hevenesdei', 'Meresdei', 'Highdei');
    return $days[$self->day_of_week];
} # end sub trad_day_name

sub holiday {
    my $self = shift;  
    $self->_recalc_Shire if $self->{recalc}; 
    return $self->{holiday};
} # end sub holiday

sub holiday_name {
    my $self = shift;
    my @holidays = ('', '2 Yule', '1 Lithe', "Midyear's day", 'Overlithe', '2 Lithe', '1 Yule');
    return $holidays[$self->holiday];
} # end sub holiday_name

sub is_leap_year { 
    my $self = shift;  
    $self->_recalc_Shire if $self->{recalc}; 
    return $self->{leapyear};
} # end is_leap_year

sub day_of_year {
    my $self = shift;
    my $yday;
    $self->_recalc_Shire if $self->{recalc};

    if ($self->{month}) { # holidays aren't part of any month
	$yday = 30 * ($self->{month} - 1) + $self->{day} + 1;  # + 1 is for the 2 Yule
	if ($self->{month} > 6) {
	    $yday += 3;
	    ++$yday if $self->{leapyear};
	}
    } else {
	if ($self->{leapyear}) {
	    $yday = (0, 1, 182, 183, 184, 185, 366)[$self->{holiday}];
	} else {
	    $yday = (0, 1, 182, 183, 0, 184, 365)[$self->{holiday}];
	}
    }

    return $yday;
} # end sub day_of_year

sub doy { return $_[0]->day_of_year };

sub week { return ($_[0]->week_year, $_[0]->week_number); }

sub week_year { return $_[0]->year; } # the shire calendar is nice this way

sub week_number {
    my $self = shift;
    my $yday = $self->day_of_year;

    183 == $yday
	and return 0;	# Midyear's day has no week number
    184 == $yday
	and $self->is_leap_year
	and return 0;	# The Overlithe has no week number either.

    --$yday if $yday > 182; # don't count Midyear's day
    --$yday if $yday > 182 and $self->is_leap_year; # don't count the Overlithe

    return int(($yday - 1) / 7) + 1;
} # end sub week_number

sub epoch { return $_[0]->{dt}->epoch; }
sub hires_epoch { return $_[0]->{dt}->hires_epoch; }
sub utc_rd_values { return $_[0]->{dt}->utc_rd_values; }
sub utc_rd_as_seconds { return $_[0]->{dt}->utc_rd_as_seconds; }

# Set methods

sub set {
    my ($self, %args) = @_;
    my (%dt_args, $arg, $itr);
    my @months = ('', 'Afteryule', 'Solmath', 'Rethe', 'Astron', 'Thrimidge', 'Forelithe', 'Afterlithe', 
		  'Wedmath', 'Halimath', 'Winterfilth', 'Blotmath', 'Foreyule');
    my @holidays = ('', '2 Yule', '1 Lithe', "Midyear's day", 'Overlithe', '2 Lithe', '1 Yule');
    $self->_recalc_Shire if $self->{recalc};

    if ($args{month}) {
	foreach $itr (1..12) {
	    $args{month} = $itr if $args{month} eq $months[$itr];
	}
    }
    if ($args{holiday}) {
	foreach $itr (1..6) {
	    $args{holiday} = $itr if $args{holiday} eq $holidays[$itr];
	}
    }

    $self->{year} = $args{year} || $self->{year};
    $self->{leapyear} = 0;
    $self->{leapyear} = 1 if $self->{year} % 4 == 0 and $self->{year} % 100 != 0;
    $self->{leapyear} = 1 if $self->{year} % 400 == 0;
    if ($self->{holiday}) {
	if ($args{holiday}) {
	    $self->{holiday} = $args{holiday};
	} else {
	    $self->{holiday} = 0;
	    $self->{month} = $args{month} || 1;
	    $self->{day} = $args{day} || 1;
	}
    } else {
	if ($args{holiday}) {
	    $self->{holiday} = $args{holiday};
	    $self->{month} = 0;
	    $self->{day} = 0;
	} else {
	    $self->{month} = $args{month} || $self->{month};
	    $self->{day} = $args{day} || $self->{day};
	}
    }

    if ($self->{holiday}) {
	die "DateTime::Fiction::JRRTolkien::Shire: Invalid holiday given to set method\n" 
	    if (int($self->{holiday}) < 0) || (int($self->{holiday}) > 6);
	die "DateTime::Fiction::JRRTolkien::Shire: Overlithe is only valid on a leap year\n"
	    if $self->{holiday} == 4 and not $self->{leapyear};
    } else {
	die "DateTime::Fiction::JRRTolkien::Shire: Invalid month given to set method\n" 
	    if (int($self->{month}) < 1) || (int($self->{month}) > 12);
        die "DateTime::Fiction::JRRTolkien::Shire: Invalid day given to set method\n" 
	    if (int($self->{day}) < 1) || (int($self->{day}) > 30);
    }
    
    foreach $arg (qw(hour minute second nanosecond locale)) {
	$dt_args{$arg} = $args{$arg} if defined $args{$arg};
    }
   
    $self->_recalc_DateTime(%dt_args);
    $self->{recalc} = 1; # for the weekday

    return $self;
} # end sub set

sub truncate {
    my ($self, %args) = @_;
    my ($info, %greg);
    $self->_recalc_Shire if $self->{recalc};

    if ($args{to} eq 'year') {
	$self->set( year => $self->{year}, holiday => 1, hour => 0, minute => 0, second => 0, nanosecond => 0);
    } elsif ($args{to} eq 'month') {
	if ($self->{holiday}) { # since holidays aren't in any month, this means we just lop off any time
	    $self->{dt}->truncate(to => 'day');
	} else {
	    $self->set( year => $self->{year}, month => $self->{month}, day => 1, hour => 0, minute => 0, second => 0, nanosecond => 0);
	}
    } else { # only time components will change, DateTime can handle it fine on its own
	$self->{dt}->truncate(to => 'day');
    }

    return $self;
} # end sub truncate

sub set_time_zone { 
    my ($self, $tz) = @_;
    $self->{dt}->set_time_zone($tz);
    $self->{recalc} = 1; # in case the day flips when the timezone changes
} # end sub set_time_zone

# Comparison overloads come with DateTime.  Stringify will be our own
use overload('<=>', \&compare);
use overload('cmp', \&compare);
use overload('""'  => \&stringify);

sub compare { return $_[0]->{dt} <=> $_[1]->{dt}; }

sub stringify {
    my $self = shift;
    my $returntext;
    $self->_recalc_Shire if $self->{recalc};

    if ($self->{holiday}) {
	if ($self->{wday}) {
	    $returntext = $self->day_name . " " . $self->holiday_name . " " . $self->{year};
	} else {
	    $returntext = $self->holiday_name . " " . $self->{year};
	}
    } else {
	$returntext = $self->day_name . " " . $self->{day} . " " . $self->month_name  . " " . $self->{year};
    }

    return $returntext;
} # stringify

sub on_date {
    my $self = shift;
    my ($returntext, %events);
    $self->_recalc_Shire if $self->{recalc};

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
		   14 => "The Company of the Ring spends the night in Moria Hall 21, 1419.\n",
		   15 => "The Bridge of Khazad-dum, and fall of Gandalf, 1419.\n",
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
		   29 => "Meriadoc and Pippin escape and meet Treebeard, 1419.\n" .
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
    $events{4} = { 6  => "The mallorn tree flowers in the Party Field, 1420.\n",
	           8  => "Ring bearers are honored on the Field of Cormallen, 1419.\n",
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
    } elsif (defined($events{$self->{month}}->{$self->{day}})) {
	$returntext .= "$self\n\n" . $events{$self->{month}}->{$self->{day}};
    } else {
	$returntext = "$self\n";
    }

    return $returntext;
} #end sub on_date

__END__

=head1 NAME

DateTime::Fiction::JRRTolkien::Shire.pm

=head1 SYNOPSIS

    use DateTime::Fiction::JRRTolkien::Shire;

    # Constructors
    my $shire = DateTime::Fiction::JRRTolkien::Shire->new(year => 1419,
                                                          month => 'Rethe',
                                                          day => 25);
    my $shire = DateTime::Fiction::JRRTolkien::Shire->new(year => 1419,
                                                          month => 3,
                                                          day => 25);
    my $shire = DateTime::Fiction::JRRTolkien::Shire->new(year => 1419,
                                                          holiday => '2 Lithe');

    my $shire = DateTime::Fiction::JRRTolkien::Shire->from_epoch(epoch = $time);
    my $shire = DateTime::Fiction::JRRTolkien::Shire->today; # same as from_epoch(epoch = time());

    my $shire = DateTime::Fiction::JRRTolkien::Shire->from_object(object => $some_other_DateTime_object);
    my $shire = DateTime::Fiction::JRRTolkien::Shire->from_day_of_year(year => 1420,
                                                                       day_of_year => 182);
    my $shire2 = $shire->clone;

    # Accessors
    $year = $shire->year;
    $month = $shire->month;            # 1 - 12, or 0 on a holiday
    $month_name = $shire->month_name;
    $day = $shire->day;                # 1 - 30, or 0 on a holiday

    $dow = $shire->day_of_week;        # 1 - 7, or 0 on certain holidays
    $day_name = $shire->day_name;

    $holiday = $shire->holiday;
    $holiday_name = $shire->holiday_name;

    $leap = $shire->is_leap_year;

    $time = $shire->epoch;
    @rd = $shire->utc_rd_values;

    # Set Methods
    $shire->set(year => 7463,
                month => 5,
                day => 3);
    $shire->set(year => 7463,
                holiday => 6);
    $shire->truncate(to => 'month');

    # Comparisons
    $shire < $shire2;
    $shire == $shire2;

    # Strings
    print "$shire1\n"; # Prints Sunday 25 Rethe 1419

    # On this date in history
    print $shire->on_date;

=head1 DESCRIPTION
 
Implementation of the calendar used by the hobbits in J.R.R. Tolkien's exceptional
novel The Lord of The Rings, as described in Appendix D of that book 
(except where noted).  The calendar has 12 months, each with 30 days, and 5
holidays that are not part of any month.  A sixth holiday, Overlithe, is added on 
leap years.  The holiday Midyear's Day (and the Overlithe on a leap year) is
not part of any week, which means that the year always starts on Sterday.

This module is a follow on to the Date::Tolkien::Shire module, and is rewritten
to support Dave Rolsky and company's DateTime module.  The DateTime module must
be installed for this module to work.  Unlike the DateTime module, which includes
time support, this calendar does not have any mechanisms for giving a shire 
time (mostly because I've never quite figured out what it should look like).
Time is maintained, however, so that objects can be converted from other
calendars to the shire calendar and then converted back without their time components
being lost.  The same is true of time zones.

=head1 METHODS

Most of these methods mimic their corresponding DateTime methods in functionality.
For additional information on these methods, see the DateTime documentation.

=over 4

=head2 Constructors

=item * new( ... )

This method takes a year, month, and day parameter, or a year and holiday parameter.
The year can be any value.  The month can be specified with a string giving the name
of the month (the same string that would be returned by month_name, with the first letter 
capitalized and the rest in lower case) or by giving the numerical value for the month,
between 1 and 12.  The day should always be between 1 and 30.  If a holiday is given 
instead of a day and month, it should be the name of the holiday as returned by 
holiday_name (with the first letter of each word capitalized) or a value between 1 
and 6.  The 1 through 6 numbers map to holidays as follows:
    1 => 2 Yule
    2 => 1 Lithe
    3 => Midyear's Day
    4 => Overlithe      # Leap years only
    5 => 2 Lithe
    6 => 1 Yule

The new method will also take parameters for hour, minute, second, nanosecond, time_zone
and locale.  If given, these parameters will be stored in case the object is converted to
another class that supports times.

If a day is not given, it will default to 1.  If neither a day or month is given,
the date will default to 2 Yule, the first day of the year.

=item * from_epoch( epoch => $epoch, ... )

Same as in DateTime.

=item * now( ... )

Same as in DateTime.  Note that this is equivalent to 
    from_epoch( epoch => time() );

=item * today( ... )

Same as in DateTime.  

=item * from_object( object => $object, ... )

Same as in DateTime.  Takes any other DateTime calendar object and converts it to
a DateTime::Fiction::JRRTolkien::Shire object.

=item * last_day_of_month( ... )

Same as in DateTime.  Like the new constructor, but it does not take a day parameter.  
Instead, the day is set to 30, which is the last day of any month in the shire 
calendar.  A holiday parameter should not be used with this method.  Use new instead.

=item * from_day_of_year( year => $year, day_of_year => $yday)

Same as in DateTime.  Gets the date from the given year and day of year, both
of which must be given.  Hour, minute, second, time_zone, etc. parameters
may also be given, and will be passed to the underlying DateTime object, just
like in new.

=item * clone

Creates a new Shire object that is the same date (and underlying time)
as the calling object.

=head2 Get Methods

=item * year

returns the year.

=item * month

Returns the month number, from 1 to 12.  If the date is a holiday, 
a 0 is returned for the month.

=item * month_name

Returns the name of the month.  If the date is a holiday, an empty
string is returned.

=item * day_of_month, day, mday

Returns the day of the current month, from 1 to 30.  If the date is a
holiday, 0 is returned.

=item * day_of_week, wday, dow

Returns the day of the week from 1 to 7.  If the day is not part of
any week (Midyear's Day or the Overlithe), 0 is returned.

=item * day_name

Returns the name of the day of the week, or an empty string if the
day is not part of any week.

=item * day_name_trad

Like day_name, but returns the more traditional name of the days
of the week, as defined in Appendix D.

=item * day_of year, doy

Returns the day of the year, from 1 to 366

=item * holiday

Returns the holiday number (given in the description of the new constructor).
If the day is not a holiday, 0 is returned.

=item * holiday_name

Returns the name of the holiday.  If the day is not a holiday, an empty string
is returned.

=item * is_leap_year

Returns 1 if the year is a leap year, and 0 otherwise.  

Leap years are given
the same rule as the Gregorian calendar.  Every four years is a leap year,
except the first year of the century, which is not a leap year.  However,
every fourth century (400 years), the first year of the century is a leap 
year (every 4, except every 100, except every 400).  This is a slight
change from the calendar descibed in Appendix D, which uses the rule of 
once every 4 years, except every 100 years (the same as in the Julian 
calendar).  Given some uncertainty about how many years have passed
since the time in Lord of the Rings (see note below), and the expectations
of most people that the years match up with what they're used to, I have
changed this rule for this implementation.  However, this does mean that 
this calendar implementation is not strictly that described in Appendix D.

=item * week

A two element array, where the first is the week_year and the latter is the week_number.

=item * week_year

This is always the same as the year in the shire calendar, but is present for
compatability with other DateTime objects.

=item * week_number

Returns the week of the year.

=item * epoch

Returns the epoch of the given object, just like in DateTime.

=item * hires_epoch

Returns the epoch as a floating point number, with the fractional portion
for fractional seconds.  Functions the same as in DateTime.

=item * utc_rd_values

Returns the UTC rata die days, seconds, and nanoseconds. Ignores fractional
seconds.  This is the standard method used by other methods to convert 
the shire calendar to other calendars.  See the DateTime documentation for
more information.

=item * utc_rd_as_seconds

Returns the UTC rata die days entirely as seconds.  

=item * on_date

Prints out the current day.  If the day has some events that transpired on it
(as defined in Appendix B of the Lord of the Rings), those events are also printed.
This can be fun to put in a .bashrc or .cshrc.  Try

    perl -MDateTime::Fiction::JRRTolkien::Shire 
      -le 'print DateTime::Fiction::JRRTolkien::Shire->now->on_date;'

=head2 Set Methods

=item * Set( ... )

Allows the day, month, and year to be changed.  It takes any parameters allowed
by new constructor, including all those supported by DateTime and the holiday parameter,
except for time_zone.  This is used in much the same way as new, with the 
exception that any parameters not given will be left as is.

All parameters are optional, with the current values inserted if the values are not
supplied.  However, with holidays not falling in any month, it is recommended
that a day and month always be given together.  Otherwise, unanticipated
results may occur.

As in the new constructor, time parameters have no effect on the shire dates 
returned.  However, they are maintained in case the object is converted to another
calendar which supports time.

=item * Truncate( ... )

Same as in DateTime.  If the date is a holiday, a truncation to either
'month' or 'day' is equivalent.  Otherwise, this functions as specified in the
DateTime object.

=item * set_time_zone( $tz )

Just like in DateTime.  This method has no effect on the shire calendar, but be
stored with the date if it is ever converted to another calendar with time support.

=head2 Comparisons and Stringification

All comparison operators should work, just as in DateTime.  In addition,
all DateTime::Fiction::JRRTolkien::Shire objects will interpolate into
a string representing the date when used in a double-quoted string.  

=back

=head1 DURATIONS AND DATE MATH

Durations and date math (other than comparisons) are not supported at present
on this module (patches are always welcome).  If this is needed, there are a couple
of options.  If workig with dates within epoch time, the dates can be converted
to epoch time, the math done, and then converted back.  Regardless of the dates,
the shire objects can also be converted to DateTime objects, the math done with
the DateTime class, and then the DateTime object converted back to a Shire object.

=head1 NOTE: YEAR CALCULATION

http://www.glyhweb.com/arda/f/fourthage.html references a letter sent by
Tolkien in 1958 in which he estimates approxiimately 6000 years have passed
since the War of the Ring and the end of the Third Age.  (Thanks to Danny
O'Brien from sending me this link).  I took this approximate as an exact amount
and calculated back 6000 years from 1958.  This I set as the start of the 
4th age (1422 S.R.).  Thus the fourth age begins in our B.C 4042.

According to Appendix D of the Lord of the Rings, leap years in hobbit
calendar are every 4 years unless its the turn of the century, in which
case it's not a leap year.  Our calendar (Gregorian) uses every 4 years unless it's 
100 years unless its 400 years.  So, if no changes have been made to 
the hobbit's calendar since the end of the third age, their calendar would
be about 15 days further behind ours now then when the War of the Ring took
place.  Implementing this seemed to me to go against Tolkien's general habit
of converting dates in the novel to our equivalents to give us a better
sense of time.  My thoughts, at least right now, is that it is truer to the
spirit of things for years to line up, and for Midyear's day to still be 
approximately on the summer solstice.  So instead, I have modified Tolkien's 
description of the hobbit 
calendar so that leap years occur once every 4 years unless it's 100
years unless it's 400 years, so as it matches the Gregorian calendar in that
regard.  These 100 and 400 year intervals occur at different times in
the two calendars, so there is not a one to one correspondence
of days regardless of years.  However, the variations follow a 400 year cycle.

=head1 AUTHOR

Tom Braun <tbraun@pobox.com>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2003 Tom Braun.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.
                                                                                
The calendar implemented on this module was created by J.R.R. Tolkien,
and the copyright is still held by his estate.  The license and 
copyright given herein applies only to this code and not to the 
calendar itself.
                                                                   
The full text of the license can be found in the LICENSE file included
with this module.

=head1 SUPPORT

Support on this module may be obtained by emailing me.  However,
I am not a developer on the other classes in the DateTime project.  For
support on them, please see the support options in the DateTime documentation.

=head1 BIBLIOGRAPHY

Tolkien, J. R. R. <i>Return of the King<i>.  New York: Houghton Mifflin Press,
1955.

http://www.glyphweb.com/arda/f/fourthage.html

=head1 SEE ALSO

The DateTime project documentation (perldoc DateTime, datetime@perl.org mailing list,
or http://datetime.perl.org/).

=cut

1;
