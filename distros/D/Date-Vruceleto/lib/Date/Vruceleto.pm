package Date::Vruceleto;

#use 5.010001;
use strict;
use warnings;
use utf8;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(vruceleto solarcycle vrutseleto);

our @EXPORT = qw();

our $VERSION = '0.01';

my %map = (
	1 => 'А',
	2 => 'В',
	3 => 'Г',
	4 => 'Д',
	5 => 'Е',
	6 => 'Ѕ', # Cyrillic capital letter DZE
	7 => 'З'
);

sub solarcycle {
    my ($year, $is_AD) = @_;
	$year = $year-8 if $is_AD;
	my $res = $year % 28 || 28;
	return $res;
}

sub vruceleto {
	my $q = solarcycle(@_);
	use integer;
	my $res = $q/4 + $q%7;
	$res = $res-7 if $res > 7;
	return $map{$res};
}

*vrutseleto = \&vruceleto;

1;
__END__

=pod

=encoding UTF-8

=head1 NAME

Date::Vruceleto - Compute year's vruceleto and solar cycle as used in
old Russian calendar

=head1 SYNOPSIS

  use Date::Vruceleto;
  $letter = vruceleto(2016); # NB: means year 2016 since March 1, 5508 BCE
  $letter = vruceleto(2016, 'AD'); # Anno Domini, valid for March 2016 - February 2017
  $letter = vruceleto(2016, 1); # the same
  $letter = vrutseleto(2016, 1); # the same

  # can also get the solar cycle (old Russian style)

  $cycle = solarcycle($year);

=head1 DESCRIPTION

Vruceletos (or vrutseletos) are similar to European Sunday letters
(see L<Date::SundayLetter>) with a few differences:

- Letters are Cyrillic

- A January-based year has always 2 letters, not just a leap
  one. That's because March-based style is used.

Vruceleto (or vrutseleto) letters are Cyrillic letters А, В, Г, Д, Е,
Ѕ, З (pronounced Az, Vedi, Glagol', Dobro, Yest', Zelo, Zemlya),
assigned sequentially to the days of the year in reverse order,
starting from the 1st of March being Г. Thus within a March-based year
(common among East Slavs until 1492) each letter corresponds to the
same day of the week, the letter corresponding to Sunday being called
"the vruceleto of the year". The latter then could be used for Easter
calculations and to refer to specific years in chronicles along with
other dating techniques.

The cycle of correspondences between vruceletos and the days of the
week is repeated every 28 years, a period also used in old Russian
chronology as "solar cycle". The count of solar cycles in this
calendar system starts from March 1, 5508 BCE (called Constantinople
World Aera).

I.A.Klimishin in his book "Calendar and Chronology" (Moscow, Nauka,
1985, pp. 66-70) gives the following formulae to calculate solar
cycles and vruceletos ([] meaning the integer part of the quotient and
|| the remainder):

- First get the solar cycle (Q) of the year of Constantinople aera (B):

    Q = |B/28|

or Christian aera (R):

    Q = |(R-8)/28|

- Then calculate the vruceleto number (W) of the year:

    W = [Q/4] + |Q/7|

А, В, Г, Д, Е, Ѕ, З corresponding to numbers 1-7 respectively.

In this module the same result is achieved with C<solarcycle> and
C<vruceleto> functions, the latter calling the former
internally. C<vrutseleto> is an alias for C<vruceleto>.

=head2 CAVEATS

Finding 2 vruceletos for a January-based year is not yet
supported. One should find vruceleto of the previous year for dates in
January and February.

This module does not use any external modules to get solar cycle. In
fact we don't even know if they exist, hardly though, Eastern and
Western solar cycles being different anyway. We haven't checked either
if L<Date::SundayLetter> is of any use for our goals.

The module is intended to find only "the vruceleto of the year" and
not to be used as a Perpetual Calendar, though it may be helpful in
building some tools that achieve that goal.

The module is intended for use in work with old Russian texts as well
as ecclesiastical calculations, i.e. where Julian calendar is
common. Usage with Gregorian calendar is generally senseless and thus
untested.

=head2 EXPORT

None by default. I<solarcycle>, I<vruceleto> and I<vrutseleto> can be
exported on request.

=head1 SEE ALSO

L<Date::SundayLetter>

=head1 AUTHOR

Roman Pavlov <rp@freeshell.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2018 Roman Pavlov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
