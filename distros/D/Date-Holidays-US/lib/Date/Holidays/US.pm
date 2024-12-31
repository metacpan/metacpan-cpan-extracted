package Date::Holidays::US;
use strict;
use warnings;
use base qw{Exporter};
use POSIX; #strftime to calculate wday

our @EXPORT_OK = qw(is_holiday holidays is_us_holiday us_holidays);

our $VERSION = '0.07';

=head1 NAME

Date::Holidays::US - Date::Holidays Adapter for US Federal holidays

=head1 SYNOPSIS

  use Date::Holidays::US qw{is_holiday};
  my $holiday_name = is_holiday($year, $month, $day);

=head1 DESCRIPTION

Date::Holidays Adapter for US Federal holidays back to 1880 with updates from 2024.

=head1 METHODS

=head2 is_holiday

Returns a holiday name or undef given three arguments (year, month, day).

  my ($year, $month, $day) = (2022, 6, 19);
  use Date::Holidays::US qw{is_holiday};
  my $holiday_name = is_holiday($year, $month, $day);
  if (defined $holiday_name) {
    print "Holiday: $holiday_name\n";
  } else {
    print "Not a US Holiday\n";
  }

=cut

sub is_holiday {
  my $year  = shift;
  my $month = shift;
  my $day   = shift;
  my $wday  = POSIX::strftime(qq{%w}, 0, 0, 0, $day, $month-1, $year-1900); #12:00 am (0-6 starting on Sunday)

  #Ref: https://sgp.fas.org/crs/misc/R41990.pdf

  #5 U.S. Code § 6103 - Holidays
  #The history of federal holidays in the United States dates back to June 28, 1870
  if ($year > 1870 and $month == 1 and $day == 1) {
    return q{New Year's Day};                                          #January 1
  } elsif ($year > 1909 and $month == 1 and $day == 2 and $wday == 1) { #Executive Order 1076 (May 22, 1909)
    return q{New Year's Day Observed};                                 #Monday after January 1

  #observed for the first time on January 20, 1986. - Pub.L. 98–399, 98 Stat. 1475, enacted November 2, 1983
  } elsif ($year >= 1986 and $month == 1 and $day >= 15 and $day <= 21 and $wday == 1) {
    return 'Birthday of Martin Luther King, Jr.'                       #the third Monday in January

  #Inauguration Day - Only DC Area
  #Purposefully processed after MLK day. In the case of concurrency, MLK is returned.
  } elsif ($year >= 1965 and $month == 1 and $day == 20 and $year % 4 == 1 and $wday != 0) { #5 U.S. Code 6103(c)
    return 'Inauguration Day'                       #January 20 of each fourth year after 1965 unless Sunday
  #Note 5 U.S. Code 6103(c) provides for Monday Jan 21 to be Inauguration Day but this package returns MKL day after 1985
  } elsif ($year == 1985 and $month == 1 and $day == 21) { #5 U.S. Code 6103(c)
    return 'Inauguration Day'              #When January 20 ... falls on Sunday, the next succeeding day...

  # Washington's Birthday was celebrated on February 22 from 1879 until 1970.
  # in 1968 the Uniform Monday Holiday Act moved it to the third Monday in February
  # The Act was signed into law on June 1, 1968, and took effect on January 1, 1971.
  } elsif ($year >= 1879 and $year < 1971 and $month == 2 and $day == 22) {
    return q{Washington's Birthday};                                   #February 22 from 1879 until 1970
  } elsif ($year >  1909 and $year < 1971 and $month == 2 and $day == 23 and $wday == 1) { #Executive Order 1076 (May 22, 1909)
    return q{Washington's Birthday Observed};                          #February 23 when Monday
  } elsif ($year >= 1971 and $month == 2 and $day >= 15 and $day <= 21 and $wday == 1) { #Uniform Monday Holiday Act (June 28, 1968)
    return q{Washington's Birthday};                                   #the third Monday in February

  # Memorial Day/Decoration Day
  } elsif ($year >= 1888 and $year < 1971 and $month == 5 and $day == 30) {
    return 'Decoration Day';                                          #May 30
  } elsif ($year >= 1909 and $year < 1971 and $month == 6 and $day == 1 and $wday == 1) { #Executive Order 1076 (May 22, 1909)
    return 'Decoration Day Observed';                                 #June 1st
  } elsif ($year >= 1971 and $month == 5 and $day >= 25 and $day <= 31 and $wday == 1) { #Uniform Monday Holiday Act (June 28, 1968)
    return 'Memorial Day';                                            #the last Monday in May

  #The day was first recognized as a federal holiday in June 2021, when President
  #Joe Biden signed the Juneteenth National Independence Day Act into law.
  } elsif ($year >= 2021 and $month == 6 and $day == 18 and $wday == 5) { #Executive Order 11582 (Feb. 11, 1971) "or any other calendar day designated as a holiday by Federal statute"
    return 'Juneteenth National Independence Day Observed';               #Friday before June 19
  } elsif ($year >= 2021 and $month == 6 and $day == 19) {                #Juneteenth National Independence Day Act (June 17, 2021)
    return 'Juneteenth National Independence Day';                        #June 19
  } elsif ($year >= 2021 and $month == 6 and $day == 20 and $wday == 1) { #Executive Order 11582 (Feb. 11, 1971)
    return 'Juneteenth National Independence Day Observed';               #Monday after June 19

  #Independence Day

  } elsif ($year >= 1971 and $month == 7 and $day == 3 and $wday == 5) { #Executive Order 11582 (Feb. 11, 1971)
    return 'Independence Day Observed';                                  #Friday before July 4
  } elsif ($year >= 1870 and $month == 7 and $day == 4) {
    return 'Independence Day';                                           #July 4
  } elsif ($year >= 1909 and $month == 7 and $day == 5 and $wday == 1) { #Executive Order 1076 (May 22, 1909)
    return 'Independence Day Observed';                                  #Monday after July 4

  ## Labor Day
  # By 1894, thirty U.S. states were already officially celebrating Labor Day. In that year,
  # Congress passed a bill recognizing the first Monday of September as Labor Day and making
  # it an official federal holiday. President Grover Cleveland signed the bill into law on
  # June 28.[15][4] The federal law, however, only made it a holiday for federal workers.

  } elsif ($year >= 1894 and $month == 9 and $day >= 1 and $day <= 7 and $wday == 1) {
    return 'Labor Day';                                               #the first Monday in September

  ##Columbus Day
  } elsif ($year >= 1971 and $month == 10 and $day >= 8 and $day <= 14 and $wday == 1) { #Uniform Monday Holiday Act
    return 'Columbus Day';                                            #the second Monday in October

  ##Veterans Day (>1954)/Armistice Day (<1954)
  #November 11 (1938 to 1970 and >1978)
  #fourth Monday in October (1971 to 1977)

  } elsif ($year >= 1938 and $year < 1954 and $month == 11 and $day == 11) {
    return 'Armistice Day';                                            #November 11
  } elsif ($year >= 1945 and $year < 1954 and $month == 11 and $day == 12 and $wday == 1) { #Executive Order 9636 (October 3, 1945)
    return 'Armistice Day Observed';                                   #Monday after November 11

  } elsif ($year >= 1954 and $year < 1971 and $month == 11 and $day == 11) {
    return 'Veterans Day';                                            #November 11
  } elsif ($year >= 1954 and $year < 1971 and $month == 11 and $day == 12 and $wday == 1) { #Executive Order 9636 (October 3, 1945)
    return 'Veterans Day Observed';                                   #Monday after November 11

  } elsif ($year >= 1971 and $year < 1978 and $month == 10 and $day >= 22 and $day <= 28 and $wday == 1) {
    return 'Veterans Day';                                            #fourth Monday in October

  } elsif ($year >= 1978 and $month == 11 and $day == 10 and $wday == 5) { #Executive Order 11582 (Feb. 11, 1971)
    return 'Veterans Day Observed';                                   #Friday before November 11
  } elsif ($year >= 1978 and $month == 11 and $day == 11) {
    return 'Veterans Day';                                            #November 11
  } elsif ($year >= 1978 and $month == 11 and $day == 12 and $wday == 1) { #Executive Order 11582 (Feb. 11, 1971)
    return 'Veterans Day Observed';                                   #Monday after November 11

  ##Thanksgiving Day
  } elsif ($year >= 1870 and $month == 11 and $day >= 22 and $day <= 28 and $wday == 4) {
    return 'Thanksgiving Day';                                        #the fourth Thursday in November.

  ##Day before Christmas Day
  } elsif ($year == 2024 and $month == 12 and $day == 24) {
    return 'Day before Christmas Day';                                #Executive Order on Providing for the Closing of Executive Departments and Agencies of the Federal Government on December 24, 2024

  ##Christmas Day
  } elsif ($year >= 1971 and $month == 12 and $day == 24 and $wday == 5) { #Executive Order 11582 (Feb. 11, 1971)
    return 'Christmas Day Observed';                                  #Friday before December 25
  } elsif ($year >= 1870 and $month == 12 and $day == 25) {
    return 'Christmas Day';                                           #December 25
  } elsif ($year >= 1909 and $month == 12 and $day == 26 and $wday == 1) { #Executive Order 1076 (May 22, 1909)
    return 'Christmas Day Observed';                                  #Monday after December 25

  } elsif ($year >= 1971 and $month == 12 and $day == 31 and $wday == 5) { #Executive Order 11582 (Feb. 11, 1971)
    return q{New Year's Day Observed};                                 #Friday before January 1

  # Beginning with the death of President Kennedy in 1963, the incumbent President has issued an Executive order closing
  # Government offices throughout the world as a mark of respect upon the death of each President or former President.
  } elsif ($year == 1963 and $month == 11 and $day == 25) {
    #35 November 25, 1963, National Day of Mourning for President John F. Kennedy
    return 'National Day of Mourning for President John F. Kennedy';
  } elsif ($year == 1973 and $month == 1 and $day == 25) {
    #36 January 25 1973, National Day of Mourning for President Lyndon B. Johnson
    return 'National Day of Mourning for President Lyndon B. Johnson';
  } elsif ($year == 1994 and $month == 4 and $day == 27) {
    #37 April 27, 1994, National Day of Mourning for President Richard Nixon
    return 'National Day of Mourning for President Richard Nixon';
  } elsif ($year == 2007 and $month == 1 and $day == 2) {
    #38 January 2, 2007 National Day of Mourning for President Gerald R. Ford
    return 'National Day of Mourning for President Gerald R. Ford';
  } elsif ($year == 2025 and $month == 1 and $day == 9) {
    #39 January 9, 2025 National Day of Mourning for President Jimmy Carter
    return 'National Day of Mourning for President James Earl Carter, Jr.';
  } elsif ($year == 2004 and $month == 6 and $day == 11) {
    #40 June 11, 2004, National Day of Mourning for President Ronald W. Reagan
    return 'National Day of Mourning for President Ronald W. Reagan';
  } elsif ($year == 2018 and $month == 12 and $day == 5) {
    #41 December 5, 2018, National Day of Mourning for President George H. W. Bush
    return 'National Day of Mourning for President George H. W. Bush';

  } else {
    return undef;
  }
}

=head2 is_us_holiday

Wrapper around is_holiday function per the API specification. See L<Date::Holidays/is_holiday1>

=cut

sub is_us_holiday {return is_holiday(@_)};

=head2 holidays

Returns a hash reference containing all of the holidays in the specified year.  The keys for the returned hash reference are the dates where 2-digit month and 2-digit day are concatenated.

  use Date::Holidays::US qw{holidays};
  my $year          = 2022;
  my $holidays_href = holidays($year);
  foreach my $key (sort keys %$holidays_href) { #e.g. "0101", "0619","0704"
    my ($month, $day) = $key =~ m/\A([0-9]{2})([0-9]{2})\Z/;
    my $name          = $holidays_href->{$key};
    print "Year: $year, Month: $month, Day: $day, Name: $name\n";
  }

=cut

sub holidays {
  my $year     = shift;
  my %holidays = ();
  my $time     = POSIX::mktime(0, 0, 0, 1, 0, $year-1900); #Jan 1st
  while (1) {
    my ($year_calculated, $month, $day) = split /-/, POSIX::strftime("%Y-%m-%d", POSIX::gmtime($time));
    last if $year_calculated > $year;
    my $date          = $month . $day;
    my $name          = is_holiday($year, $month, $day);
    $holidays{$date}  = $name if defined($name);
    $time            += 86400; #Note: Not all US days have 24 hours but we are using UTC for the date component
  }
  return \%holidays;
}

=head2 us_holidays

Wrapper around holidays function per the API specification. See L<Date::Holidays/holidays1>

=cut

sub us_holidays {return holidays(@_)};

=head1 TODO

=head1 SEE ALSO

L<Date::Holidays> (wrapper), L<Date::Holidays::USFederal> (defunct), L<Date::Holidays::USExtended> (e.g., Valentine's Day, Mother's Day, etc.)

=head1 AUTHOR

Michael R. Davis, MRDVT

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Michael R. Davis

MIT License

=cut

1;
