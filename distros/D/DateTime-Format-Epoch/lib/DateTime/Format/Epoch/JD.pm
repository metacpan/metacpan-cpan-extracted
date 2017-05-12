package DateTime::Format::Epoch::JD;

use strict;

use vars qw($VERSION @ISA);

$VERSION = '0.13';

use DateTime;
use DateTime::Format::Epoch;

@ISA = qw/DateTime::Format::Epoch/;

my $epoch = DateTime->new( year => -4713, month => 11,
                           day => 24, hour => 12 );

sub new {
	my $class = shift;

    return $class->SUPER::new( epoch => $epoch,
                               unit  => 1/86400,
                               type  => 'float',
                               skip_leap_seconds => 1 );
}

1;
__END__

=head1 NAME

DateTime::Format::Epoch::JD - Convert DateTimes to/from Julian Days

=head1 SYNOPSIS

  use DateTime::Format::Epoch::JD;

  my $dt = DateTime::Format::Epoch::JD->parse_datetime( 2453244.5 );
   # 2004-08-27T00:00:00
  DateTime::Format::Epoch::JD->format_datetime($dt);
   # 2453244.5

  my $formatter = DateTime::Format::Epoch::JD->new();
  my $dt2 = $formatter->parse_datetime( 2453244.5 );
   # 2004-08-27T00:00:00
  $formatter->format_datetime($dt2);
   # 2453244.5

=head1 DESCRIPTION

This module can convert a DateTime object (or any object that can be
converted to a DateTime object) to the Julian Day number. This is the
number of days since noon U.T.C. on January 1, 4713 B.C. (Julian
calendar).

This time scale was originally proposed by John Herschel, and is
often used in astronomical calculations.

Similar modules are:

=over 4

=item * DateTime::Format::Epoch::MJD

Implements the "modified Julian Day", starting at midnight U.T.C.,
November 17, 1858.  This number is always 2,400,000.5 lower than the JD,
and this count only uses five digits to specify a date between 1859 and
about 2130.

=item * DateTime::Format::Epoch::RJD

Implements the "reduced Julian Day", starting at noon U.T.C., November
16, 1858.  This number is always 2,400,000 lower than the JD.

=item * DateTime::Format::Epoch::TJD

Implements the "truncated Julian Day", starting at midnight U.T.C., May
24, 1968.  This number is always 2,440,000,5 lower than the JD.
Actually, there is another version of the TJD, defined as JD modulo
10,000.  But that one is a bit harder to implement, so you'll have to do
with this version of TJD.  Or don't use TJD's at all.

=item * DateTime::Format::Epoch::RataDie

Implements the Rata Die count, starting at January 1, 1 (Gregorian).
This count is used by DateTime::Calendar programmers.

=item * DateTime::Format::Epoch::Lilian

Implements the Lilian count, named after Aloysius Lilian (a 16th century
physician) and first used by IBM (a 19th century punched card machine
manufacturer).  This counts the number of days since the adoption of the
Gregorian calendar.  Only days are counted, and October 15, 1584 is day
1.

=back

=head1 METHODS

Most of the methods are the same as those in L<DateTime::Format::Epoch>.
The only difference is the constructor.

=over 4

=item * new()

Constructor of the formatter/parser object. It has no parameters.

=back

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list. See http://lists.perl.org/ for more details.

=head1 AUTHOR

Eugene van der Pijll <pijll@gmx.net>

=head1 COPYRIGHT

Copyright (c) 2004 Eugene van der Pijll.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<DateTime>

datetime@perl.org mailing list

=cut
