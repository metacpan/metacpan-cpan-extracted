package Date::Holidays::UK;
use strict;
use warnings;
use base qw(Exporter);
our $VERSION = '0.01';
our @EXPORT = qw( is_uk_holiday );

=head1 NAME

Date::Holidays::UK - Determine UK Public Holidays

=head1 SYNOPSIS

  use Date::Holidays::UK;
  my ($year, $month, $day) = (localtime)[ 5, 4, 3 ];
  $year  += 1900;
  $month += 1;
  print "Woohoo" if is_uk_holiday( $year, $month, $day );

=head1 DESCRIPTION

Naming modules is a tricky thing, especially when similar modules
already exist.  The awkwardness can be further excaberated when the
similar modules don't have consistent apis.

In this case we started by contrasting L<Date::Japanese::Holiday> and
L<Date::Holidays::DE>.  We've crossed the streams by taking the simple
is_*_holiday interface from L<Date::Japanese::Holiday>, and taken the
Date::Holidays::<country> convention from Date::Holidays::DE.  We hope
nothing explodes.

=head1 SUBROUTINES

=head2 is_uk_holiday( $year, $month, $day )

Returns the name of the Holiday that falls on the given day, or undef
if there is none.

=cut

# XXX either programatically fill these, or just do the monkey work
# OOK!
our %holidays;

$holidays{ 2004,  1,  1 } =
$holidays{ 2005,  1,  3 } =
$holidays{ 2006,  1,  2 } =
$holidays{ 2007,  1,  1 } = "New Year's Day";

$holidays{ 2004,  4,  9 } =
$holidays{ 2005,  3, 25 } =
$holidays{ 2006,  4, 14 } =
$holidays{ 2007,  4,  6 } = "Good Friday";

$holidays{ 2004,  4, 12 } =
$holidays{ 2005,  3, 28 } =
$holidays{ 2006,  4, 17 } =
$holidays{ 2007,  4,  9 } = "Easter Monday";

$holidays{ 2004,  5,  3 } =
$holidays{ 2005,  5,  2 } =
$holidays{ 2006,  5,  1 } =
$holidays{ 2007,  5,  7 } = "Early May Bank Holiday";

$holidays{ 2004,  5, 31 } =
$holidays{ 2005,  5, 30 } =
$holidays{ 2006,  5, 29 } =
$holidays{ 2007,  5, 28 } = "Spring Bank Holiday";

$holidays{ 2004,  8, 30 } =
$holidays{ 2005,  8, 29 } =
$holidays{ 2006,  8, 28 } =
$holidays{ 2007,  8, 27 } = "Summer Bank Holiday";

$holidays{ 2004, 12, 25 } =
$holidays{ 2005, 12, 25 } =
$holidays{ 2006, 12, 25 } =
$holidays{ 2007, 12, 25 } = "Christmas Day";

$holidays{ 2004, 12, 26 } =
$holidays{ 2005, 12, 26 } =
$holidays{ 2006, 12, 26 } =
$holidays{ 2007, 12, 26 } = "Boxing Day";

$holidays{ 2004, 12, 27 } = "Substitute Bank Holiday in lieu of 26th";

$holidays{ 2004, 12, 28 } =
$holidays{ 2005, 12, 27 } = "Substitute Bank Holiday in lieu of 25th";

sub is_uk_holiday {
    my ($year, $month, $day) = @_;
    return $holidays{ $year, $month, $day };
}

1;
__END__
=head1 Holiday Data

The DTI's webpage http://www.dti.gov.uk/er/bankhol.htm is taken as the
canonical source for bank holidays.

=head1 CAVEATS

We only currently contain the DTI bank holiday detail, which at the
time of writing only covers the years 2004-2007.

=head1 AUTHOR

Richard Clamp <richardc@fotango.com>, Amelie Guyot, Jerome Parfant.

=head1 COPYRIGHT

Copyright 2004 Fotango.  All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 BUGS

None known.

Bugs should be reported to me via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date::Holidays::UK>.

=head1 SEE ALSO

L<Date::Holidays::DE>, L<Date::Japanese::Holiday>

=cut
