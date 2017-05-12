package Calendar::Any::Julian;
{
  $Calendar::Any::Julian::VERSION = '0.5';
}
use Carp;
use POSIX qw/ceil/;
use base 'Calendar::Any';
my @MONTH_DAYS = (0,31,59,90,120,151,181,212,243,273,304,334,365);
our $default_format = "%D";

sub MONTH_DAYS {
    return @MONTH_DAYS;
}

sub new {
    my $_class = shift;
    my $class = ref $_class || $_class;
    my $self = {};
    bless $self, $class;
    if ( @_ ) {
        my %arg;
        if ( $_[0] =~ /-\D/ ) {
            %arg = @_;
        } else {
            if ( scalar(@_) == 3 ) {
                $arg{$_} = shift for qw(-month -day -year);
            } else {
                return $self->from_absolute(shift);
            }
        }
        foreach ( qw(-month -day -year) ) {
            $self->{substr($_, 1)} = $arg{$_} if exists $arg{$_};
        }
        $self->absolute_date();
    }
    return $self;
}

sub from_absolute {
    use integer;
    my $self = shift;
    my $date = shift;
    $self->{absolute} = $date;
    $date++;
    my $n4 = $date / 1461;
    my $d0 = $date % 1461;
    my $n1 = $d0 / 365;
    my $day = $d0 % 365 + 1;
    my $year = 4 * $n4 + $n1;
    my $month;
    if ( $n1==4 ) {
        $month = 12;
        $day = 31;
    } else {
        $year++;
        $month = ceil($day/31);
        my $leap = (_is_leap_year($year) ? 1 : 0);
        while ($day > $MONTH_DAYS[$month] + ($month >1 ? $leap: 0)) {
            $month++;
        }
        $day = $day-$MONTH_DAYS[$month-1]-($month>2?$leap:0);
    }
    $self->{year} = $year;
    $self->{month} = $month;
    $self->{day} = $day;
    return $self;
}

sub absolute_date {
    use integer;
    my $self = shift;
    if ( exists $self->{absolute} ) {
        return $self->{absolute};
    }
    $self->assert_date();
    return $self->{absolute} = _absoulte_date($self->month, $self->day, $self->year);
}

sub is_leap_year {
    return _is_leap_year(shift->year);
}

sub day_of_year {
    my $self = shift;
    return _day_of_year($self->month, $self->day, $self->year);
}

sub last_day_of_month {
    my $self = shift;
    return _last_day_of_month($self->month, $self->year);
}

sub assert_date {
    my $self = shift;
    if ( $self->year == 0 ) {
        croak('Not a valid year: should not be zero in ' . ref $self);
    }
    if ( $self->month < 1 || $self->month > 12 ) {
        confess(sprintf('Not a valid month %d: should from 1 to 12 for %s', $self->month, ref $self));
    }
    if ( $self->day < 1 || $self->day > $self->last_day_of_month() ) {
        confess(sprintf('Not a valid day %d: should from 1 to %d in month %d %d for %s',
                        $self->day, $self->last_day_of_month, $self->month, $self->year, ref $self));
    }
}

#==========================================================
# Private functions
#==========================================================
sub _absoulte_date {
    my ($month, $day, $year) = @_;
    int(_day_of_year($month, $day, $year) + 365*($year-1) + ($year-1)/4 -2);
}

sub _day_of_year {
    use integer;
    my ($month, $day, $year) = @_;
    my $day_of_year = $day + 31 * ($month-1);
    if ( $month > 2) {
        $day_of_year -= (23 + 4*$month)/10;
        if ( _is_leap_year($year) ) {
            $day_of_year++;
        }
    }
    return $day_of_year;
}

sub _is_leap_year {
    my $year = shift;
    if ( $year < 0 ) {
        $year = abs($year) - 1;
    }
    $year % 4 == 0
}

sub _last_day_of_month {
    my ($month, $year) = @_;
    return unless $month>0 && $month<13;
    if ( $month==2 && _is_leap_year($year) ) {
        29;
    } else {
        $MONTH_DAYS[$month]-$MONTH_DAYS[$month-1];
    }
}

1;

__END__

=head1 NAME

Calendar::Any::Julian - Perl extension for Julian Calendar

=head1 VERSION

version 0.5

=head1 SYNOPSIS

   use Calendar::Any::Julian;
   my $date = Calendar::Any::Julian->new(1, 1, 2006);

=head1 DESCRIPTION

From "FREQUENTLY ASKED QUESTIONS ABOUT CALENDARS"(C<http://www.tondering.dk/claus/calendar.html>)

=over

The Julian calendar was introduced by Julius Caesar in 45 BC. It was
in common use until the late 1500s, when countries started changing to
the Gregorian calendar (section 2.2). However, some countries (for
example, Greece and Russia) used it into the early 1900s, and the
Orthodox church in Russia still uses it, as do some other Orthodox
churches.

In the Julian calendar, the tropical year is approximated as 365 1/4
days = 365.25 days. This gives an error of 1 day in approximately 128
years.

The approximation 365 1/4 is achieved by having 1 leap year every 4
years.

=back

=head1 METHOD

=over 4

=item  is_leap_year

True if the date in a leap year.

=item  day_of_year

Return the day of year the day of the year, in the range 1..365 (or
1..366 in leap years.)

=item  last_day_of_month

Return the last day in the month. For example:

    $date = Calendar::Any::Julian->new(2, 1, 2006);
    print $date->last_day_of_month;       # output 28

=back

=head1 AUTHOR

Ye Wenbin <wenbinye@gmail.com>

=head1 SEE ALSO

L<Calendar::Any>, L<Calendar::Any::Gregorian>

=cut
