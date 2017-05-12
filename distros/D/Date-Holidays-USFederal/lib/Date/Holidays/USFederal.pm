package Date::Holidays::USFederal;
use strict;
use warnings;
use base qw(Exporter);
our $VERSION = '1.0';
our @EXPORT = qw( is_usfed_holiday );

=head1 NAME

Date::Holidays::USFederal - Determine US Federal Public Holidays

=head1 SYNOPSIS

  use Date::Holidays::USFederal;
  my ($year, $month, $day) = (localtime)[ 5, 4, 3 ];
  $year  += 1900;
  $month += 1;
  print "Woohoo" if is_usfed_holiday( $year, $month, $day );

=head1 DESCRIPTION

The naming convention for the module follows that of L(Date::Holidays:UK)
as where the format for this module was also taken.

=head1 SUBROUTINES

=head2 is_usfed_holiday( $year, $month, $day )

Returns the name of the Holiday that falls on the given day, or undef
if there is none.

=cut

# 
# 
our %holidays;

$holidays{ 1997,  1,  1 } =
$holidays{ 1998,  1,  1 } =
$holidays{ 1999,  1,  1 } =
$holidays{ 1999, 12, 31 } =
$holidays{ 2001,  1,  1 } =
$holidays{ 2002,  1,  1 } =
$holidays{ 2003,  1,  1 } =
$holidays{ 2004,  1,  1 } =
$holidays{ 2004, 12, 31 } =
$holidays{ 2006,  1,  2 } =
$holidays{ 2007,  1,  1 } =
$holidays{ 2008,  1,  1 } = 
$holidays{ 2009,  1,  1 } =
$holidays{ 2010,  1,  1 } = 
$holidays{ 2010, 12, 31 } = 
$holidays{ 2012,  1,  2 } = 
$holidays{ 2013,  1,  1 } = 
$holidays{ 2014,  1,  1 } =
$holidays{ 2015,  1,  1 } =
$holidays{ 2016,  1,  1 } = 
$holidays{ 2017,  1,  2 } = 
$holidays{ 2018,  1,  1 } =
$holidays{ 2019,  1,  1 } = 
$holidays{ 2020,  1,  1 } = 
$holidays{ 2021,  1,  1 } = 
$holidays{ 2022, 12, 31 } =
$holidays{ 2023,  1,  2 } = 
$holidays{ 2024,  1,  1 } = 
$holidays{ 2025,  1,  1 } = "New Year's Day";

$holidays{ 1997,  1, 20 } =
$holidays{ 1998,  1, 19 } =
$holidays{ 1999,  1, 18 } =
$holidays{ 2000,  1, 17 } =
$holidays{ 2001,  1, 15 } =
$holidays{ 2002,  1, 17 } =
$holidays{ 2003,  1, 20 } =
$holidays{ 2004,  1, 19 } =
$holidays{ 2005,  1, 17 } =
$holidays{ 2006,  1, 16 } =
$holidays{ 2007,  1, 15 } =
$holidays{ 2008,  1, 21 } = 
$holidays{ 2009,  1, 19 } = 
$holidays{ 2010,  1, 18 } =
$holidays{ 2011,  1, 17 } =
$holidays{ 2012,  1, 16 } = 
$holidays{ 2013,  1, 21 } = 
$holidays{ 2014,  1, 20 } = 
$holidays{ 2015,  1, 19 } =
$holidays{ 2016,  1, 18 } = 
$holidays{ 2017,  1, 16 } = 
$holidays{ 2018,  1, 15 } = 
$holidays{ 2019,  1, 21 } =
$holidays{ 2020,  1, 20 } = 
$holidays{ 2021,  1, 18 } = 
$holidays{ 2022,  1, 17 } =
$holidays{ 2023,  1, 16 } =
$holidays{ 2024,  1, 15 } = 
$holidays{ 2025,  1, 20 } = "Martin Luther King, Jr. Birthday";

$holidays{ 2001,  1, 20 } =
$holidays{ 2005,  1, 20 } =
$holidays{ 2009,  1, 20 } =
$holidays{ 2013,  1, 20 } =
$holidays{ 2017,  1, 20 } =
$holidays{ 2021,  1, 20 } =
$holidays{ 2025,  1, 20 } = "Inaugration Days (Observed in US Capitol Area)";

$holidays{ 1997,  2, 17 } =
$holidays{ 1998,  2, 16 } =
$holidays{ 1999,  2, 15 } =
$holidays{ 2000,  2, 21 } =
$holidays{ 2001,  2, 19 } =
$holidays{ 2002,  2, 18 } =
$holidays{ 2003,  2, 17 } =
$holidays{ 2004,  2, 16 } =
$holidays{ 2005,  2, 21 } =
$holidays{ 2006,  2, 20 } =
$holidays{ 2007,  2, 19 } =
$holidays{ 2008,  2, 18 } = 
$holidays{ 2009,  2, 16 } = 
$holidays{ 2010,  2, 15 } =
$holidays{ 2011,  2, 21 } =
$holidays{ 2012,  2, 20 } = 
$holidays{ 2013,  2, 18 } = 
$holidays{ 2014,  2, 17 } = 
$holidays{ 2015,  2, 16 } =
$holidays{ 2016,  2, 15 } = 
$holidays{ 2017,  2, 20 } = 
$holidays{ 2018,  2, 19 } = 
$holidays{ 2019,  2, 18 } =
$holidays{ 2020,  2, 17 } = 
$holidays{ 2021,  2, 15 } = 
$holidays{ 2022,  2, 21 } =
$holidays{ 2023,  2, 20 } =
$holidays{ 2024,  2, 19 } = 
$holidays{ 2025,  2, 17 } = "Washington's Birthday / Presidents Day";

$holidays{ 1997,  5, 26 } =
$holidays{ 1998,  5, 25 } =
$holidays{ 1999,  5, 31 } =
$holidays{ 2000,  5, 29 } =
$holidays{ 2001,  5, 28 } =
$holidays{ 2002,  5, 27 } =
$holidays{ 2003,  5, 26 } =
$holidays{ 2004,  5, 31 } =
$holidays{ 2005,  5, 28 } =
$holidays{ 2006,  5, 29 } =
$holidays{ 2007,  5, 28 } =
$holidays{ 2008,  5, 26 } = 
$holidays{ 2009,  5, 25 } = 
$holidays{ 2010,  5, 31 } =
$holidays{ 2011,  5, 30 } =
$holidays{ 2012,  5, 28 } = 
$holidays{ 2013,  5, 27 } = 
$holidays{ 2014,  5, 26 } = 
$holidays{ 2015,  5, 25 } =
$holidays{ 2016,  5, 30 } = 
$holidays{ 2017,  5, 29 } = 
$holidays{ 2018,  5, 28 } = 
$holidays{ 2019,  5, 27 } =
$holidays{ 2020,  5, 25 } = 
$holidays{ 2021,  5, 31 } = 
$holidays{ 2022,  5, 30 } =
$holidays{ 2023,  5, 29 } =
$holidays{ 2024,  5, 27 } = 
$holidays{ 2025,  5, 26 } = "Memorial Day";

$holidays{ 1997,  7,  4 } =
$holidays{ 1998,  7,  5 } =
$holidays{ 1999,  7,  4 } =
$holidays{ 2000,  7,  4 } =
$holidays{ 2001,  7,  4 } =
$holidays{ 2002,  7,  4 } =
$holidays{ 2003,  7,  4 } =
$holidays{ 2004,  7,  5 } =
$holidays{ 2005,  7,  4 } =
$holidays{ 2006,  7,  4 } =
$holidays{ 2007,  7,  4 } =
$holidays{ 2008,  7,  4 } = 
$holidays{ 2009,  7,  3 } = 
$holidays{ 2010,  7,  5 } =
$holidays{ 2011,  7,  4 } =
$holidays{ 2012,  7,  4 } = 
$holidays{ 2013,  7,  4 } = 
$holidays{ 2014,  7,  4 } = 
$holidays{ 2015,  7,  3 } =
$holidays{ 2016,  7,  4 } = 
$holidays{ 2017,  7,  4 } = 
$holidays{ 2018,  7,  4 } = 
$holidays{ 2019,  7,  4 } =
$holidays{ 2020,  7,  3 } = 
$holidays{ 2021,  7,  5 } = 
$holidays{ 2022,  7,  4 } =
$holidays{ 2023,  7,  4 } =
$holidays{ 2024,  7,  4 } = 
$holidays{ 2025,  7,  4 } = "Independence Day";

$holidays{ 1997,  9,  1 } =
$holidays{ 1998,  9,  1 } =
$holidays{ 1999,  9,  6 } =
$holidays{ 2000,  9,  4 } =
$holidays{ 2001,  9,  3 } =
$holidays{ 2002,  9,  2 } =
$holidays{ 2003,  9,  1 } =
$holidays{ 2004,  9,  6 } =
$holidays{ 2005,  9,  5 } =
$holidays{ 2006,  9,  4 } =
$holidays{ 2007,  9,  3 } =
$holidays{ 2008,  9,  1 } = 
$holidays{ 2009,  9,  7 } = 
$holidays{ 2010,  9,  6 } =
$holidays{ 2011,  9,  5 } =
$holidays{ 2012,  9,  3 } = 
$holidays{ 2013,  9,  2 } = 
$holidays{ 2014,  9,  1 } = 
$holidays{ 2015,  9,  7 } =
$holidays{ 2016,  9,  5 } = 
$holidays{ 2017,  9,  4 } = 
$holidays{ 2018,  9,  3 } = 
$holidays{ 2019,  9,  2 } =
$holidays{ 2020,  9,  7 } = 
$holidays{ 2021,  9,  6 } = 
$holidays{ 2022,  9,  5 } =
$holidays{ 2023,  9,  4 } =
$holidays{ 2024,  9,  2 } = 
$holidays{ 2025,  9,  1 } = "Labor Day";

$holidays{ 1997, 10, 13 } =
$holidays{ 1998, 10, 13 } =
$holidays{ 1999, 10, 11 } =
$holidays{ 2000, 10,  9 } =
$holidays{ 2001, 10,  8 } =
$holidays{ 2002, 10, 14 } =
$holidays{ 2003, 10, 13 } =
$holidays{ 2004, 10, 11 } =
$holidays{ 2005, 10, 10 } =
$holidays{ 2006, 10,  9 } =
$holidays{ 2007, 10,  8 } =
$holidays{ 2008, 10, 13 } = 
$holidays{ 2009, 10, 12 } = 
$holidays{ 2010, 10, 11 } =
$holidays{ 2011, 10, 10 } =
$holidays{ 2012, 10,  8 } = 
$holidays{ 2013, 10, 14 } = 
$holidays{ 2014, 10, 13 } = 
$holidays{ 2015, 10, 12 } =
$holidays{ 2016, 10, 10 } = 
$holidays{ 2017, 10,  9 } = 
$holidays{ 2018, 10,  8 } = 
$holidays{ 2019, 10, 14 } =
$holidays{ 2020, 10, 12 } = 
$holidays{ 2021, 10, 11 } = 
$holidays{ 2022, 10, 10 } =
$holidays{ 2023, 10,  9 } =
$holidays{ 2024, 10, 14 } = 
$holidays{ 2025, 10, 13 } = "Columbus Day";

$holidays{ 1997, 11, 11 } =
$holidays{ 1998, 11, 11 } =
$holidays{ 1999, 11, 11 } =
$holidays{ 2000, 11, 10 } =
$holidays{ 2001, 11, 12 } =
$holidays{ 2002, 11, 11 } =
$holidays{ 2003, 11, 11 } =
$holidays{ 2004, 11, 11 } =
$holidays{ 2005, 11, 11 } =
$holidays{ 2006, 11, 10 } =
$holidays{ 2007, 11, 12 } =
$holidays{ 2008, 11, 11 } = 
$holidays{ 2009, 11, 11 } =
$holidays{ 2010, 11, 11 } =
$holidays{ 2011, 11, 11 } =
$holidays{ 2012, 11, 12 } = 
$holidays{ 2013, 11, 11 } = 
$holidays{ 2014, 11, 11 } = 
$holidays{ 2015, 11, 11 } =
$holidays{ 2016, 11, 11 } = 
$holidays{ 2017, 11, 10 } = 
$holidays{ 2018, 11, 12 } = 
$holidays{ 2019, 11, 11 } =
$holidays{ 2020, 11, 11 } = 
$holidays{ 2021, 11, 11 } = 
$holidays{ 2022, 11, 11 } =
$holidays{ 2023, 11, 10 } =
$holidays{ 2024, 11, 11 } = 
$holidays{ 2025, 11, 11 } = "Veterans Day";

$holidays{ 1997, 11, 27 } =
$holidays{ 1998, 11, 27 } =
$holidays{ 1999, 11, 25 } =
$holidays{ 2000, 11, 23 } =
$holidays{ 2001, 11, 22 } =
$holidays{ 2002, 11, 28 } =
$holidays{ 2003, 11, 27 } =
$holidays{ 2004, 11, 25 } =
$holidays{ 2005, 11, 24 } =
$holidays{ 2006, 11, 23 } =
$holidays{ 2007, 11, 22 } =
$holidays{ 2008, 11, 27 } = 
$holidays{ 2009, 11, 26 } = 
$holidays{ 2010, 11, 25 } =
$holidays{ 2011, 11, 24 } =
$holidays{ 2012, 11, 22 } = 
$holidays{ 2013, 11, 28 } = 
$holidays{ 2014, 11, 27 } = 
$holidays{ 2015, 11, 26 } =
$holidays{ 2016, 11, 24 } = 
$holidays{ 2017, 11, 23 } = 
$holidays{ 2018, 11, 22 } = 
$holidays{ 2019, 11, 28 } =
$holidays{ 2020, 11, 26 } = 
$holidays{ 2021, 11, 25 } = 
$holidays{ 2022, 11, 24 } =
$holidays{ 2023, 11, 23 } =
$holidays{ 2024, 11, 28 } = 
$holidays{ 2025, 11, 27 } = "Thanksgiving Day";

$holidays{ 1997, 12, 25 } =
$holidays{ 1998, 12, 25 } =
$holidays{ 1999, 12, 24 } =
$holidays{ 2000, 12, 25 } =
$holidays{ 2001, 12, 25 } =
$holidays{ 2002, 12, 25 } =
$holidays{ 2003, 12, 25 } =
$holidays{ 2004, 12, 24 } =
$holidays{ 2005, 12, 26 } =
$holidays{ 2006, 12, 25 } =
$holidays{ 2007, 12, 25 } = 
$holidays{ 2008, 12, 25 } = 
$holidays{ 2009, 12, 25 } =
$holidays{ 2010, 12, 24 } =
$holidays{ 2011, 12, 26 } =
$holidays{ 2012, 12, 25 } = 
$holidays{ 2013, 12, 25 } = 
$holidays{ 2014, 12, 25 } = 
$holidays{ 2015, 12, 25 } =
$holidays{ 2016, 12, 25 } = 
$holidays{ 2017, 12, 25 } = 
$holidays{ 2018, 12, 25 } = 
$holidays{ 2019, 12, 25 } =
$holidays{ 2020, 12, 25 } = 
$holidays{ 2021, 12, 24 } = 
$holidays{ 2022, 12, 26 } =
$holidays{ 2023, 12, 25 } =
$holidays{ 2024, 12, 25 } = 
$holidays{ 2025, 12, 25 } =   "Christmas Day";


sub is_usfed_holiday {
    my ($year, $month, $day) = @_;
    return $holidays{ $year, $month, $day };
}

1;
__END__
=head1 US Federal Holiday Data

The holidays are listed on the US Government Office of Personnel Management
web site - http://www.opm.gov/Fedhol/

=head1 CAVEATS

The module current only contains US Federal holiday information for years 1997-2025.

=head1 AUTHOR

Doug Morris <dougmorris at mail d0t nih D0T gov >

=head1 COPYRIGHT

US government.  All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 BUGS

None known.

Bugs should be reported to me via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date::Holidays::USFederal>.

=head1 SEE ALSO

L<Date::Holidays::UK>, L<Date::Japanese::Holiday>

=cut
