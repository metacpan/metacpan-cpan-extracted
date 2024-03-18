package Date::Holidays::DK;
use strict;
use base qw(Exporter);

use Date::Simple;
use Date::Easter;
use utf8;

use vars qw($VERSION @EXPORT);
$VERSION = '0.04';
@EXPORT = qw(is_dk_holiday dk_holidays);

# Fixed-date holidays
my $FIX = {'0101' => "Nytårsdag",
	   '0605' => "Grundlovsdag",
	   '1224' => "Juleaftensdag",
	   '1225' => "Juledag",
	   '1226' => "2. Juledag",
	  };

my $VAR;

# Holidays relative to Easter
my $VAR_PRE2024 = {-7 => "Palmesøndag",
	   -3 => "Skærtorsdag",
	   -2 => "Langfredag",
	    0 => "Påskedag",
	    1 => "2. Påskedag",
	   26 => "Store Bededag",
	   39 => "Kristi Himmelfartsdag",
	   49 => "Pinsedag",
	   50 => "2. Pinsedag",
	  };

# "Store Bededag" no longer a holiday after 2023
my $VAR_POST2023 = {-7 => "Palmesøndag",
	   -3 => "Skærtorsdag",
	   -2 => "Langfredag",
	    0 => "Påskedag",
	    1 => "2. Påskedag",
	   39 => "Kristi Himmelfartsdag",
	   49 => "Pinsedag",
	   50 => "2. Pinsedag",
	  };

sub is_dk_holiday {
  my ($year, $month, $day) = @_;

  if ($year >= 2024) {
    $VAR = $VAR_POST2023;
  } else {
    $VAR = $VAR_PRE2024;
  }

  my $holiday = $FIX->{sprintf "%02d%02d", $month, $day} ||
  $VAR->{Date::Simple->new($year, $month, $day) -
	 Date::Simple->new($year, easter($year))} ||
  undef;

  return $holiday;
}

sub dk_holidays {
  my ($year) = @_;

  # get the fixed dates
  my $h = {%$FIX};

  my $easter = Date::Simple->new($year, easter($year));

  # build the relative dates
  foreach my $diff (keys %$VAR) {
    my $date = $easter + $diff;
    $h->{sprintf "%02d%02d", $date->month, $date->day} = $VAR->{$diff};
  }

  return $h;
}

1;

=head1 NAME

Date::Holidays::DK - Determine Danish public holidays

=head1 SYNOPSIS

  use Date::Holidays::DK;
  my ($year, $month, $day) = (localtime)[ 5, 4, 3 ];
  $year  += 1900;
  $month += 1;
  print "Woohoo" if is_dk_holiday( $year, $month, $day );

  my $h = dk_holidays($year);
  printf "Dec. 25th is named '%s'\n", $h->{'1225'};

=head1 DESCRIPTION

Determines whether a given date is a Danish public holiday or not.

This module is based on the simple API of Date::Holidays::UK, but
implements a generalised date mechanism, that will work for all
years since 1700, when Denmark adopted the Gregorian calendar.

=head1 Functions

=over 4

=item is_dk_holiday($year, $month, $date)

Returns the name of the Holiday that falls on the given day, or undef
if there is none.

=item dk_holidays($year)

Returns a hashref of all defined holidays in the year. Keys in the
hashref are in 'mmdd' format, the values are the names of the
holidays.

=back

=head1 EXPORTS

Exports is_dk_holiday() and dk_holidays() by default.

=head1 BUGS

Please report issues via CPAN RT:

  http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Holidays-DK

or by sending mail to

  bug-Date-Holidays-DK@rt.cpan.org

=head1 AUTHORS

Lars Thegler <lars@thegler.dk>. Originally inspired by
Date::Holidays::UK by Richard Clamp.

dk_holidays() concept by Jonas B. Nielsen.

=head1 COPYRIGHT

Copyright (c) 2004-2005 Lars Thegler. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

