package Date::Holidays::NZ;
use strict;
use base qw(Exporter);

our $SET;
BEGIN {
    eval { require Set::Scalar };
    if ($@) {
	require Set::Object;
        die "Need at least Set::Object 1.09"
	    if ($Set::Object::VERSION < 1.09);
	$SET = "Set::Object";
    } else {
	$SET = "Set::Scalar";
    }
}

use vars qw($VERSION @EXPORT @EXPORT_OK);
$VERSION = '1.02';
@EXPORT = qw(is_nz_holiday nz_holidays nz_regional_day nz_holiday_date);
@EXPORT_OK = qw(%HOLIDAYS $NATIONAL_HOLIDAYS %regions
		nz_region_code nz_region_name %holiday_cache);

my $AD = "Anniversary Day";

our %HOLIDAYS
    = (
       # holidays that everyone gets, unless they fall on a weekend,
       # in which case you only get them "if you would normally have
       # worked on that day (of the week)
       "Waitangi Day" => "0206",
       "ANZAC Day" => "0425",

       # holidays which are fixed, but unless you would "normally have
       # worked on that day", then they are moved to the next working
       # day
       "New Years Day" => "0101+",
       "Day after New Years Day" => '0102+',
       "Christmas Day" => "1225+",
       "Boxing Day" => '1226+',

       # other nationwide holidays
       "Easter Monday" => "Easter + 1day",
       "Good Friday" => "Easter - 2days",
       "Queens Birthday" => '1st Monday in June',
       "Labour Day" => "4th Monday in October",

       # Anniversary days - these are the official dates, but regional
       # authorities and sometimes district councils pick the actual
       # dates.
       "Auckland $AD" => "Closest Monday to 0129",

       #"Taranaki $AD" => "Closest Monday to 0331",
       # Moves to 2nd Monday in March to avoid Easter.
       "Taranaki $AD" => "2nd Monday in March",

       #"Hawkes' Bay $AD" => "Closest Monday to 1101",
       # Moved to Friday before Labour Day.
       "Hawkes' Bay $AD" => "4th Monday in October - 3days",

       "Wellington $AD" => "Closest Monday to 0122",

       # "Marlborough $AD"  => "Closest Monday to 1101",
       # Observed 1st Monday after Labour Day.
       "Marlborough $AD" => "4th Monday in October + 7days",

       "Nelson $AD" => "Closest Monday to 0201",

       #"Westland $AD" => "Closest Monday to 1201",
       "Westland $AD" => "1st monday in december",

       # ``Varies throughout Westland, but Greymouth observes the
       # official day.'' - that's the West Coast for you

       "Otago $AD" => "Closest Monday to 0323",
       "Southland $AD" => "Closest Monday to 0117",
       "Chatham Islands $AD" => "Closest Monday to 1130",

       # oddballs
       #"Canterbury $AD" => "Closest Monday to 1216",
       "Dominion Day" => "4th Monday in September",
       "Christchurch Show Day" => "1st Tuesday in November + 10d",
      );

our $NATIONAL_HOLIDAYS =
    $SET->new( "Waitangi Day",
		      "ANZAC Day",
		      "New Years Day",
		      "Day after New Years Day",
		      "Christmas Day",
		      "Boxing Day",
		      "Easter Monday",
		      "Good Friday",
		      "Queens Birthday",
		      "Labour Day",
		    );

our %holiday_aliases =
    ( "Birthday of the Reigning Sovereign" => "Queens Birthday",
    );

# These are Census 2001 region codes.
our %regions =
    (
      1 => "Northland",
      2 => "Auckland",
      3 => "Waikato",
      4 => "Bay of Plenty",
      5 => "Gisbourne",
      6 => "Hawkes' Bay",
      7 => "Taranaki",
      8 => "Manuwatu-Wanganui",
      9 => "Wellington",
      12 => "West Coast",
      13 => "Canterbury",
      -13 => "Canterbury (South)",  # tsk!  naughty use of sign bit
      14 => "Otago",
      15 => "Southland",
      16 => "Tasman",
      17 => "Nelson",
      18 => "Marlborough",
      99 => "Outside Regional Authority (incl. Chatham Is)",
    );
our %rev_regions;

# which anniversary days are followed by each region is largely
# educated guesses, please e-mail samv@cpan.org if this list is
# incorrect.
our %FOLLOW = ( 1 => 2, 3 => 2, 4 => 5, 5 => 6,
	       8 => 9, 12 => "Westland",
	       13 => "Christchurch Show Day",
	       -13 => "Dominion Day",
	       16 => 17,
	       99 => "Chatham Islands",
	     );

use Scalar::Util qw(looks_like_number);
use Carp qw(croak);

sub rev_regions {
    my $region_name = shift;
    unless ( $rev_regions{Auckland} ) {
	%rev_regions = map { lc($_) } reverse %regions;
    }
    return $rev_regions{lc($region_name)}
	|| croak "`$region_name' is not a valid NZ region name";
}

sub nz_region_name {
    my $region = shift;
    return undef unless defined $region;
    if ( looks_like_number($region) ) {
	return $regions{$region}
	    || croak "no such NZ region code `$region'";
    } else {
	return $regions{rev_regions($region)};
    }
}

sub nz_region_code {
    my $region = shift;
    return undef unless defined $region;
    if ( looks_like_number($region) ) {
	exists $regions{$region}
	    or croak "no such NZ region code `$region'";
	return $region;
    } else {
	return rev_regions($region);
    }
}

# try to guess the regional day observed from the region
sub nz_regional_day {
    my $label = shift or return undef;

    if ( !looks_like_number($label) and
	 exists $HOLIDAYS{$label." $AD"} ) {
	return "$label $AD";
    }
    my $region = nz_region_code($label);
    my $followed;
    if ( $followed = $FOLLOW{$region} ) {
	if ( looks_like_number($followed) ) {
	    $followed = nz_region_name($followed);
	}
    }
    else {
	$followed = nz_region_name($region);
    }
    if ( $followed !~ /Day$/ ) {
	$followed .= " $AD";
    }
    return $followed;
}

sub check_falling_on {
    my ($h, $year, $date) = @_;

	my $falls_on = UnixDate($year.$date, "%w");
	if ( $falls_on >= 6 ) {
	    my $name = delete $h->{$date};
	    #print STDERR "Blast, $name falls on a ".UnixDate($year.$date, "%A"). " ($falls_on)\n";
	    my $add = ($falls_on + 2) % 7;
	    #print STDERR "Adding $add days to it.\n";
	    my $to_fall_on = UnixDate(DateCalc($year.$date, "+${add}d"), "%m%d");
	    #print STDERR "Trying $to_fall_on instead.\n";
	    while ( exists $h->{$to_fall_on} or
		    UnixDate($year.$to_fall_on, "%w") >= 6
		  ) {
		$to_fall_on = UnixDate(DateCalc($year.$to_fall_on, "+1d"), "%m%d");
		#print STDERR "That's no bloody good, trying $to_fall_on instead.\n";
	    }
	    #print STDERR "Settling on $to_fall_on ($name Holiday)\n";
	    $h->{$to_fall_on} = "$name Holiday";
	}
}

use Date::Manip qw(DateCalc ParseDate UnixDate ParseRecur);

sub interpret_date {
    my $year = shift;
    my $value = shift;

    my ($date, $add);
    if ( $value =~ m/^(\d\d)(\d\d)\+?$/ ) {
	return $value;
    }
    elsif ( $value =~ m/^(\d+(?:st|nd|rd|th) \w+day in \w+)(.*)$/i) {
	(my $spec, $add) = ($1, $2);
	$date = ParseDate($spec. " $year");
    }
    elsif ( $value =~ m/^Closest (\w+day) to (\d\d)(\d\d)(.*)$/i) {
	#print STDERR "**** $value($year):\n";
	(my ($day, $month, $dom), $add) = ($1, $2, $3, $4);
	$date = ParseDate("$year-$month-$dom");
	my $wanted = UnixDate($day, "%w");
	my $got    = UnixDate($date, "%w");
	#print STDERR "    $year-$month-$dom is a ".UnixDate($date, "%A")
	    #." ($got)\n";
	if ( my $diff = ($wanted - $got + 7) % 7 ) {
	    #print STDERR "    difference is $diff days\n";
	    if ( $diff < 4 ) {
		#print STDERR "Adding $diff days\n";
		$date = DateCalc($date, "+${diff}d");
	    } else {
		$diff = 7 - $diff;
		#print STDERR "Subtracting $diff days\n";
		$date = DateCalc($date, "-${diff}d");
	    }
	} else {
	    #print STDERR "Which is good\n";
	}
    }
    elsif ( $value =~ m/^Easter(.*)$/i) {
	($date) = ParseRecur("*$year:0:0:0:0:0:0*EASTER");
	$add = $1;
    }
    $date = DateCalc($date, "$add") if $add;
    return UnixDate($date, "%m%d");
}

sub nz_stat_holidays {
    my $year = shift;

    # build the relative dates
    my (%h, @tentative);
    foreach my $holiday ($NATIONAL_HOLIDAYS->members) {

	my $when = interpret_date($year, $HOLIDAYS{$holiday}||die)
	    or die "couldn't interpret $year, $HOLIDAYS{$holiday}";

	if ( $when =~ s/\+// ) {
	    push @tentative, $when;
	}
	$h{$when} = $holiday;
    }
    for my $date ( sort { $a <=> $b } @tentative ) {
	check_falling_on(\%h, $year, $date);
    }

    return \%h;
}

our %regional_holiday_cache
    = # exceptions
    ( "2004/Westland $AD" => "1129",
      "2008/Hawkes' Bay $AD" => "1017",
      "2008/Otago $AD" => "0325",
    );

our %holiday_cache;

sub nz_holidays {
  my ($year, $region) = @_;

  my $hols = $holiday_cache{$year} ||= nz_stat_holidays($year);

  if ( $region ) {
      my $rd = nz_regional_day($region);

      my $when = $regional_holiday_cache{"$year/$rd"} ||=
	  (interpret_date($year, $HOLIDAYS{$rd}||die)
	   or die "couldn't interpret $year, $HOLIDAYS{$rd}");

      $hols = { %$hols, $when => "$rd" };
  }

  return $hols;
}

sub is_nz_holiday {
  my ($year, $month, $day, $region) = @_;
  my $mmdd = sprintf("%.2d%.2d", $month, $day);

  my $hols = $holiday_cache{$year} ||= nz_stat_holidays($year);

  if ( exists $hols->{$mmdd} ) {
      return $hols->{$mmdd};
  }

  if ( $region ) {
      my $rd = nz_regional_day($region);

      my $when = $regional_holiday_cache{"$year/$rd"} ||=
	  (interpret_date($year, $HOLIDAYS{$rd}||die)
	   or die "couldn't interpret $year, $HOLIDAYS{$rd}");

      if ( $when eq $mmdd ) {
	  return $rd;
      }
  }

  return undef;
}

sub nz_holiday_date {
    my ($year, $holname) = @_;
    $holname = $holiday_aliases{$holname} if $holiday_aliases{$holname};
    exists $HOLIDAYS{$holname} or croak "no such holiday $holname";

    if ( $NATIONAL_HOLIDAYS->has($holname) ) {
	my $date = interpret_date($year, $HOLIDAYS{$holname});
	my $hols = nz_holidays($year);

	if ( $date =~ s/\+$// ) {
	    while ( not exists $hols->{$date} or
		    $hols->{$date} !~ m/^\Q$holname\E/i
		  ) {
		die "couldn't find it!" if $date eq "1231";
		$date = UnixDate(DateCalc($year.$date, "+1d"), "%m%d");
	    }
	}

	return $date;
    } else {
	return $regional_holiday_cache{"$year/$holname"}
		|| interpret_date($year, $HOLIDAYS{$holname});
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Date::Holidays::NZ - Determine New Zealand public holidays

=head1 SYNOPSIS

  use Date::Holidays::NZ;
  my ($year, $month, $day) = (localtime)[ 5, 4, 3 ];
  $year  += 1900;
  $month += 1;
  print "Woohoo" if is_nz_holiday( $year, $month, $day );

  # supply Census 2001 region codes (1-19), or names like
  # "Wellington", "Canterbury (South)", etc
  print "Yes!" if is_nz_holiday( $year, $month, $day, $region );

  my $h = nz_holidays($year);
  printf "Dec. 25th is named '%s'\n", $h->{'1225'};

=head1 DESCRIPTION

Determines whether a given date is a New Zealand public holiday or
not.

As described at
L<http://www.ers.dol.govt.nz/holidays_act_2003/dates/>, the system of
determining holidays in New Zealand is a complicated matter.  Not only
do you need to know what region the country is living in to figure out
the relevant Anniversary Day, but sometimes the district too (for the
West Coast and Canterbury).  As regions are free to pick the actual
days observed for particular holidays, this module cannot guarantee
dates past the last time it was checked against the Employment
Relations Service web site (currently returns known good values for
statutory holidays 2003 - 2009 and regional holidays for 2005).

This module hopes to return values that are Mostly Right(tm) when
passed in census 2001 region codes (widely used throughout government
and industry), and can also be passed in textual region labels, which
includes the appropriate Anniversary Day.

Also, there is a difference between what is considered a holiday by
the Holidays Act 2003 - and hence entitling a person to time in lieu
and/or extra pay - and what is considered to be a Bank Holiday.  This
module returns Bank Holiday dates, so if Christmas Day falls on a
Sunday, the 26th will be called "Boxing Day", and the 27th "Christmas
Day Holiday".


=head1 Functions

=over 4

=item is_nz_holiday($year, $month, $date, [$region])

Returns the name of the Holiday that falls on the given day, or undef
if there is none.

Optionally, a region may be specified, which also checks the
anniversary day applicable to that region.

=item nz_holidays($year, [$region])

Returns a hashref of all defined holidays in the year. Keys in the
hashref are in 'mmdd' format, the values are the names of the
holidays.

As per the previous function, a region name may be specified.  If you
do not specify a region, then no regional holidays are included in the
returned hash.

=item nz_regional_day($region)

Returns the name of the regional holiday for the specified region.

This can be passed into the next function to find the actual date for
a given year.

Valid regions are:

  Number    Region Name
    1       Northland
    1       Northland
    2       Auckland
    3       Waikato
    4       Bay of Plenty
    5       Gisbourne
    6       Hawkes' Bay
    7       Taranaki
    8       Manuwatu-Wanganui
    9       Wellington
    12      West Coast
    13      Canterbury
   -13      Canterbury (South)
    14      Otago
    15      Southland
    16      Tasman
    17      Nelson
    18      Marlborough
    99      Outside Regional Authority

Note: for the purposes of calculating a holiday, 99 is considered to
be Chatham Islands, as there is no Regional Authority there.

Sorry about the -13 for South Canterbury.  That's a bit of a hack.
Better ideas welcome.

=item nz_holiday_date($year, $holiday)

Return the actual day that a given holiday falls on for a particular
year.

Valid holiday names are:

  ANZAC Day
  Boxing Day
  Christmas Day
  Day after New Years Day
  Dominion Day
  Easter Monday
  Good Friday
  Labour Day
  New Years Day
  Queens Birthday
  Waitangi Day
  
  Auckland Anniversary Day
  Chatham Islands Anniversary Day
  Christchurch Show Day
  Hawkes' Bay Anniversary Day
  Marlborough Anniversary Day
  Nelson Anniversary Day
  Otago Anniversary Day
  Southland Anniversary Day
  Taranaki Anniversary Day
  Wellington Anniversary Day
  Westland Anniversary Day

Somebody let me know if any of those are incorrect.

C<Date::Holidays::NZ> version 1.00 and later also supports referring
to Queen's Birthday as "Birthday of the Reigning Sovereign".  Not that
it has anything to do with the Queen's Birthday, really - it's just
another day off to stop us British subjects getting all restless,
revolutionary and whatnot.

=back

=head1 ERRATA

Otago Anniversary Day is due to fall on Easter Monday in 2035 and 2046.
When this happened in 2008, the council made Easter Tuesday the
anniversary day; however this is not currently codified as a general
rule, as it is up to the council to declare this in advance.  This was
only fixed in Date::Holidays::NZ 1.02, which was released very close
to the actual anniversary day - apologies for the delay in the update.
For those days (in 2035 and beyond), depending on which method you
call you might get a different answer as to why that day is a holiday
for that region.

Also in 1.02 was a fix which affected functions which would return
the "normal" day for a holiday, rather than the day listed on the
official government site, for a couple of regional days which did not
match the general rule for when they were due.

Note that district councils are free to alter the holidays schedule at
any time.  Also, strictly speaking, it is the Pope that decides the
date of Easter, upon which Easter Friday and Monday are based.

I'm not entirely sure on which Anniversary Day the following NZ
regions observe, so if it matters for you, please check that it is
correct and let me know if I need to fix anything:

=over

=item *

Waikato (assumed Auckland)

=item *

BOP (assumed Auckland)

=item *

Gisbourne (assumed Hawkes' Bay)

=item *

Tasman (assumed Nelson)

=item *

Area 99 - that is, areas outside regional authority.  The biggest one
of these is the Chatham Islands, so this module assumes Region 99 is
the Chatham Islands.

=back

Maybe someone can shed some light on the situation in the West Coast,
although this is confounded by the matter that the whole concept of
holidays or even time there is only a loosely observed phenomenon.

=head1 EXPORTS

Exports the four listed functions in this manual page by default.

You may also import various internal variables and methods used by
this module if you like.  Log a ticket if you want any of them to be
added to the documentation.

=head1 BUGS

This module does not support Te Reo Māori.  If you would be interested
in translating the holiday names, region names or manual page to
Māori, please contact the author.

Please report issues via CPAN RT:

  http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Holidays-NZ

or by sending mail to

  bug-Date-Holidays-NZ@rt.cpan.org

=head1 AUTHORS

Modified for NZ holidays by Sam Vilain <samv@cpan.org>, from
Date::Holidays::DK, by Lars Thegler <lars@thegler.dk>

=head1 COPYRIGHT

portions:

Copyright (c) 2004 Lars Thegler. All rights reserved.

some modifications

Copyright (c) 2005, 2008, Sam Vilain. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

