package Date::Holidays::USA;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Provides United States of America holidays

use warnings;
use strict;

use utf8;
use Date::Easter qw(easter);
use DateTime ();
use Exporter qw(import);

our @EXPORT = qw(is_holiday holidays);

our $VERSION = '0.0204';


sub new {
    my $self = shift;
    bless \$self => $self;
}


sub is_holiday {
    my ($self, $year, $month, $day) = @_;
    return undef unless $year && $month && $day;
    my $holidays = $self->holidays($year);
    my $str = sprintf '%02d%02d', $month, $day;
    return $holidays->{$str} ? $holidays->{$str} : undef;
}


sub us_holidays {
    my ($self, $year) = @_;
    unless ($year) {
      $year = (localtime)[5];
      $year += 1900;
    }
    my %dom = (
        memorial     => _nth_day_of_month(-1, 1, $year, 5),
        mothers      => _nth_day_of_month(2, 7, $year, 5),
        fathers      => _nth_day_of_month(3, 7, $year, 6),
        labor        => _nth_day_of_month(1, 1, $year, 9),
        columbus     => _nth_day_of_month(2, 1, $year, 10),
        thanksgiving => _nth_day_of_month(4, 4, $year, 11),
    );
    my %holidays = (
        1 => {
            1  => "New Year's",
            15 => 'Martin Luther King Jr.',
        },
        2 => {
            14 => "Valentine's",
            19 => "President's",
        },
        3 => {
            17 => "St. Patrick's",
        },
        4 => {
        },
        5 => {
            5 => 'Cinco de Mayo',
            $dom{mothers}  => "Mother's",
            $dom{memorial} => 'Memorial',
        },
        6 => {
            14 => 'Flag',
            $dom{fathers} => "Father's",
            19 => 'Juneteenth',
        },
        7 => {
            4 => 'Independence',
        },
        8 => {
        },
        9 => {
            $dom{labor} => 'Labor',
        },
        10 => {
            $dom{columbus} => "Columbus; Indigenous Peoples'",
            31 => 'Halloween'
        },
        11 => {
            11 => 'Veterans',
            $dom{thanksgiving} => 'Thanksgiving',
        },
        12 => {
          24 => 'Christmas Eve',
          25 => 'Christmas',
          31 => "New Year's Eve",
        },
    );
    my ($month, $day) = easter($year);
    $holidays{$month}->{$day} = 'Easter';
    return \%holidays;
}


sub holidays {
    my ($self, $year) = @_;
    my $holidays = $self->us_holidays($year);
    my %rtn;
    for my $month (sort { $a <=> $b } keys %$holidays) {
        for my $day (sort { $a <=> $b } keys %{ $holidays->{$month} }) {
            $rtn{ sprintf '%02d%02d', $month, $day } = $holidays->{$month}->{$day}
                if $holidays->{$month}->{$day};
        }
    }
    return \%rtn;
}

# https://stackoverflow.com/questions/18908238/perl-datetime-module-calculating-first-second-third-fouth-last-sunday-monda
# Here $nth is 1, 2, 3... for first, second, third, etc.
# Or -1, -2, -3... for last, next-to-last, etc.
# $dow is 1-7 for Monday-Sunday. $month is 1-12
sub _nth_day_of_month {
    my ($nth, $dow, $year, $month) = @_;

    my ($date, $delta);
    if ($nth > 0) {
        # For 1st etc. we want the last day of that week (i.e. 7, 14, 21, 28, "35")
        $date  = DateTime->new(year => $year, month => $month, day => 1);
        $delta = $nth * 7 - 1;
    } else {
        # For last etc. we want the last day of the month (minus a week if next-to-last, etc)
        $date  = DateTime->last_day_of_month(year => $year, month => $month);
        $delta = 7 * ($nth + 1); # $nth is negative
    }

    # Back up to the first $dow on or before $date + $delta
    $date->add(days => $delta - ($date->day_of_week + $delta - $dow) % 7);

    # If we're not in the right month, then that month doesn't have the specified date
    return (($date->month == $month) ? $date->day : undef);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Date::Holidays::USA - Provides United States of America holidays

=head1 VERSION

version 0.0204

=head1 SYNOPSIS

  # Using with the Date::Holidays module:
  use Date::Holidays ();
  my $dh = Date::Holidays->new(countrycode => 'USA', nocheck => 1);
  print $dh->is_holiday(year => 2024, month => 1, day => 1), "\n";
  my $h = $dh->holidays;

  # Using the Date::Holidays::USA module directly:
  use Date::Holidays::USA ();
  $dh = Date::Holidays::USA->new;
  print $dh->is_holiday(2024, 1, 1), "\n";
  $h = $dh->holidays;
  $h = $dh->us_holidays(2032);

=head1 DESCRIPTION

C<Date::Holidays::USA> provides United States of America holidays.

=head1 METHODS

=head2 new

  $dh = Date::Holidays::USA->new;

Return a new C<Date::Holidays::USA> object.

=head2 is_holiday

  $holiday = is_holiday($year, $month, $day);

Takes three arguments:

  year:  four digits
  month: between 1-12
  day:   between 1-31

Returns the name of the holiday, if one exists on that day.

=head2 us_holidays

  $holidays = us_holidays;
  $holidays = us_holidays($year);

Returns a hash reference of holiday names, where the keys are by month
and day.

=head2 holidays

  $holidays = holidays;
  $holidays = holidays($year);

Returns a hash reference of holiday names, where the keys are 4 digit
strings month and day.

=head1 SEE ALSO

L<Date::Holidays>

L<Date::Holidays::Adapter>

L<Date::Holidays::Adapter::USA>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Gene Boggs.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
