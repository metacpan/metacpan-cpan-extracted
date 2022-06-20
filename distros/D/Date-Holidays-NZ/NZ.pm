package Date::Holidays::NZ;
use strict;
use base qw(Exporter);
use utf8;

use vars qw($VERSION @EXPORT @EXPORT_OK);
$VERSION = '1.06';
@EXPORT = qw(is_nz_holiday nz_holidays nz_regional_day nz_holiday_date);
@EXPORT_OK = qw(%HOLIDAYS @NATIONAL_HOLIDAYS %regions
		nz_region_code nz_region_name %holiday_cache);

my $AD = "Anniversary Day";

# Matariki dates 2022-2052 from
# https://www.mbie.govt.nz/assets/matariki-dates-2022-to-2052-matariki-advisory-group.pdf
our %MATARIKI = (
        2022 => '2022-06-24',
        2023 => '2023-07-14',
        2024 => '2024-06-28',
        2025 => '2025-06-20',
        2026 => '2026-07-10',
        2027 => '2027-06-25',
        2028 => '2028-07-14',
        2029 => '2029-07-06',
        2030 => '2030-06-21',
        2031 => '2031-07-11',
        2032 => '2032-07-02',
        2033 => '2033-06-24',
        2034 => '2034-07-07',
        2035 => '2035-06-29',
        2036 => '2036-07-21',
        2037 => '2037-07-10',
        2038 => '2038-06-25',
        2039 => '2039-07-15',
        2040 => '2040-07-06',
        2041 => '2041-07-19',
        2042 => '2042-07-11',
        2043 => '2043-07-03',
        2044 => '2044-06-24',
        2045 => '2045-07-07',
        2046 => '2046-06-29',
        2047 => '2047-07-19',
        2048 => '2048-07-03',
        2049 => '2049-06-25',
        2050 => '2050-07-15',
        2051 => '2051-06-30',
        2052 => '2052-06-21'
        );

our %HOLIDAYS
    = (
       # Holidays which are fixed, but are moved to the next working
       # day if you would not normally have worked on that day
       "New Year's Day" => "0101+",
       "Day after New Year's Day" => '0102+',
       "Christmas Day" => "1225+",
       "Boxing Day" => '1226+',
       "Waitangi Day" => "0206+",
       "Anzac Day" => "0425+",

       # Other national holidays
       "Easter Monday" => "Easter + 1day",
       "Good Friday" => "Easter - 2days",
       "Queen's Birthday" => '1st Monday in June',
       "Labour Day" => "4th Monday in October",
       "Matariki" => "Matariki",

       # Anniversary days - these are the official dates, but regional
       # authorities and sometimes district councils pick the actual dates.
       "Auckland $AD" => "Closest Monday to 0129",

       # 2nd Monday in March to avoid Easter.
       "Taranaki $AD" => "2nd Monday in March",

       # Moved to Friday before Labour Day.
       "Hawke's Bay $AD" => "4th Monday in October - 3days",

       "Wellington $AD" => "Closest Monday to 0122",

       # "Marlborough $AD"  => "Closest Monday to 1101",
       # Observed 1st Monday after Labour Day.
       "Marlborough $AD" => "4th Monday in October + 7days",

       "Nelson $AD" => "Closest Monday to 0201",

       "Westland $AD" => "Closest Monday to 1201",
       # "Varies throughout Westland, but Greymouth observes the
       # official day." - that's the West Coast for you

       # https://www.employment.govt.nz/leave-and-holidays/public-holidays/public-holidays-and-anniversary-dates/ states: "there is no easily determined single day of local observance for Otago"
       "Otago $AD" => "Closest Monday to 0323",

       # In 2011, the three southern mayors decided Southland Anniversary Day
       # would be celebrated on Easter Tuesday.
       "Southland $AD" => "Easter + 2days",

       "Chatham Islands $AD" => "Closest Monday to 1130",

       # South Canterbury observes Dominion Day
       "Dominion Day" => "4th Monday in September",

       # North Canterbury observes Christchurch show day
       # "2nd Friday after the first Tuesday in November"
       "Christchurch Show Day" => "1st Tuesday in November + 10d",
      );

our %CHANGESET_2010 = (
       # Pre-2011 dates for Southland
       "Southland $AD" => "Closest Monday to 0117",
    );

our %CHANGESET_2014 = (
       # Pre-mondayisation dates for Waitangi and Anzac days
       "Waitangi Day" => "0206",
       "Anzac Day" => "0425",
    );

our @NATIONAL_HOLIDAYS = ( "Waitangi Day",
        "Anzac Day",
        "New Year's Day",
        "Day after New Year's Day",
        "Christmas Day",
        "Boxing Day",
        "Easter Monday",
        "Good Friday",
        "Queen's Birthday",
        "Labour Day",
        );

our @NATIONAL_HOLIDAYS_ADDED_2022 = ( "Matariki" );

our %holiday_aliases =
    ( "Birthday of the Reigning Sovereign" => "Queen's Birthday",
    );

# These are region codes from 2022 Regional Councils:
# https://datafinder.stats.govt.nz/layer/106666-regional-council-2022-generalised/data/
our %regions =
    (
      1 => "Northland",
      2 => "Auckland",
      3 => "Waikato",
      4 => "Bay of Plenty",
      5 => "Gisborne",
      6 => "Hawke's Bay",
      7 => "Taranaki",
      8 => "Manawatū-Whanganui",
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

# Some regions may be split in which Anniversary Day they follow, this has been updated
# using various government and web sources, including: Wikipedia and
# https://www.employment.govt.nz/leave-and-holidays/public-holidays/public-holidays-and-anniversary-dates/
our %FOLLOW = ( 1 => 2, 3 => 2, 4 => 2, 5 => 2,
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
	    my $add = ($falls_on == 6) ? 2 : 1;
	    my $to_fall_on = UnixDate(DateCalc($year.$date, "+${add}d"), "%m%d");
	    while ( exists $h->{$to_fall_on} or
		    UnixDate($year.$to_fall_on, "%w") >= 6
		  ) {
		$to_fall_on = UnixDate(DateCalc($year.$to_fall_on, "+1d"), "%m%d");
	    }
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
	(my ($day, $month, $dom), $add) = ($1, $2, $3, $4);
	$date = ParseDate("$year-$month-$dom");
	my $wanted = UnixDate($day, "%w");
	my $got    = UnixDate($date, "%w");
	if ( my $diff = ($wanted - $got + 7) % 7 ) {
	    if ( $diff < 4 ) {
		$date = DateCalc($date, "+${diff}d");
	    } else {
		$diff = 7 - $diff;
		$date = DateCalc($date, "-${diff}d");
	    }
	}
    }
    elsif ( $value =~ m/^Easter(.*)$/i) {
	($date) = ParseRecur("*$year:0:0:0:0:0:0*EASTER");
	$add = $1;
    }
    elsif ( $value =~ m/^Matariki$/i) {
        # return a date for Matariki if one is available for the year
        ($date) = ParseDate($MATARIKI{$year});
    }
    $date = DateCalc($date, "$add") if $add;
    return UnixDate($date, "%m%d");
}

sub nz_stat_holidays {
    my $year = shift;

    my %holidays = %HOLIDAYS;

    if ( $year < 2011 ){
        %holidays = ( %holidays, %CHANGESET_2010 );
    }

    # merge the old definitions of Waitangi day and Anzac day if year is pre-mondayisation
    if ( $year < 2014 ) {
        %holidays = ( %holidays, %CHANGESET_2014 );
    }

    my @national_holidays = @NATIONAL_HOLIDAYS;
    if ( $year >= 2022 ) {
        push(@national_holidays, @NATIONAL_HOLIDAYS_ADDED_2022);
    }

    # build the relative dates
    my (%h, @tentative);
    foreach my $holiday (@national_holidays) {

	my $when = interpret_date($year, $holidays{$holiday}||die)
	    or die "couldn't interpret $year, $holidays{$holiday}";

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
      "2008/Otago $AD" => "0325",
    );

our %holiday_cache;

sub nz_holidays {
  my ($year, $region) = @_;

  my $hols = $holiday_cache{$year} ||= nz_stat_holidays($year);

  my %holidays = %HOLIDAYS;
  if ( $year < 2011 ){
      %holidays = ( %holidays, %CHANGESET_2010 );
  }

  if ( $region ) {
      my $rd = nz_regional_day($region);

      my $when = $regional_holiday_cache{"$year/$rd"} ||=
	  (interpret_date($year, $holidays{$rd}||die)
	   or die "couldn't interpret $year, $holidays{$rd}");

      $hols = { %$hols, $when => "$rd" };
  }

  return $hols;
}

sub is_nz_holiday {
  my ($year, $month, $day, $region) = @_;
  my $mmdd = sprintf("%.2d%.2d", $month, $day);

  my %holidays = %HOLIDAYS;
  if ( $year < 2011 ){
      %holidays = ( %holidays, %CHANGESET_2010 );
  }

  my $hols = $holiday_cache{$year} ||= nz_stat_holidays($year);

  if ( exists $hols->{$mmdd} ) {
      return $hols->{$mmdd};
  }

  if ( $region ) {
      my $rd = nz_regional_day($region);

      my $when = $regional_holiday_cache{"$year/$rd"} ||=
	  (interpret_date($year, $holidays{$rd}||die)
	   or die "couldn't interpret $year, $holidays{$rd}");

      if ( $when eq $mmdd ) {
	  return $rd;
      }
  }

  return undef;
}

sub nz_holiday_date {
    my ($year, $holname) = @_;
    $holname = $holiday_aliases{$holname} if $holiday_aliases{$holname};

    # merge the old definitions of Waitangi day and Anzac day if year is pre-mondayisation
    my %holidays = %HOLIDAYS;
    if ( $year < 2014 ){
        %holidays = ( %holidays, %CHANGESET_2014 );
    }

    my @national_holidays = @NATIONAL_HOLIDAYS;
    # include Matariki from 2022
    if ( $year >= 2022 ){
        push(@national_holidays, @NATIONAL_HOLIDAYS_ADDED_2022);
    }

    exists $holidays{$holname} or croak "no such holiday $holname";

    if ( grep $_ eq $holname, @national_holidays ) {

	my $date = interpret_date($year, $holidays{$holname});
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
		|| interpret_date($year, $holidays{$holname});
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

  # supply Statistics NZ region codes (1-19), or names like
  # "Wellington", "Canterbury (South)", etc
  print "Yes!" if is_nz_holiday( $year, $month, $day, $region );

  my $h = nz_holidays($year);
  printf "Dec. 25th is named '%s'\n", $h->{'1225'};

=head1 DESCRIPTION

Determines whether a given date is a New Zealand public holiday or
not.

As described at
L<https://www.govt.nz/browse/work/public-holidays-and-work/public-holidays-and-anniversary-dates/>, 
the system of determining holidays in New Zealand is a complicated
atter.  Not only do you need to know what region the country is
living in to figure out the relevant Anniversary Day, but
sometimes the district too (for the West Coast and Canterbury). As
regions are free to pick the actual days observed for particular
holidays, this module cannot guarantee dates past the last time it
was checked against the New Zealand Government web site (which, at
the time of revision provides statutory holiday details from 2021
to 2024 regional holidays for 2022 and 2023).

This module hopes to return values that are Mostly Right(tm) when
passed in Statistics NZ region codes (widely used throughout government
and industry), and can also be passed in textual region labels, which
includes the appropriate Anniversary Day.

Also, there is a difference between what is considered a holiday by
the Holidays Act 2003 - and hence entitling a person to time in lieu
and/or extra pay - and what is considered to be a Bank Holiday. This
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
    2       Auckland
    3       Waikato
    4       Bay of Plenty
    5       Gisborne
    6       Hawke's Bay
    7       Taranaki
    8       Manawatū-Wanganui
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

  Anzac Day
  Boxing Day
  Christmas Day
  Day after New Year's Day
  Dominion Day
  Easter Monday
  Good Friday
  Labour Day
  Matariki (from 2022)
  New Year's Day
  Queen's Birthday
  Waitangi Day

  Auckland Anniversary Day
  Chatham Islands Anniversary Day
  Christchurch Show Day
  Hawke's Bay Anniversary Day
  Marlborough Anniversary Day
  Nelson Anniversary Day
  Otago Anniversary Day
  Southland Anniversary Day
  Taranaki Anniversary Day
  Wellington Anniversary Day
  Westland Anniversary Day

Somebody let me know if any of those are incorrect.

C<Date::Holidays::NZ> version 1.00 and later also support referring
to Queen's Birthday as "Birthday of the Reigning Sovereign".

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

In 1.03 was a fix to correct for the newly Monday-ised Anzac and
Waitangi days, which came into force on 1 January 2014, but had no
effect until 25 April 2015. Pre-2014 instances of these holidays are
unaffected and will continue to match their original dates.

Note that district councils are free to alter the holidays schedule at
any time.  Also, strictly speaking, it is the Pope who decides the date
of Easter, upon which Easter Friday and Monday are based.

I'm not entirely sure on which Anniversary Day the following NZ regions
observe, so if it matters for you, please check that it is correct and
let me know if I need to fix anything:

=over

=item *

Waikato (assumed Auckland)

=item *

BOP (assumed Auckland)

=item *

Gisborne (assumed Auckland)

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

You may also import various internal variables and methods used by this
module if you like. Log a ticket if you want any of them to be added to
the documentation.

=head1 BUGS

This module does not support Te Reo Māori. If you would be interested
in translating the holiday names, region names or manual page to Māori,
please contact the author.

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

further modifications

Copyright (c) 2015, Haydn Newport. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

