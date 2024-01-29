package Date::Holidays::NYSE;
use strict;
use warnings;
use base qw{Exporter};
use POSIX (); #strftime to calculate wday
use Date::Calc 5.0 (); #to calculate Easter and thus Good Friday

our @EXPORT_OK = qw(is_holiday holidays is_nyse_holiday nyse_holidays);
our $VERSION   = '0.02';

=head1 NAME

Date::Holidays::NYSE - Date::Holidays Adapter for New York Stock Exchange (NYSE) holidays

=head1 SYNOPSIS

  use Date::Holidays::NYSE qw{is_holiday};
  my $holiday_name = is_holiday($year, $month, $day);

=head1 DESCRIPTION

Date::Holidays Adapter for New York Stock Exchange (NYSE) holidays

Per https://www.nyse.com/markets/hours-calendars these are the NYSE holidays.

  New Years Day (not observed on 12/31)
  Martin Luther King, Jr. Day
  Washington's Birthday
  Good Friday (falls between March 20 and April 23)
  Memorial Day
  Juneteenth National Independence Day (first observed in 2022)
  Independence Day
  Labor Day
  Thanksgiving Day
  Christmas Day

It is unclear if Juneteenth were to fall on a weekend that it would be observed. Juneteenth was not observed on Friday June 18th, 2021 but the Law was enacted on June 17th, 2021.

=head1 METHODS

=head2 is_holiday

Returns a holiday name or undef given three arguments (year, month, day).

  my ($year, $month, $day) = (2023, 4, 7);
  use Date::Holidays::NYSE qw{is_holiday};
  my $holiday_name = is_holiday($year, $month, $day);
  if (defined $holiday_name) {
    print "Holiday: $holiday_name\n"; #Good Friday
  } else {
    print "Not a NYSE Holiday\n";
  }

=cut

sub is_holiday {
  my $year           = shift;
  my $month          = shift;
  my $day            = shift;
  my $wday           = POSIX::strftime(qq{%w}, 0, 0, 0, $day, $month-1, $year-1900); #12:00 am #0=Sun, 1=Mon, 6=Sat
  my $is_good_friday = 0;
  if ($wday == 5 and (($month == 3 and $day >= 20) or ($month == 4 and $day <= 23))) { #Check Fridays in March and April for Good Friday
    # Good Friday is the Friday before Easter Sunday.
    # Easter can happen on any day from March 22 to April 25.
    # thus Good Friday can happen on any day from March 20 to April 23.
    my ($year_easter     , $month_easter     , $day_easter     ) = Date::Calc::Easter_Sunday($year);
    my ($year_good_friday, $month_good_friday, $day_good_friday) = Date::Calc::Add_Delta_Days($year_easter, $month_easter, $day_easter, -2);
    if ($year == $year_good_friday and $month == $month_good_friday and $day == $day_good_friday) {
      $is_good_friday = 1;
    }
  }

  #Ref: https://www.nyse.com/markets/hours-calendars
  #Ref: https://web.archive.org/web/20101203013357/http://www.nyse.com/about/newsevents/1176373643795.html
  #Friday 12/31 - New Years' Day (January 1) in 2011 falls on a Saturday. The rules of the applicable exchanges state that when a holiday falls on a Saturday, we observe the preceding Friday unless the Friday is the end of a monthly or yearly accounting period. In this case, Friday, December 31, 2010 is the end of both a monthly and yearly accounting period; therefore the exchanges will be open that day and the following Monday.
  if ($month == 1 and $day == 1 and $wday >= 1 and $wday <= 5) {                         #New Year's Day on a Weekday
    return q{New Year's Day};
  } elsif ($month == 1 and $day == 2 and $wday == 1) {                                   #Monday after New Year's Day
    return q{New Year's Day Observed};
  } elsif ($month == 1 and $day >= 15 and $day <= 21 and $wday == 1) {                   #Third Monday in January
    return 'Martin Luther King, Jr. Day';
  } elsif ($month == 2 and $day >= 15 and $day <= 21 and $wday == 1) {                   #Third Monday in February
    return q{Washington's Birthday};
  } elsif ($is_good_friday) {                                                            #Good Friday between March 20 and April 23
    return 'Good Friday';
  } elsif ($month == 5 and $day >= 25 and $day <= 31 and $wday == 1) {                   #Last Monday in May
    return 'Memorial Day';
  } elsif ($year >= 2022 and $month == 6 and $day == 18 and $wday == 5) {                #Juneteenth on a Friday (Assumption)
    return 'Juneteenth National Independence Day Observed';
  } elsif ($year >= 2022 and $month == 6 and $day == 19 and $wday >= 1 and $wday <= 5) { #Juneteenth on a weekday
    return 'Juneteenth National Independence Day';
  } elsif ($year >= 2022 and $month == 6 and $day == 20 and $wday == 1) {                #Juneteenth on a Monday (Assumption)
    return 'Juneteenth National Independence Day Observed';
  } elsif ($month == 7 and $day == 3 and $wday == 5) {                                   #Friday before July 4
    return 'Independence Day Observed';
  } elsif ($month == 7 and $day == 4 and $wday >= 1 and $wday <= 5) {                    #July 4 on a weekday
    return 'Independence Day';
  } elsif ($month == 7 and $day == 5 and $wday == 1) {                                   #Monday after July 4
    return 'Independence Day Observed';
  } elsif ($month == 9 and $day >= 1 and $day <= 7 and $wday == 1) {                     #First Monday in September
    return 'Labor Day';
  } elsif ($month == 11 and $day >= 22 and $day <= 28 and $wday == 4) {                  #Fourth Thursday in November.
    return 'Thanksgiving Day';
  } elsif ($month == 12 and $day == 24 and $wday == 5) {                                 #Friday before December 25
    return 'Christmas Day Observed';
  } elsif ($month == 12 and $day == 25 and $wday >= 1 and $wday <= 5) {                  #December 25 on a weekday
    return 'Christmas Day';
  } elsif ($month == 12 and $day == 26 and $wday == 1) {                                 #Monday after December 25
    return 'Christmas Day Observed';
  } else {
    return undef;
  }
}

=head2 is_nyse_holiday

Wrapper around is_holiday function per the API specification. See L<Date::Holidays/is_holiday1>

=cut

sub is_nyse_holiday {return is_holiday(@_)};

=head2 holidays

Returns a hash reference containing all of the holidays in the specified year. The keys for the returned hash reference are the dates where 2-digit month and 2-digit day are concatenated.

  use Date::Holidays::US qw{holidays};
  my $year          = 2023;
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

=head2 nyse_holidays

Wrapper around holidays function per the API specification. See L<Date::Holidays/holidays1>

=cut

sub nyse_holidays {return holidays(@_)};

=head1 TODO

This package assumes that Juneteenth will be observed when it falls on a weekend. However, in 2021 Juneteenth was not observed on Friday June 18th, 2021. The next weekend Juneteenth will be in June 2027.

=head1 SEE ALSO

L<Date::Holidays>, L<Date::Holidays::US>

=head1 AUTHOR

Michael R. Davis, MRDVT

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023 by Michael R. Davis

MIT License

=cut

1;
