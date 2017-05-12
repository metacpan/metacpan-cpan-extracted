package Date::Holidays::UK::EnglandAndWales;
use strict;
use warnings;

our $VERSION = '0.04'; # Colin Hart

require Exporter;
require Tie::Hash ;

our @ISA    = qw( Exporter Tie::StdHash );
our @EXPORT = qw( is_uk_holiday );

=head1 NAME

Date::Holidays::UK::EnglandAndWales - Public Holidays in England and Wales

=head1 SYNOPSIS

  use Date::Holidays::UK::EnglandAndWales;
  my ($year, $month, $day) = (localtime)[ 5, 4, 3 ];
  $year  += 1900;
  $month += 1;
  warn "Holiday" if is_uk_holiday( $year, $month, $day );
  warn "Holiday" if Date::Holidays::UK::EnglandAndWales->is_holiday( $year, $month, $day );

=head1 DESCRIPTION

These bank and public holidays are holidays in England and Wales,
and not necessarily for Scotland and Northern Ireland.

=head2 MODULE HISTORY

This module is based on L<Date::Holidays::UK|Date::Holidays::UK>
by Richard Clamp, Amelie Guyot, Jerome Parfant, which did not contain
the dates needed by my clients.

As Msrs Clamp et al note in the L<POD for their module|Date::Holidays::UK/DESCRIPTION>,
Naming modules is a tricky thing: I've named this C<EnglandAndWales> because
the C<UK> module cannot include holidays for Northern Ireland and Scotland,
and maintain its API, since the dates vary across the UK for events of the same name.

=head2 USE

=head3 is_uk_holiday( $year, $month, $day )

=head3 is_holiday( $year, $month, $day );

=head3 Date::Holidays::UK::EnglandAndWales->is_holiday( $year, $month, $day )

May be called as class method or subroutine.
Returns the name of the Holiday that falls on the given day, or undef
if there is none.

Year must be four-digit. Strips any leading zeros from month and day.

Can be included or imported to a class as an object method, since the first
argument supplied is discarded if an reference.

=head2 EXPORTS

C<is_uk_holiday> is exported by default, but this is deprecated and will
be removed in a future version.

=cut

our (%holidays, %_holidays);

$_holidays{ 2005,  1,  3 } =
$_holidays{ 2006,  1,  2 } =
$_holidays{ 2011,  1,  3 } =
$_holidays{ 2012,  1,  2 } =
$_holidays{ 2017,  1,  2 } =
$_holidays{ 2022,  1,  3 } =
$_holidays{ 2023,  1,  2 } =
    "Substitute Bank Holiday in lieu of 1 Jan";

$_holidays{ 2004,  4,  9 } =
$_holidays{ 2005,  3, 25 } =
$_holidays{ 2006,  4, 14 } =
$_holidays{ 2007,  4,  6 } =
$_holidays{ 2008,  3, 21 } =
$_holidays{ 2009,  4, 10 } =
$_holidays{ 2010,  4,  2 } =
$_holidays{ 2011,  4, 22 } =
$_holidays{ 2012,  4,  6 } =
$_holidays{ 2013,  3, 29 } =
$_holidays{ 2014,  4, 15 } =
$_holidays{ 2015,  4,  3 } =
$_holidays{ 2016,  3, 25 } =
$_holidays{ 2017,  4, 14 } =
$_holidays{ 2018,  3, 30 } =
$_holidays{ 2019,  4, 19 } =
$_holidays{ 2020,  4, 10 } =
$_holidays{ 2021,  4,  2 } =
$_holidays{ 2022,  4, 15 } =
$_holidays{ 2023,  4,  7 } =
$_holidays{ 2024,  3, 29 } =
    "Good Friday";

$_holidays{ 2004,  4, 12 } =
$_holidays{ 2005,  3, 28 } =
$_holidays{ 2006,  4, 17 } =
$_holidays{ 2007,  4,  9 } =
$_holidays{ 2008,  3, 24 } =
$_holidays{ 2009,  4, 13 } =
$_holidays{ 2010,  4,  5 } =
$_holidays{ 2011,  4, 25 } =
$_holidays{ 2012,  4,  9 } =
$_holidays{ 2013,  4,  1 } =
$_holidays{ 2014,  4, 21 } =
$_holidays{ 2015,  4,  6 } =
$_holidays{ 2016,  3, 28 } =
$_holidays{ 2017,  4, 17 } =
$_holidays{ 2018,  4,  2 } =
$_holidays{ 2019,  4, 22 } =
$_holidays{ 2020,  4, 13 } =
$_holidays{ 2021,  4,  5 } =
$_holidays{ 2022,  4, 18 } =
$_holidays{ 2023,  4, 10 } =
$_holidays{ 2024,  4,  1 } =
    "Easter Monday";

$_holidays{ 2004,  5,  3 } =
$_holidays{ 2005,  5,  2 } =
$_holidays{ 2006,  5,  1 } =
$_holidays{ 2007,  5,  7 } =
$_holidays{ 2008,  5,  5 } =
$_holidays{ 2009,  5,  4 } =
$_holidays{ 2010,  5,  3 } =
$_holidays{ 2011,  5,  2 } =
$_holidays{ 2012,  5,  7 } =
$_holidays{ 2013,  5,  6 } =
$_holidays{ 2014,  5,  5 } =
$_holidays{ 2015,  5,  4 } =
$_holidays{ 2016,  5,  2 } =
$_holidays{ 2017,  5,  1 } =
$_holidays{ 2018,  5,  7 } =
$_holidays{ 2019,  5,  6 } =
$_holidays{ 2020,  5,  4 } =
$_holidays{ 2021,  5,  3 } =
$_holidays{ 2022,  5,  2 } =
$_holidays{ 2023,  5,  1 } =
$_holidays{ 2024,  5,  6 } =
    "Early May Bank Holiday";

$_holidays{ 2004,  5, 31 } =
$_holidays{ 2005,  5, 30 } =
$_holidays{ 2006,  5, 29 } =
$_holidays{ 2007,  5, 28 } =
$_holidays{ 2008,  5, 26 } =
$_holidays{ 2009,  5, 25 } =
$_holidays{ 2010,  5, 31 } =
$_holidays{ 2011,  5, 30 } =
$_holidays{ 2012,  5, 28 } =
$_holidays{ 2013,  5, 27 } =
$_holidays{ 2014,  5, 26 } =
$_holidays{ 2015,  5, 25 } =
$_holidays{ 2016,  5, 30 } =
$_holidays{ 2017,  5, 29 } =
$_holidays{ 2018,  5, 28 } =
$_holidays{ 2019,  5, 27 } =
$_holidays{ 2020,  5, 25 } =
$_holidays{ 2021,  5, 31 } =
$_holidays{ 2022,  5, 30 } =
$_holidays{ 2023,  5, 29 } =
$_holidays{ 2024,  5, 27 } =
    "Spring Bank Holiday";

$_holidays{ 2004,  8, 30 } =
$_holidays{ 2005,  8, 29 } =
$_holidays{ 2006,  8, 28 } =
$_holidays{ 2007,  8, 27 } =
$_holidays{ 2008,  8, 25 } =
$_holidays{ 2009,  8, 31 } =
$_holidays{ 2010,  8, 30 } =
$_holidays{ 2011,  8, 29 } =
$_holidays{ 2012,  8, 27 } =
$_holidays{ 2013,  8, 26 } =
$_holidays{ 2014,  8, 25 } =
$_holidays{ 2015,  8, 31 } =
$_holidays{ 2016,  8, 29 } =
$_holidays{ 2017,  8, 28 } =
$_holidays{ 2018,  8, 27 } =
$_holidays{ 2019,  8, 26 } =
$_holidays{ 2020,  8, 31 } =
$_holidays{ 2021,  8, 30 } =
$_holidays{ 2022,  8, 29 } =
$_holidays{ 2023,  8, 28 } =
$_holidays{ 2024,  8, 26 } =
    "Summer Bank Holiday";

$_holidays{ 2004, 12, 28 } =
$_holidays{ 2005, 12, 27 } =
$_holidays{ 2010, 12, 27 } =
$_holidays{ 2011, 12, 27 } =
$_holidays{ 2016, 12, 27 } =
$_holidays{ 2021, 12, 27 } =
$_holidays{ 2022, 12, 27 } =
    "Substitute Bank Holiday in lieu of 25 Dec";

$_holidays{ 2004, 12, 27 } =
$_holidays{ 2009, 12, 28 } =
$_holidays{ 2010, 12, 28 } =
$_holidays{ 2015, 12, 28 } =
$_holidays{ 2021, 12, 28 } =
    "Substitute Bank Holiday in lieu of 26 Dec";


tie %holidays, 'Date::Holidays::UK::EnglandAndWales';

sub is_uk_holiday {
    shift if $_[0] eq __PACKAGE__ or ref $_[0];

    my ($year, $month, $day) = $#_ > 0 ? @_ : split/\D+/,$_[0],3;
    $month =~ s/^0// if $month;
    $day   =~ s/^0// if $day;

    return $_holidays{ $year, $month, $day }
        if exists $_holidays{ $year, $month, $day };

    if ($month == 12){
        return 'Christmas Day'      if $day == 25;
        return 'Boxing Day'         if $day == 26;
    }
    if ($month == 1){
        return 'New Year\'s Day'    if $day == 1;
    }
}

# alias
*is_holiday = *is_uk_holiday;

# tie API forwards to legacy API
sub FETCH {
    return is_uk_holiday( @_ );
}

1;

__END__

=head1 SOURCE

The DTI's webpage L<http://www.dti.gov.uk/employment/bank-public-holidays/index.html|http://www.dti.gov.uk/employment/bank-public-holidays/index.html>
is taken as the canonical source for bank holidays.

=head1 CAVEATS

We only currently contain the DTI Bank Holiday detail, which at the
time of writing only covers the years 2004-2014.

These Bank and Public Holidays are holidays in England and Wales,
and not necessarily in Scotland and Northern Ireland.

=head1 CONTRIBUTORS

Lee Goddard; Richard Clamp <richardc@fotango.com>; Amelie Guyot; Jerome Parfant; Colin Hart.

=head1 COPYRIGHT

Copyright (C) 2017 Colin Hart. All Rights Reserved.
Copyright (C) 2004 Fotango.  All Rights Reserved.
Copyright (C) 2007, 2011 Lee Goddard.  All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 BUGS

None known.

Bugs should be reported via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date::Holidays::UK::EnglandAndWales>.

=head1 SEE ALSO

L<Date::Holidays::UK>

=cut

