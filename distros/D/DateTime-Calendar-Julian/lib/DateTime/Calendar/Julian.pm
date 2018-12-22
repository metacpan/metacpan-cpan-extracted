package DateTime::Calendar::Julian;

use strict;
use warnings;

use vars qw($VERSION @ISA);

$VERSION = '0.100';

use DateTime 0.08;
@ISA = 'DateTime';

sub _floor {
    my $x  = shift;
    my $ix = int $x;
    if ($ix <= $x) {
        return $ix;
    } else {
        return $ix - 1;
    }
}

my @start_of_month = (0, 31, 61, 92, 122, 153, 184, 214, 245, 275, 306, 337);

# Julian dates are formatted in exactly the same way as Gregorian dates,
# so we use most of the DateTime methods.

# This is the difference between Julian and Gregorian calendar:
sub _is_leap_year {
    my (undef, $year) = @_;	# Invocant unused

    return ($year % 4 == 0);
}

# Algorithms from http://home.capecod.net/~pbaum/date/date0.htm
sub _ymd2rd {	## no critic (ProhibitUnusedPrivateSubroutines)
    my (undef, $y, $m, $d) = @_;	# Invocant unused

    my $adj = _floor( ($m-3)/12 );
    $m -= 12 * $adj;
    $y += $adj;

    my $rd = $d + $start_of_month[$m-3] + 365*$y + _floor($y/4) - 308;
    return $rd;
}

sub _rd2ymd {	## no critic (ProhibitUnusedPrivateSubroutines)
    my ($self, $rd, $extra) = @_;

    my $z = $rd + 308;
    my $y = _floor(($z*100-25)/36525);
    my $c = $z - _floor(365.25*$y);
    my $m = int((5*$c + 456)/153);
    my $d = $c - $start_of_month[$m-3];
    if ($m > 12) {
        $m -= 12;
        $y++;
    }

    if ($extra) {
        # day_of_week, day_of_year
        my $doy = ($c + 31 + 28 - 1)%365 + 1 +
                      ($self->_is_leap_year($y) && $m > 2);
        my $dow = (($rd + 6)%7) + 1;
        return $y, $m, $d, $dow, $doy;
    }
    return $y, $m, $d;
}

sub epoch {
    my $self = shift;

    my $greg = DateTime->from_object( object => $self );
    return $greg->epoch;
}

sub from_epoch {
    my $class = shift;

    my $greg = DateTime->from_epoch( @_ );
    return $class->from_object( object => $greg );
}

sub gregorian_deviation {
    my $self = shift;

    my $year = $self->{local_c}{year};
    $year-- if $self->{local_c}{month} <= 2;

    return _floor($year/100)-_floor($year/400)-2;
}

sub datetime {
    my $self = shift;

    return join 'J', $self->ymd, $self->hms(':');
}

1;

__END__

=head1 NAME

DateTime::Calendar::Julian - Dates in the Julian calendar

=head1 SYNOPSIS

  use DateTime::Calendar::Julian;

  $dt = DateTime::Calendar::Julian->new( year  => 964,
                                         month => 10,
                                         day   => 16,
                                       );

  # convert Julian->Gregorian...

  $dtgreg = DateTime->from_object( object => $dt );
  print $dtgreg->datetime;  # prints '0964-10-21T00:00:00'

  # ... and back again

  $dtjul = DateTime::Calendar::Julian->from_object( object => $dtgreg );
  print $dtjul->datetime;  # prints '0964-10-16J00:00:00'

=head1 DESCRIPTION

DateTime::Calendar::Julian implements the Julian Calendar.  This module
implements all methods of DateTime; see the DateTime(3) manpage for all
methods.

=head1 METHODS

This module implements one additional method besides the ones from
DateTime, and changes the output of one other method.

=over 4

=item * gregorian_deviation

Returns the difference in days between the Gregorian and the Julian
calendar.

=item * datetime

This method is now equivalent to:

  $dt->ymd('-') . 'J' . $dt->hms(:)

=back

=head1 BACKGROUND

The Julian calendar was introduced by Julius Caesar in 46BC.  It
featured a twelve-month year of 365 days, with a leap year in February
every fourth year.  This calendar was adopted by the Christian church in
325AD.  Around 532AD, Dionysius Exiguus moved the starting point of the
Julian calendar to the calculated moment of birth of Jesus Christ. Apart
from differing opinions about the start of the year (often January 1st,
but also Christmas, Easter, March 25th and other dates), this calendar
remained unchanged until the calendar reform of pope Gregory XIII in
1582.  Some backward countries, however, used the Julian calendar until
the 18th century or later.

This module uses the proleptic Julian calendar for years before 532AD,
or even 46BC.  This means that dates are calculated as if this calendar
had existed unchanged from the beginning of time.  The assumption is
made that January 1st is the first day of the year.

Note that BC years are given as negative numbers, with 0 denoting the
year 1BC (there was no year 0AD!), -1 the year 2BC, etc.

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list. See http://lists.perl.org/ for more details.

Bug reports will be accepted as RT tickets or by mail to Wyant.

=head1 AUTHOR

Eugene van der Pijll <pijll@gmx.net>

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003 Eugene van der Pijll.  All rights reserved.

Copyright (C) 2018 Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 SEE ALSO

L<DateTime|/DateTime>

L<DateTime::Calendar::Christian|DateTime::Calendar::Christian>

datetime@perl.org mailing list

L<http://datetime.perl.org/>

=cut

# ex: set textwidth=72 :
