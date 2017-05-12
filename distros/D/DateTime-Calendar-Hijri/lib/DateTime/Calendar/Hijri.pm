package DateTime::Calendar::Hijri;

use strict;

use vars qw($VERSION);

$VERSION = '0.00';

use Date::Hijri;
use Params::Validate qw(validate SCALAR OBJECT);

sub new {
    my $class = shift;
    my %p = validate( @_,
                      { year  => {type => SCALAR},
                        month => {type => SCALAR, default => 1},
                        day   => {type => SCALAR, default => 1},
                        rd_secs   => { type => SCALAR, default => 0},
                        rd_nano   => { type => SCALAR, default => 0},
                      } );

    $p{rd} = Date::Hijri::Islamic2Absolute(@p{qw(day month year)});

    return bless \%p, $class;
}

sub year { $_[0]->{year} }

sub month { $_[0]->{month} }

sub day { $_[0]->{day} }

sub datetime {
    return $_[0]->year .'-'. $_[0]->month .'-'. $_[0]->day .' AH';
}

sub from_object {
    my $class = shift;
    my %p = validate( @_,
                      { object => { type => OBJECT,
                                    can => 'utc_rd_values',
                                  },
                      } );

    my %parts;
    @parts{qw(rd rd_secs rd_nano)} = $p{object}->utc_rd_values;
    @parts{qw(day month year)} = Date::Hijri::Absolute2Islamic($parts{rd});
    return bless \%parts, $class;
}

sub utc_rd_values {
    my ($self) = @_;
    return $self->{rd}, $self->{rd_secs}, $self->{rd_nano};
}

1;
__END__

=head1 NAME

DateTime::Calendar::Hijri - Dates in the Hijri (Islamic) calendar

=head1 SYNOPSIS

    use DateTime::Calendar::Hijri;
    $dt = DateTime::Calendar::Hijri->new( year => 1424,
                                          month => 1,
                                          day => 1);

    $year = $dt->year;      # 1424
    $month = $dt->month;    # 1
    $day = $dt->day;        # 1

    $str = $dt->datetime;   # "1424-1-1 AH"

    $dt = DateTime::Calendar::Hijri->from_object(
                                            object => $datetime_obj
                                     );

=head1 DESCRIPTION

The Hijri calendar is based on the flight of Mohammed from Mecca to
Medina in the year 622 in the Gregorian calendar. This was taken as the
start of the new calendar, which is still used in a number of Islamic
countries.

Like the Gregorian calendar, the Hijri year consists of 12 months. The
start of each month is determined by the observation of the young moon.
This means that the Hijri calendar is not predictable: it is not known
beforehand when a new month will start. Several algorithms have been
written to predict the starting days of the month, and one of them is
used by this module. The calculated dates can therefore be one or two
days off the actual dates.

=head1 METHODS

=over 4

=item * new( ... )

Creates a new Hijri date object. Possible parameters are "year", "month"
and "day".

=item * year , month , day

Return parts of a Hijri date.

=item * datetime

Returns a string representing the Hijri date.

=item * from_object( object => ... )

Creates a Hijri date from another datetime compatible object.

=item * utc_rd_values

Returns the rata die count of days. This is used to convert from a Hijri
date to another calendar

=head1 BUGS

=item *

The dates are sometimes wrong by one or two days when you convert to or
from other calendars. This can't be helped, as the Hijri calendar is
based on observations, not on an algorithm.

=item *

The functionality offered by this module is rather minimal compared to
other calendar modules within the DateTime project. This is because I am
not very familiar with the Hijri calendar, and I feel I am unable to do
it justice. If you can, and if you are willing to put some time into
improving this module, I would be glad to hand over the maintainership.
Mail me!

=back

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list. See http://lists.perl.org/ for more details.

=head1 AUTHOR

Eugene van der Pijll <pijll@gmx.net>

This module uses the Date::Hijri module by Alex Pleiner for all
calculations.

=head1 COPYRIGHT

Copyright (c) 2003 Eugene van der Pijll.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<DateTime>

datetime@perl.org mailing list

http://datetime.perl.org/

=cut
