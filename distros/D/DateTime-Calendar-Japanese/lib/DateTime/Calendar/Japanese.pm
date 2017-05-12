# $Id: Japanese.pm 3782 2007-11-01 23:18:42Z lestrrat $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package DateTime::Calendar::Japanese;
use strict;
use warnings;
use vars qw(@ISA $VERSION);
BEGIN
{
    $VERSION = '0.06001';
    @ISA     = qw(DateTime::Calendar::Chinese);
}
use DateTime;
use DateTime::Util::Calc qw(amod truncate_to_midday);
use DateTime::Calendar::Chinese;
use DateTime::Calendar::Japanese::Era;
use DateTime::Event::Sunrise;
use Params::Validate();

my %NewValidate = (
    era_year => {
        depends  => [ 'era_name' ],
        type     => Params::Validate::SCALAR(),
        optional => 1,
    },
    era_name => {
        depends  => [ 'era_year' ],
        type     => Params::Validate::SCALAR(),
        optional => 1,
    },
    hour     => {
        type      => Params::Validate::SCALAR(),
        default   => 1,
        callbacks => { 'is between 1 and 12' =>
            sub { $_[0] >= 1 && $_[0] <= 12 } }
    },
    hour_quarter => {
        type      => Params::Validate::SCALAR(),
        default   => 1,
        callbacks => { 'is between 1 and 4' =>
            sub { $_[0] >= 1 && $_[0] <= 4 } }
    },
    cycle => {
        default => 1,
    },
    cycle_year  => {
        default   => 1,
        callbacks => {
            'is between 1 and 60' => sub { $_[0] >= 1 && $_[0] <= 60 }
        }
    },
    month => {
        default   => 1,
        callbacks => {
            'is between 1 and 12' => sub { $_[0] >= 1 && $_[0] <= 12 }
        }
    },
    leap_month => {
        default => 0,
        type => Params::Validate::BOOLEAN()
    },
    day        => {
        default   => 1,
        type => Params::Validate::SCALAR()
    },
    locale    => { type => Params::Validate::SCALAR() | Params::Validate::OBJECT(), optional => 1 },
    language  => { type => Params::Validate::SCALAR() | Params::Validate::OBJECT(), optional => 1 },
    time_zone  => { type => Params::Validate::SCALAR() | Params::Validate::OBJECT(), default => 'Asia/Tokyo' },
);

sub _era2cycle
{
    my($era_name, $era_year) = @_;

    my $era = DateTime::Calendar::Japanese::Era->lookup_by_id(
        id => $era_name
    ) or Carp::croak("Lookup of era name $era_name failed");

    # it's darn hard to calculate the dates from the era years,
    # so we first calculate a date that will always fall in the
    # middle of the year, and then use the cycle/cycle_year
    # from that object.

    my $cc_date =
        DateTime::Calendar::Chinese->from_object(object => $era->start);

    my $ny_in_year =
        DateTime::Event::Chinese->new_year_for_gregorian_year(datetime => $era->start);

    my $elapsed_years = $cc_date->elapsed_years + $era_year;
    if ($ny_in_year >= $cc_date->{gregorian}) {
        $elapsed_years--;
    }
    my $cycle         = POSIX::floor( ($elapsed_years - 1) / 60) + 1;
    my $cycle_year    = amod($elapsed_years, 60);

#print STDERR 
#    "era2cycle: \n",
#    " start: ", $cc_date->{gregorian}->datetime,  "\n",
#    " start_cycle: ", $cc_date->cycle, "\n",
#    " start_cycle_year: ", $cc_date->cycle_year, "\n",
#    " era_name: ", $era_name,  "\n",
#    " era_year: ", $era_year,  "\n",
#    " cycle: ", $cycle,  "\n",
#    " cycle_year: ", $cycle_year, "\n"; 

    return ($cycle, $cycle_year);
}

sub new
{
    my $class = shift;
    my %args  = Params::Validate::validate_with(
        params => \@_,
        spec   => \%NewValidate,
        allow_extra => 1
    );

    if (exists $args{era_name}) {
        my $era_name = delete $args{era_name};
        my $era_year = delete $args{era_year};

        @args{ qw(cycle cycle_year) } = _era2cycle($era_name, $era_year);

#        $args{cycle}      = $cc_date->cycle + $delta_cycle;
#        $args{cycle_year} = $cycle_year;
    }

    my $adjust_time = 0;
    my ($hour, $hour_quarter);
    if (exists $args{hour} or $args{hour_quarter}) {
        ($hour, $hour_quarter) = (delete $args{hour}, delete $args{hour_quarter});
        $adjust_time = 1;
    }

    my $self = $class->SUPER::new(%args);
    $self->_calc_era_components();

    if ($adjust_time) {
        $self->_adjust_time_components($hour, $hour_quarter);
#    } else {
#        $self->_calc_time_components();
    }
    return $self;
}

# Tokyo
my %BaseLocation = (
    longitude => 139.45,
    latitude  => 35.40,
    iteration => 1
);

sub _calc_local_components
{
    my $self = shift;
    $self->SUPER::_calc_local_components();

    $self->_calc_era_components();
    $self->_calc_time_components();
}

sub _calc_era_components
{
    my $self = shift;

    my $era  = DateTime::Calendar::Japanese::Era->lookup_by_date(
        datetime => $self->{gregorian} );
    if ($era) {
        my $midday = truncate_to_midday($self->{gregorian}->clone);
        my $ny_this_gy = DateTime::Event::Chinese->new_year_for_gregorian_year(datetime => $midday);
        my $ny_start_gy = DateTime::Event::Chinese->new_year_for_gregorian_year(datetime => $era->start);


        my $year = $midday->year() - $era->start->year() + 1;
        # this date is before new year
        if ($ny_this_gy->year != $ny_start_gy->year && $ny_this_gy <= $midday) {
            $year++;
        }

        # start date is before new year
        if ($ny_this_gy->year == $ny_start_gy->year &&
            $self->{gregorian} >= $ny_start_gy &&
            $era->start() < $ny_start_gy) {
            $year++;
        }

        $self->{era}      = $era;
        $self->{era_year} = $year;

#print STDERR
#    "_calc_era_components\n",
#    "  \$self->elapsed_years: ", $self->elapsed_years, "\n",
#    "  \$self->{gregorian}: ", $self->{gregorian}->datetime, " (", $self->{gregorian}->time_zone_long_name, ")\n",
#    "  midday: ", $midday->datetime, " (", $midday->time_zone_long_name, ")\n",
#    "  era->start: ", $era->start->datetime, " (", $era->start->time_zone_long_name, ")\n",
#    "  \$ny_this_gy: ", $ny_this_gy->datetime, " (", $ny_this_gy->time_zone_long_name, ")\n",
#    "  \$ny_start_gy: ", $ny_start_gy->datetime, " (", $ny_start_gy->time_zone_long_name, ")\n",
#    "  era_year: ", $year, "\n";
    } else {
        $self->{era}      = undef;
        $self->{era_year} = 0;
    }
}

sub _calc_canonical_hour
{
    my $self = shift;
    my $hour = $self->hour;
    if (!defined($hour)) {
        Carp::confess("hour is undefined!");
    }
    $self->{canonical_hour} =
        ($hour > 3 && $hour < 10) ? 9 - ($hour - 4) :
        ($hour < 4)               ? 6 - ($hour - 3) :
                                    9 - ($hour - 10);
}

sub _calc_time_components
{
    my $self = shift;

    my $dt = $self->{gregorian};

    # XXX - hmmm, probably not kosher to do this.
    my $sunrise = DateTime::Event::Sunrise->new(%BaseLocation);
    my $span    = $sunrise->sunrise_sunset_span($dt);
    my($rise_dt, $set_dt) = ($span->start, $span->end);

    # We don't recompute if the time falls before or after the
    # given rise_dt and set_dt, because the times doesn't change
    # significantly on just one day. 

    my $three_day_pos = 2; # 1 - prev_set_dt <= dt < rise_dt
                           # 2 - rise_dt <= dt <= set_dt
                           # 3 - set_dt < dt <= next_rise_dt
    my($base_dt, $max_dt, $base_hour);
    if ($rise_dt > $dt) {
        $base_dt   = $set_dt->subtract(days => 1);
        $max_dt    = $rise_dt;
        $base_hour = 6;
    } elsif ($set_dt < $dt) {
        $base_dt   = $set_dt;
        $max_dt    = $rise_dt->add(days => 1);
        $base_hour = 6;
    } else {
        $base_dt   = $rise_dt;
        $max_dt    = $set_dt;
        $base_hour = 1;
    }

    my($hour, $hour_quarter) =
        _calc_japanese_time($dt, $base_dt, $max_dt, $base_hour);

    $self->{hour}           = $hour;
    $self->{hour_quarter}   = $hour_quarter;
    $self->_calc_canonical_hour();
}

sub _adjust_time_components
{
    my ($self, $hour, $hour_quarter) = @_;

    my $dt = $self->{gregorian};

    my $sunrise = DateTime::Event::Sunrise->new(%BaseLocation);
    my $span    = $sunrise->sunrise_sunset_span($dt);
    my($rise_dt, $set_dt) = ($span->start, $span->end);

    # first try a straight forward calculation. but
    # if the time is post midnight, then we calculate it from the
    # day before, so we can specify the time before sunrise

    my($new_dt, $base_dt, $hour_add_amount, $quarter_add_amount);

    if ($hour > 6) {
        my $one_hour     = (
            ($rise_dt + DateTime::Duration->new(days => 1)) - $set_dt
        )->multiply(1/6);
        my $quarter_hour = $one_hour * 0.25;
        $base_dt    = $set_dt;
        if ($hour > 1) {
            $hour_add_amount = ($hour - 7) * $one_hour;
        }
        if ($hour_quarter > 1) {
            $quarter_add_amount = ($hour_quarter - 1) * $quarter_hour;
        }
    } else {
        my $one_hour     = ($set_dt - $rise_dt)->multiply(1/6);
        my $quarter_hour = $one_hour * 0.25;
        $base_dt = $rise_dt;
        if ($hour > 1) {
            $hour_add_amount = ($hour - 1) * $one_hour;
        }
        if ($hour_quarter > 1) {
            $quarter_add_amount = ($hour_quarter - 1) * $quarter_hour;
        }
    }

    $new_dt = $base_dt;
    if ($hour_add_amount) {
        $new_dt += $hour_add_amount;
    }
    if ($quarter_add_amount) {
        $new_dt += $quarter_add_amount;
    }

    # if this date goes over today, then pull back one day
    my $next_day = $dt->clone->truncate(to => 'day')->add(days => 1);
    if ($new_dt >= $next_day) {
        $new_dt->subtract(days => 1);
    }

    $self->{gregorian}    = $new_dt;
    $self->{hour}         = $hour;
    $self->{hour_quarter} = $hour_quarter;
    $self->_calc_canonical_hour();
}

sub _calc_japanese_time
{
    my($dt, $base_dt, $max_dt, $base_hour) = @_;

    my($hour, $hour_quarter);

    my $one_hour     = ($max_dt - $base_dt)->multiply(1/6);
    my $quarter_hour = $one_hour * 0.25;

    my @h_separators = map { $base_dt + $one_hour * $_ } 0..6 ;
    foreach my $h_offset (0..$#h_separators - 1) {
        my $h_begin = $h_separators[$h_offset];
        my $h_end   = $h_separators[$h_offset + 1];
            
       if ($h_begin <= $dt && $dt < $h_end) {
            $hour = $base_hour + $h_offset;

            my @q_separators = map { $h_begin + $quarter_hour * $_ } 0..5;
            foreach my $quarter_offset (0..$#q_separators - 1) {
                my $quarter_begin = $q_separators[$quarter_offset];
                my $quarter_end   = $q_separators[$quarter_offset + 1];

                if($quarter_begin <= $dt && $dt < $quarter_end) {
                
                    $hour_quarter = $quarter_offset + 1;
                    last;
                }
            }
        }
    }

    if (!defined($hour) || !defined($hour_quarter)) {
        Carp::confess("hour or hour_quarter is undefined!");
    }

    return($hour, $hour_quarter);
}

sub era            { $_[0]->{era}            }
sub era_name       { $_[0]->{era}->id        }
sub era_year       { $_[0]->{era_year}       }
sub hour           { $_[0]->{hour}           }
sub canonical_hour { $_[0]->{canonical_hour} }
sub hour_quarter   { $_[0]->{hour_quarter}   }

my %SetValidate;
foreach my $key (keys %NewValidate) {
    my %hash = %{$NewValidate{$key}};
    delete $hash{default};
    delete $hash{depends};
    $hash{optional} = 1;
    $SetValidate{$key} = \%hash;
}

sub set
{
    my $self = shift;
    my %args = Params::Validate::validate(@_, \%SetValidate);

    if (exists $args{era_name} || exists $args{era_year}) {
        my $era_name = delete $args{era_name} || $self->era_name;
        my $era_year = delete $args{era_year} || $self->era_year;

        @args{ qw(cycle cycle_year) } = _era2cycle($era_name, $era_year);
    }

    my $adjust_time = 0;
    my ($hour, $hour_quarter);
    if (exists $args{hour} or exists $args{hour_quarter}) {
        $hour         = delete $args{hour} || $self->hour;
        $hour_quarter = delete $args{hour_quarter} || $self->hour_quarter;
        $adjust_time = 1;
    }

    $self->SUPER::set(%args);
    $self->_calc_era_components();

    if ($adjust_time) {
        $self->_adjust_time_components($hour, $hour_quarter);
    }
}

1;

__END__

=head1 NAME

DateTime::Calendar::Japanese - DateTime Extension for Traditional Japanese Calendars

=head1 SYNOPSIS

  use DateTime::Calendar::Japanese;

  # Construct a DT::C::Japanese object using the Chinese hexagecimal
  # cycle system
  my $dt = DateTime::Calendar::Japanese->new(
    cycle        => $cycle,
    cycle_year   => $cycle_year,
    month        => $month,
    leap_month   => $leap_month,
    day          => $day,
    hour         => $hour,
    hour_quarter => $hour_quarter
  );

  # Construct a DT::C::Japanese object using the era system
  use DateTime::Calendar::Japanese::Era qw(HEISEI);
  my $dt = DateTime::Calendar::Japanese->new(
    era_name     => HEISEI,
    era_year     => $era_year,
    month        => $month,
    leap_month   => $leap_month,
    day          => $day,
    hour         => $hour,
    hour_quarter => $hour_quarter
  );

  $cycle          = $dt->cycle;
  $cycle_year     = $dt->cycle_year;
  $era            = $dt->era;   # era object
  $era_name       = $dt->era_name;
  $era_year       = $dt->era_year;
  $month          = $dt->month;
  $leap_month     = $dt->leap_month;
  $day            = $dt->day;
  $hour           = $dt->hour;
  $canonical_hour = $dt->canonical_hour
  $hour_quarter   = $dt->hour_quarter;

=head1 DESCRIPTION

This module implements the traditional Japanese Calendar, which was used
from circa 692 A.D. to 1867 A.D. The traditional Japanese Calendar is a
I<lunisolar calendar> based on the Chinese Calendar, and therefore
this module may *not* be used for handling or formatting modern Japanese
calendars which are Gregorian Calendars with a twist.
Please use DateTime::Format::Japanese for that purpose.

On top of the lunisolar calendar, this module implements a simple time
system used in the Edo period, which is a type of temporal hour system, 
based on sunrise and sunset.

=head1 CAVEATS/DISCLAIMERS

=head2 SPEED

This module is based on L<DateTime::Calendar::Chinese>, which in turn is
based on positions of the Moon and the Sun. Calculations of this sort is
definitely not Perl's forte, and therefore this module is *very* slow.

Help is much appreciated to rectify this :)

=head2 CALENDAR "VERSION"

Note that for each of these calendars there exist numerous different
versions/revisions. The Japanese Calendar has at least 6 different
revisions.

The Japanese Calendar that is implemented here uses the algorithm described
in the book "Calendrical Computations" [1], which presumably describes the
latest incarnation of these calendars.

=head2 ERA DISCREPANCIES FROM MODERN JAPANESE DATES

Even though this module can handle modern dates, note that this module
creates dates in the *traditional* calendar, NOT the modern gregorian
calendar used in Japane since the Meiji era. Yet, we must honor the gregorian
date in which an era started or ended. This means that the era year
calculations could be off from what you'd expect on a modern calendar.

For example, the Heisei era starts on 08 Jan 1989 (Gregorian), so in a 
modern calendar you would expect the rest of year 1989 to be Heisei 1.
However, the Chinese New Year happens to fall on 06 Feb 1989. Thus
this module would see that and increment the era year by one on that
date.

If you want to express modern Japanese calendars, you will need to use
L<DateTime::Format::Japanese> module on the vanilla DateTime object. 
(As of this writing DateTime::Format::Japanese is in alpha release. Use
at your own peril)

=head2 TIME COMPONENTS

The time component is based on the little that I already knew about the
traditional Japanese time system and numerous resources available on the net.

As for the Japanese time system, not much detail was available to me.
I searched in various resources on the net and used a combined alogorithm
(see L</REFERENCES>) to produce what seemed logical (and simple enough for
me) to emulate the time system implemented in this module is from the one
used during the Edo period (1600's - 1800's). 

If there are any corrections, please let me know.

Also note that this module Currently assumes that the sunrise/sunset hours
are calculated based on Tokyo latitude/longitude.

=head1 THE TRADITIONAL JAPANESE (EDO) TIME SYSTEM

The time system that is implemented in this module is the time system used
in the Edo era, during the time of the Tokugawa shogunate (1603 - 1867).

This time system is completely unlike the ones we are used in the modern
world, mainly in that the notion of an "hour" changes from season to
season.  The days were divided in to two parts, from sunrise to sunset, and
from sunset to sunrise. Each of these parts were then divided into 6 equal
parts.

This also means that an "hour" has a different length depending on the
season, and it even differs between day and night. However, for those people
with no watches or clocks, it's sometimes more convenient because the
position of the sun directly corelates to the time of the day.

Even more complicated to us is the fact that Japanese hours have a slightly
complex numbering scheume. The hours do not start from 1. Instead, the hour
that starts with the sunrise is hour "6", then "5", "4", and then "9", all
the way back to "6". Each of these hours also have a corresponding name,
which is based on the Chinese Zodiac.

  ------------------
  | Hour | Zodiac  |
  ------------------
  |   6  | Hare    | <-- Sunrise ---
  ------------------               |
  |   5  | Dragon  |               |
  ------------------               |
  |   4  | Snake   |               |
  ------------------               |---- Day
  |   9  | Horse   |               |
  ------------------               |
  |   8  | Sheep   |               |
  ------------------               |
  |   7  | Monkey  |----------------
  ------------------
  |   6  | Fowl    | <-- Sunset ----
  ------------------               |
  |   5  | Dog     |               |
  ------------------               | 
  |   4  | Pig     |               | 
  ------------------               |---- Night
  |   9  | Rat     |               | 
  ------------------               | 
  |   8  | Ox      |               | 
  ------------------               | 
  |   7  | Tiger   |----------------
  ------------------

These names are used standalone or sometimes interchangeably. For example,
"ne no koku" literary means "the hour of hare", but you can also say
"ake mutsu" which means "morning 6".

For computational purposes, DateTime::Calendar::Japanese will number the
hours 1 to 12. (You can get the canonical representation by using the
canonical_hour() method)

Each hour is further broken up in 4 parts, which is combined with the
hour notation to express a more precise time, for example:

  hour of Ox, 3rd quarter (around 3 a.m.)

=head1 METHODS

=head2 new

There are two forms to the constructor. One form accepts "era" and "era_year"
to define the year, and the other accepts "cycle" and "cycle_year". The
rest of the parameters are the same, and they are: "month", "leap_month",
"day", "hour", "hour_quarter".

  use DateTime::Calendar::Japanese;
  use DateTime::Calendar::Japanese::Era qw(TAIKA);
  my $dt = DateTime::Calendar::Japanese->new(
    era          => TAIKA,
    era_year     => 1,
    month        => 7,
    day          => 25,
    hour         => 4,
    hour_quarter => 3
  );

  # DateTime::Calendar::Chinese style
  my $dt = DateTime::Calendar::Japanese->new(
    cycle        => 78,
    cycle_year   => 20,
    month        => 3,
    day          => 4,
    hour         => 4,
    hour_quarter => 3
  );

See the documentation for DateTime::Calendar::Chinese for the semantics
of cycle and cycle_year
 
=head2 now

=head2 from_epoch

=head2 from_object

These constructors are exactly the same as those in DateTime::Calendar::Chinese

=head2 set

Sets DateTime components.

=head2 utc_rd_values

Returns the current UTC Rata Die days, seconds, and nanoseconds as a three
element list. This exists primarily to allow other calendar modules to create
objects based on the values provided by this object.

=head2 cycle

Returns the current cycle. See L<DateTime::Calendar::Chinese>

=head2 cycle_year

Returns the current cycle_year. See L<DateTime::Calendar::Chinese>

=head2 era

Returns the DateTime::Calendar::Japanese::Era object associated with this
calendar.

=head2 era_name

Returns the name (id) of the DateTime::Calendar::Japanese::Era object
associated with this calendar.

=head2 era_year

Returns the number of years in the current era, as calculated by the
traditional lunisolar calendar. Note that calculations will be different
from those based on the modern calendar, as the date of New Year (which is
when era years are incremented) differ from modern calendars. For example,
based on the traditional calendar, SHOUWA3 (1926 - 1989) had only 63 years,
not 64. See L<CAVEATS|/ERA DISCREPANCIES FROM MODERN JAPANESE DATES>

=head2 hour

Returns the hour, based on the traditional Japanese time system. The
hours are encoded from 1 to 12 to uniquely qulaify them. However, you
can get the canonical hour by using the canonical_hour() method

1 is the time of sunrise, somewhere around 5am to 6am, depending on the
time of the year (This means that hour 12 on a given date is actually BEFORE
hour 1)

=head2 canonical_hour

Returns the canonical hour, based on the numbering system described
in L<the above section|/THE TRADITIONAL JAPANESE (EDO) TIME SYSTEM>,
which counts from 9 to 4, and back to 9.

=head2 hour_quarter

Returns the quarter in the current hour (1 to 4).

=head1 AUTHOR

Copyright (c) 2004-2007 Daisuke Maki E<lt>daisuke@endeworks.jp<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=head1 REFERENCES

  [1] Edward M. Reingold, Nachum Dershowitz
      "Calendrical Calculations (Millenium Edition)", 2nd ed.
       Cambridge University Press, Cambridge, UK 2002

  [2] http://homepage2.nifty.com/o-tajima/rekidaso/calendar.htm
  [3] http://www.tanomi.com/shop/items/wa_watch/index2.html
  [4] http://www.geocities.co.jp/Playtown/6757/edojikan01.html
  [5] http://www.valley.ne.jp/~ariakehs/Wadokei/hours_system.html

=head1 SEE ALSO

L<DateTime>
L<DateTime::Set>
L<DateTime::Span>
L<DateTime::Calendar::Chinese>
L<DateTime::Calendar::Japanese::Era>
L<DateTime::Event::Sunrise>

=cut
