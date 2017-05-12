package DateTime::Calendar::Chinese;
use 5.008;
use strict;
use utf8;
use vars qw($VERSION);
BEGIN {
    $VERSION = '1.00';
}

use DateTime;
use DateTime::Astro qw(MEAN_TROPICAL_YEAR MEAN_SYNODIC_MONTH moment dt_from_moment new_moon_after new_moon_before
    solar_longitude_from_moment
);
use DateTime::Event::Chinese qw(chinese_new_year_before);
use DateTime::Event::SolarTerm qw(prev_term_at no_major_term_on);
use Params::Validate;
use Math::Round qw(round);
use constant GREGORIAN_CHINESE_EPOCH => DateTime->new(
    year => -2636, month => 2, day => 15, time_zone => 'UTC');
use constant GREGORIAN_CHINESE_EPOCH_MOMENT => moment(GREGORIAN_CHINESE_EPOCH);
use constant DEBUG => $ENV{PERL_DATETIME_CALENDAR_CHINESE_DEBUG};

my %BasicValidate = (
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
    hour   => {
        type => Params::Validate::SCALAR(), default => 0,
        callbacks => {
            'is between 0 and 23' => sub { $_[0] >= 0 && $_[0] <= 23 },
        },
    },
    minute => {
        type => Params::Validate::SCALAR(), default => 0,
        callbacks => {
            'is between 0 and 59' => sub { $_[0] >= 0 && $_[0] <= 59 },
        },
    },
    second => {
        type => Params::Validate::SCALAR(), default => 0,
        callbacks => {
            'is between 0 and 61' => sub { $_[0] >= 0 && $_[0] <= 61 },
        },
    },
    nanosecond => {
        type => Params::Validate::SCALAR(), default => 0,
        callbacks => {
            'cannot be negative' => sub { $_[0] >= 0 },
        }
    },
    locale    => { type => Params::Validate::SCALAR() | Params::Validate::OBJECT(), optional => 1 },
    language  => { type => Params::Validate::SCALAR() | Params::Validate::OBJECT(), optional => 1 },
);

my %NewValidate = (
    %BasicValidate,
    time_zone  => { type => Params::Validate::SCALAR() | Params::Validate::OBJECT(), default => 'Asia/Shanghai' },
);
sub new
{
    my $class = shift;
    my %args  = Params::Validate::validate(@_, \%NewValidate);

    # XXX - currently _calc_gregorian_components() calculates the
    # date component only, then we set the time
    my %hash;
    $hash{cycle}      = delete $args{cycle};
    $hash{cycle_year} = delete $args{cycle_year};
    $hash{month}      = delete $args{month};
    $hash{leap_month} = delete $args{leap_month};
    $hash{day}        = delete $args{day};

    my $self  = bless \%hash, $class;
    $self->_calc_gregorian_components(time_zone => delete $args{time_zone});
    $self->{gregorian}->set(%args);

    $self;
}

# XXX - these values are proxied directly to the underlying DateTime
# (Gregorian) object.
sub utc_rd_values { $_[0]->{gregorian}->utc_rd_values }
sub hour          { $_[0]->{gregorian}->hour }
sub minute        { $_[0]->{gregorian}->minute }
sub second        { $_[0]->{gregorian}->second }
sub nanosecond    { $_[0]->{gregorian}->nanosecond }
sub day_of_week   { $_[0]->{gregorian}->day_of_week }
sub time_zone     { $_[0]->{gregorian}->time_zone }
sub set_time_zone { shift->{gregorian}->set_time_zone(@_) }

# XXX - accessors for DT::C::C specific fields
sub cycle      { $_[0]->{cycle} }
sub cycle_year { $_[0]->{cycle_year} }
sub month      { $_[0]->{month} }
sub leap_month { $_[0]->{leap_month} }
sub day        { $_[0]->{day} }

my @celestial_stems =
    ( "ç²",
      "ä¹",
      "ä¸",
      "ä¸",
      "æ",
      "å·±",
      "åº",
      "è¾",
      "å£¬",
      "ç¸",
    );

my @celestial_stems_py =
    qw( jia3
        yi3
        bing3
        ding1
        wu4
        ji3
        geng1
        xin1
        ren2
        gui3
      );

my @terrestrial_branches =
    ( "å­",
      "ä¸",
      "å¯",
      "å¯",
      "è¾°",
      "å·³",
      "å",
      "æª",
      "ç³",
      "é",
      "æ",
      "äº¥",
    );

my @terrestrial_branches_py =
    qw( zi
        chou3
        yin2
        mao3
        chen2
        si4
        wu3
        wei4
        shen1
        you3
        xu1
        hai4
      );

my @zodiac_animals =
    qw( rat
        ox
        tiger
        hare
        dragon
        snake
        horse
        sheep
        monkey
        fowl
        dog
        pig
      );

sub celestial_stem     { $celestial_stems[ ( $_[0]->cycle_year % 10 || 10) - 1 ] }
sub terrestrial_branch { $terrestrial_branches[ ( $_[0]->cycle_year % 12 || 12 ) - 1 ] }
sub year_name          { $_[0]->celestial_stem . $_[0]->terrestrial_branch }

sub celestial_stem_py     { $celestial_stems_py[ ( $_[0]->cycle_year % 10 || 10 ) - 1 ] }
sub terrestrial_branch_py { $terrestrial_branches_py[ ( $_[0]->cycle_year % 12 || 12 ) - 1 ] }
sub year_name_py          { $_[0]->celestial_stem_py . $_[0]->terrestrial_branch_py }

sub zodiac_animal         { $zodiac_animals[ ( $_[0]->cycle_year % 12 || 12 ) - 1 ] }

my %SetValidate;
foreach my $key (keys %BasicValidate) {
    my %hash = %{$BasicValidate{$key}};
    delete $hash{default};
    $hash{optional} = 1;
    $SetValidate{$key} = \%hash;
}

sub set
{
    my $self = shift;
    my %args  = Params::Validate::validate(@_, \%SetValidate);

#print STDERR 
#    "BEFORE SET ",
#    "grgorian: ", $self->{gregorian}->datetime,
#    " RD: ", ($self->{gregorian}->utc_rd_values)[0],
#    " time_zone: ", $self->{gregorian}->time_zone_short_name, "\n";
    foreach my $ch_component (qw(cycle cycle_year month leap_month day)) {
        if (exists $args{$ch_component}) {
            $self->{$ch_component} = delete $args{$ch_component};
        }
    }
        
    my $clone = $self->{gregorian}->clone;

    $self->_calc_gregorian_components(time_zone =>
        $args{time_zone} || $clone->time_zone || 'UTC');

    # get "defaults" from the cloned dt object. we will only use these
    # values if the field wasn't specified in the argument to set()
    foreach my $dt_component (qw(hour minute second locale)) {
        if (! exists $args{$dt_component}) {
            $args{$dt_component} = $clone->$dt_component;
        }
    }
    $self->{gregorian}->set(%args);

#print STDERR 
#    "AFTER SET ",
#    "grgorian: ", $self->{gregorian}->datetime,
#    " RD: ", ($self->{gregorian}->utc_rd_values)[0],
#    " time_zone: ", $self->{gregorian}->time_zone_short_name, "\n";

    $self;
}

sub from_epoch
{
    my $class = shift;
    my $self  = bless {}, $class;
    my $dt    = DateTime->from_epoch(@_);
    $self->{gregorian} = $dt;
    $self->_calc_local_components();
    return $self;
    
}
sub now { shift->from_epoch(@_, epoch => time()) }

sub from_object
{
    my $class = shift;
    my $self  = bless {}, $class;
    my $dt    = DateTime->from_object(@_);

    $self->{gregorian} = $dt;
    $self->_calc_local_components();
    return $self;
}

sub _calc_gregorian_components
{
    my $self = shift;

    my $mid_year = POSIX::floor(
        GREGORIAN_CHINESE_EPOCH_MOMENT + 
        (($self->cycle() - 1) * 60 + $self->cycle_year() - 1 + 0.5) *
        MEAN_TROPICAL_YEAR);
    my $new_year = chinese_new_year_before(dt_from_moment($mid_year) );

    # XXX - I don't know why I need to do $self->month() - 2 here
    my $p_dt = $new_year + DateTime::Duration->new(days => ($self->month() - 2) * 29);
    my $p = new_moon_after( $p_dt );
    my $d = DateTime::Calendar::Chinese->from_object(object => $p);

    my $prior_new_moon;
    if ($d->month == $self->month && $d->leap_month == $self->leap_month) {
        $prior_new_moon = $p;
    } else {
        $prior_new_moon = new_moon_after( $p + DateTime::Duration->new(days => 1) );
    }

    my $tmp = $prior_new_moon + DateTime::Duration->new(days => $self->day - 1);
    my %args = @_;
    my %new_args = ();
    foreach my $component (qw(
        year month day hour minute second nanosecond locale)) {

        $new_args{$component} = $tmp->$component;
    }
    if ($args{time_zone}) {
        $new_args{time_zone} = $args{time_zone};
    } else {
        $new_args{time_zone} = $tmp->time_zone;
    }

    $self->{gregorian} = DateTime->new(%new_args);

#print STDERR 
#    ">>>>>>>\n",
#    "   cycle: ", $self->cycle, "\n",
#    "  c_year: ", $self->cycle_year, "\n",
#    "mid_year: ", dt_from_moment($mid_year)->datetime, "\n",
#    "new_year: ", $new_year->datetime, "\n",
#    "       p: ", $p->datetime, "\n",
#    "    p_dt: ", $p_dt->datetime, "\n",
#    "prior_nm: ", $prior_new_moon->datetime, "\n",
#    "    self: cycle: ", $self->cycle, " cycle_year: ", $self->cycle_year,
#        " month: ", $self->month, " leap_month: ", $self->leap_month,
#        " day: ", $self->day, "\n",
#    "       d: cycle: ", $d->cycle, " cycle_year: ", $d->cycle_year,
#        " month: ", $d->month, " leap_month: ", $d->leap_month,
#        " day: ", $d->day, "\n";
#    "grgorian: ", $self->{gregorian}->datetime, "\n",
#    "<<<<<<<\n";

}

sub _calc_local_components
{
    my $self = shift;
    my $dt   = $self->{gregorian}->clone->truncate(to => 'day');

    # XXX TODO: Change these calculations to use moment, not DateTime

    # last winter solstice
    my $s1 = prev_term_at( $dt, 270 );
    # next winter solstice
    my $s2 = prev_term_at( $s1 + DateTime::Duration->new(days => 370), 270 );

    # new moon after the last winter solstice (12th month in the last sui)
    my $m12 = new_moon_after($s1 + DateTime::Duration->new(days => 1) );

    # new moon before the next winter solstice (11th month in the current sui)
    my $next_m11 = new_moon_before($s2 + DateTime::Duration->new(days => 1));

    # new moon before now.
    my $m = new_moon_before($dt + DateTime::Duration->new(days => 1));

    # pre-compute and save a call to moment()
    my $m12_moment = moment($m12);
    my $m_moment   = moment($m);
    my $m11_moment = moment($next_m11);


    # if there are 12 lunar months (29.5 days) between the last 12th month
    # and the next 11th month, then there must be a leap month some where
    my $leap_year =
        round(($m11_moment - $m12_moment) / MEAN_SYNODIC_MONTH) == 12;

    # XXX - hey, there are a lot of paranthesis, but it's required or
    # else you get into some real unhappy problems
    my $month;
    {
        my $x = round(($m_moment - $m12_moment) / MEAN_SYNODIC_MONTH);
        if ($leap_year && $self->_prior_leap_month($m12, $m)) {
            if (DEBUG) {
                print STDERR ">>>> leap_year && prior_leap_mont $m12 : $m\n";
            }
            $x--;
        }
        $month = $x % 12 || 12;
    }

    # XXX - tricky... we need to set month before calling elapsed_years,
    # because it will be used by that function
    $self->{month}    = $month;
    my $elapsed_years = $self->elapsed_years;

    $self->{cycle}      = POSIX::floor( ($elapsed_years - 1) / 60) + 1;
    $self->{cycle_year} = $elapsed_years % 60 || 60;
    $self->{day}        = POSIX::ceil(moment($dt) - $m_moment + 1);

    if ($leap_year && no_major_term_on($m)) {
        my $end = new_moon_before($m - DateTime::Duration->new(days => 1));
        $self->{leap_month} = ! $self->_prior_leap_month($m12, $end);
    } else {
        $self->{leap_month} = 0;
    }

    if (DEBUG) {
        print STDERR 
            ">>>>>>\n",
            "        dt: ", $dt->datetime, "\n",
            "        s1: ", $s1->datetime, "\n",
            "        s2: ", $s2->datetime, "\n",
            "       m12: ", $m12->datetime, "\n",
            "     n_m11: ", $next_m11->datetime, "\n",
            "     11-12: ", round( (moment($next_m11) - $m12_moment) / MEAN_SYNODIC_MONTH), "\n",
            "         m: ", $m->datetime, "\n",
            " leap year: ", $leap_year ? "yes" : "no", "\n",
            "leap month: ", $self->{leap_month} ? "yes" : "no", "\n",
            "     m-m12: ", round(abs($m_moment - $m12_moment) / MEAN_SYNODIC_MONTH), "\n",
            "      sl_m: ", solar_longitude_from_moment($m_moment), "\n",
            "    sl_m12: ", solar_longitude_from_moment($m12_moment), "\n",

#            "pleap: ", $self->_prior_leap_month($m12, $m) ? "yes" : "no", "\n",
            "     month: ", $month, "\n",
            "   elapsed: ", $elapsed_years, "\n",
            "     cycle: ", $self->{cycle}, "\n",
            "cycle_year: ", $self->{cycle_year}, "\n",
            "<<<<<<\n";
    }

}

sub elapsed_years
{
    my $self = shift;
    if (DEBUG) {
        print  STDERR
            ">>>> elapsed_years\n",
            "moment: ", moment($self->{gregorian}), "\n",
            "epoch:  ", GREGORIAN_CHINESE_EPOCH_MOMENT, "\n",
            "month:  ", $self->month, "\n",
            "<<<<\n"
    }
    return POSIX::floor(
        1.5 - $self->month / 12 + (moment($self->{gregorian}) - GREGORIAN_CHINESE_EPOCH_MOMENT) / MEAN_TROPICAL_YEAR);
}

# [1] p.250
sub _prior_leap_month
{
    my($class, $start, $end) = @_;

    if (DEBUG) {
        print STDERR 
            ">>>> prior_leap_month\n",
            "caller: ", join(':', (caller)[1, 2]), "\n", 
            "start: ", $start, "\n",
            "end:   ", $end, "\n",
            "<<<<\n";
    }

    while ($start <= $end) {
        if (no_major_term_on($end)) {
            if (DEBUG) {
                print STDERR " + prior_leap_month: there are no major terms on $end\n";
            }
            return 1;
        }

        $end = new_moon_before($end - DateTime::Duration->new(minutes => 30));
    }
    if (DEBUG) {
        print " + prior_leap_month: nothing found, returning false\n";
    }

    return ();
}

1;
__END__

=head1 NAME

DateTime::Calendar::Chinese - Traditional Chinese Calendar Implementation

=head1 SYNOPSIS

  use DateTime::Calendar::Chinese;

  my $dt = DateTime::Calendar::Chinese->now();
  my $dt = DateTime::Calendar::Chinese->new(
    cycle      => $cycle,
    cycle_year => $cycle_year,
    month      => $month,
    leap_month => $leap_month,
    day        => $day,
  );

  $dt->cycle;
  $dt->cycle_year; # 1 - 60
  $dt->month;      # 1-12
  $dt->leap_month; # true/false
  $dt->day;        # 1-30 
  $dt->elapsed_years; # years since "Chinese Epoch"

  my ($rd_days, $rd_secs, $rd_nanosecs) = $dt->utc_rd_values();

=head1 DESCRIPTION

This is an implementation of the Chinese calendar as described in 
"Calendrical Calculations" [1]. Please note that the following description
is the description from [1], and the author has not made attempts to verify
the correctness of statements with other sources.

The Chinese calendar described in [1] is expressed in terms of "cycle",
"cycle_year", "month", "a boolean leap_month", and "day".

Traditional Chinese years have been counted using the "Sexagecimal Cycle
of Names", which is a cycle of 60 names for each year. The names are
the combination of a "celestial stem" (tian1 gan1), with a "terrestrial branch"
(di4 zhi1):

    Celestial Stems         Terrestrial Branches
  -------------------     -----------------------
  | Jia3            |     | Zi (Rat)            |
  -------------------     -----------------------
  | Yi3             |     | Chou3 (Ox)          |
  -------------------     -----------------------
  | Bing3           |     | Yin2 (Tiger)        |
  -------------------     -----------------------
  | Ding1           |     | Mao3 (Hare)         |
  -------------------     -----------------------
  | Wu4             |     | Chen2 (Dragon)      |
  -------------------     -----------------------
  | Ji3             |     | Si4 (Snake)         |
  -------------------     -----------------------
  | Geng1           |     | Wu3 (Horse)         |
  -------------------     -----------------------
  | Xin1            |     | Wei4 (Sheep)        |
  -------------------     -----------------------
  | Ren2            |     | Shen1 (Monkey)      |
  -------------------     -----------------------
  | Gui3            |     | You3 (Fowl)         |
  -------------------     -----------------------
                          | Xu1 (Dog)           |
                          -----------------------
                          | Hai4 (Pig)          |
                          -----------------------

Names are assigned by running each list sequentially, so the first
year woud be jia1zi, then yi3chou3, bing1yin2, and so on.  The numbers
after each syllable indicates the tone used for the syllable.

The animal names of the Chinese "Zodiac" are I<not> translations of
the terrestrial branches, which have different meanings.  For example,
the first branch, "zi", can mean "child" or "son", as well as several
other things.

Chinese months are true lunar months, which starts on a new moon and runs
until the day before the next new moon. Therefore each month consists of
exactly 29 or 30 days. The month numbers are calculated based on a logic
that combines lunar months and solar terms (which is too hard to explain
here -- read "Calendrical Calculation" if you must know), and may include
leap months.

Leap months can be inserted anywhere in the year, so months are numbered
from 1 to 12, with the boolean flag "leap_month" that indicates if the
month is a leap month or not.

=head1 METHODS

=head2 new

This class method accepts parameters for each date and time component: "cycle",
"cycle_year", "month", "leap_month", "day", "hour", "minute", "second",
"nanosecond". It also accepts "locale" and "time_zone" parameters.

Note that in order to avoid confusion between the official Chinese Calendar
which is based on Chinese time zone, the default value for time_zone is
*not* "floating", but is instead "Asia/Shanghai". See L<CAVEATS|/CAVEATS>.

  XXX The time zone settings may change in a few ture version such
  XXX that the calculation is done in Asia/Shanghai, but the
  XXX resulting object is set to "floating" time zone.

Note that currently there's no way to verify if a given date is "correct" --
i.e. if you give a date as a leap_month when it in fact isn't a leap month,
all sorts of wacky things will happen. Perhaps there's a simple way to do
this. If there is, please let me know

=head2 now

This class method is equivalent to calling from_epoch() with the value
returned from Perl's time() function. 

=head2 from_object(object => ...)

This class method can be used to construct a new DateTime::Calendar::Chinese
object from any object that implements the utc_rd_values() method. 

=head2 from_epoch(epoch => ...)

This class method can be used to construct a new DateTime::Calendar::Chinese
object from an epoch time instead of components.  

=head2 set(...)

This method is identical to that of DateTime, except the date components
that can be set are restricted to the Chinese ones ("cycle", "cycle_year",
"month", "leap_month", "day"). The time components are the same as 
that of DateTime (See L<CAVEATS|/CAVEATS>).

=head2 set_time_zone

Sets the time zone. This method is identical to that of DateTime.

=head2 time_zone

Gets the time zone. This method is identical to that of DateTime.

=head2 utc_rd_values()

Returns the current UTC Rata Die days, seconds, and nanoseconds as a three
element list. This method is identical to that of L<DateTime>.

=head2 cycle

Returns the current cycle of the sexagecimal names since the Chinese epoch
(defined to be 25 Feb, -2636 gregorian).

=head2 cycle_year

Returns the current year in the current cycle. 

=head2 month

Returns the current lunar month.

=head2 leap_month

Returns true if the current month is a leap month.

=head2 day

Returns the current day in the lunar month.

=head2 elapsed_year

This returns the number of years elapsed since the Chinese Epoch as defined
by [1] (Which is 15 Feb. -2646 gregorian). Some documents use different
epoch dates, and hence this may not match with whatever source you have. 

=head2 year_name

Returns the name of the year (the celestial stem and the terrestrial
branch) as UTF8 (or a sequence of bytes in Perl 5.00503).

=head2 celestial_stem

Returns the celestial stem as UTF8 (or a sequence of bytes in Perl
5.00503).

=head2 terrestrial_branch

Returns the terrestrial branch as UTF8 (or a sequence of bytes in Perl
5.00503).

=head2 year_name_py

=head2 celestial_stem_py

=head2 terrestrial_branch_py

These methods return the various names in Pinyin, with the tones given
as numbers at the end of each syllable.  The first terrestrial branch
is generally pronounced without a tone, and is returned as "zi".

=head2 zodiac_animal

Returns the year's Zodiac animal.

=head2 day_of_week

=head2 elapsed_years

=head2 hour

=head2 minute

=head2 second

=head2 nanosecond

=head1 CAVEATS

=head2 TIMEZONES

Be careful with time zones! The "official" Chinese Calendar is based on
date/time in China, not your local time zone nor "floating" time zone.
This is because the Chinese Calendar is based on astronomical events,
but dates such as Chinese New Year are calculated in Chinese time and
then transferred over to wherever you're at.

For example, the Chinese New Year in 2004 is Jan 22, but that is Jan 22
in China time. The same time is Jan 21 UTC, and now you'd be off by one day.

So when you're calculating Chinese Calendars, always set the time zone to
something like 'Asia/Hong_Kong', 'Asia/Shanghai', 'Asia/Taipei'

=head2 TIME

Because "Calendrical Calculations" did not go much in detail about the
Chinese time system, this module simply uses the time components from the
underlying DateTime module (XXX - Note: we may implement this later, so
be careful not to use the time components too much for now)

=head2 PERFORMANCE

Yes, this module is slow, because the underlying calculations are slow.
If you can contribute to the speed, please let me know. So far I've
concentrated on porting the algorithms from [1] straight over, and not
on performance. I'm sure there's a lot that could be done.

=head1 AUTHOR

(c) Copyright 2004-2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=head1 REFERENCES

  [1] Edward M. Reingold, Nachum Dershowitz
      "Calendrical Calculations (Millenium Edition)", 2nd ed.
       Cambridge University Press, Cambridge, UK 2002

=head1 SEE ALSO

L<DateTime>
L<DateTime::Event::Chinese>

=cut

