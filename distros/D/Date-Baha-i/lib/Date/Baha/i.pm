package Date::Baha::i;
BEGIN {
  $Date::Baha::i::AUTHORITY = 'cpan:GENE';
}

# ABSTRACT: Convert to and from Baha'i dates

our $VERSION = '0.1903';


use strict;
use warnings;

use parent 'Exporter';
use vars qw(@EXPORT @EXPORT_OK);
@EXPORT = @EXPORT_OK = qw(
    as_string
    cycles
    days
    days_of_the_week
    from_bahai
    holy_days
    months
    next_holy_day
    to_bahai
    years
);

use Date::Calc qw(
    Add_Delta_Days
    Date_to_Days
    Day_of_Week
    leap_year
);
use Lingua::EN::Numbers qw(num2en_ordinal);
use Lingua::EN::Numbers::Years;

# Set constants
use constant FACTOR         =>   19;  # Groups of 19
use constant FEBRUARY       =>    2;  # Handy
use constant MARCH          =>    3;  # Handy
use constant SHARAF         =>   16;  # Handy
use constant LAST_START_DAY =>    2;  # 1st day of fast
use constant YEAR_START_DAY =>   21;  # Vernal equinox
use constant LEAP_START_DAY =>   26;  # Intercalary days
use constant FIRST_YEAR     => 1844;  # History!
use constant ADJUST_YEAR    => 1900;  # Year factor


use constant CYCLE_YEAR => qw(
    Alif
    Ba
    Ab
    Dal
    Bab
    Vav
    Abad
    Jad
    Baha
    Hubb
    Bahhaj
    Javab
    Ahad
    Vahhab
    Vidad
    Badi
    Bahi
    Abha
    Vahid
);
use constant MONTH_DAY => qw(
    Baha
    Jalal
    Jamal
    'Azamat
    Nur
    Rahmat
    Kalimat
    Kamal
    Asma'
    'Izzat
    Mashiyyat
    'Ilm
    Qudrat
    Qawl
    Masa'il
    Sharaf
    Sultan
    Mulk
    'Ala
    Ayyam-i-Ha
);


# We quote floats to avoid mis-computation.
# Month => [Number, Start, End] # TODO ?, ?
use constant MONTHS => {
    "Baha"       => [ 0,  '3.21',  '4.08'],  # 80,  98
    "Jalal"      => [ 1,  '4.09',  '4.27'],  # 99, 117
    "Jamal"      => [ 2,  '4.28',  '5.16'],  #118, 136
    "'Azamat"    => [ 3,  '5.17',  '6.04'],  #137, 155
    "Nur"        => [ 4,  '6.05',  '6.23'],  #156, 174
    "Rahmat"     => [ 5,  '6.24',  '7.12'],  #175, 193
    "Kalimat"    => [ 6,  '7.13',  '7.31'],  #194, 212
    "Kamal"      => [ 7,  '8.01',  '8.19'],  #213, 231
    "Asma'"      => [ 8,  '8.20',  '9.07'],  #232, 250
    "'Izzat"     => [ 9,  '9.08',  '9.26'],  #251, 269
    "Mashiyyat"  => [10,  '9.27', '10.15'],  #270, 288
    "'Ilm"       => [11, '10.16', '11.03'],  #289, 307
    "Qudrat"     => [12, '11.04', '11.22'],  #308, 326
    "Qawl"       => [13, '11.23', '12.11'],  #327, 345
    "Masa'il"    => [14, '12.12', '12.30'],  #346, 364
    "Sharaf"     => [15, '12.31',  '1.18'],  #365,  18
    "Sultan"     => [16,  '1.19',  '2.06'],  # 19,  37
    "Mulk"       => [17,  '2.07',  '2.25'],  # 38,  56
    "Ayyam-i-Ha" => [-1,  '2.26',  '3.01'],  # 57,  60
    "'Ala"       => [18,  '3.02',  '3.20'],  # 61,  79
};


use constant DOW_NAME => qw(
    Jalal
    Jamal
    Kaml
    Fidal
    'Idal
    Istijlal
    Istiqlal
);


use constant HOLY_DAYS => {
    # Work suspended':
    "Naw Ruz"                   => [  '3.21' ],
    "First Day of Ridvan"       => [  '4.21' ],
    "Ninth Day of Ridvan"       => [  '4.29' ],
    "Twelfth Day of Ridvan"     => [  '5.02' ],
    "Declaration of the Bab"    => [  '5.23' ],
    "Ascension of Baha'u'llah"  => [  '5.29' ],
    "Martyrdom of the Bab"      => [  '7.09' ],
    "Birth of the Bab"          => [ '10.20' ],
    "Birth of Baha'u'llah"      => [ '11.12' ],
    # Work not suspended:
    "Ayyam-i-Ha"                => [  '2.26',  4 ],  # 5 days are calculated in leap years
    "The Fast"                  => [  '3.02', 19 ],
    "Days of Ridvan"            => [  '4.21', 12 ],
    "Day of the Covenant"       => [ '11.26' ],
    "Ascension of 'Abdu'l-Baha" => [ '11.28' ],
};

# List return functions
sub cycles           { return CYCLE_YEAR }
sub years            { return CYCLE_YEAR }
sub months           { return MONTH_DAY }
sub days             { return (MONTH_DAY)[0 .. 18] }
sub days_of_the_week { return DOW_NAME }
sub holy_days        { return HOLY_DAYS }

sub to_bahai {
    my %args = @_;

    # Grab the ymd from the arguments if they have been passed in.
    my ($year, $month, $day) = @args{qw(year month day)};
    # Make sure we have a proper ymd before proceeding.
    ($year, $month, $day) = _ymd(
        %args,
        year  => $year,
        month => $month,
        day   => $day,
    );

    my ($bahai_month, $bahai_day);

    for (values %{ MONTHS() }) {
        my ($days, $lower, $upper) = _setup_date_comparison(
            $year, $month, $day, @$_[1,2]
        );

        if ($days >= $lower && $days <= $upper) {
            $bahai_month = $_->[0];
            $bahai_day = $days - $lower;
            last;
        }
    }

    # Build the date hash to return.
    return _build_date(
        $year, $month, $day, $bahai_month, $bahai_day,
        %args
    );
}

sub from_bahai {
    my %args = @_;

    # Figure out the year.
    my $year = $args{year} + FIRST_YEAR;
    $year-- unless $args{month} > SHARAF || $args{month} == -1;

    # Reset the month number if we are given Ayyam-i-Ha.
    $args{month} = 0 if $args{month} == -1;

    # This ugliness actually finds the month and day number.
    my $day = (MONTHS->{ (MONTH_DAY)[$args{month} - 1] })->[1];
    (my $month, $day) = split /\./, $day;
    ($year, $month, $day) = Add_Delta_Days(
        $year, $month, $day, $args{day} - 1
    );

    return wantarray
        ? ($year, $month, $day)
        : join '/', $year, $month, $day;
}

sub as_string {
    # XXX With Lingua::EN::Numbers, naively assume that we only care about English.
    my ($date_hash, %args) = @_;

    $args{size}     = 1 unless defined $args{size};
    $args{numeric}  = 0 unless defined $args{numeric};
    $args{alpha}    = 1 unless defined $args{alpha};

    my $date;

    my $is_ayyam_i_ha = $date_hash->{month} == -1 ? 1 : 0;

    if (!$args{size} && $args{numeric} && $args{alpha}) {
        # short alpha-numeric
        $date .= sprintf '%s (%d), %s (%d) of %s (%d), year %d, %s (%d) of %s (%d)',
            @$date_hash{qw(
                dow_name dow day_name day month_name month
                year year_name cycle_year cycle_name cycle
            )};
    }
    elsif ($args{size} && $args{numeric} && $args{alpha}) {
        # long alpha-numeric
        # XXX Fugly hacking begins.
        my $month_string = $is_ayyam_i_ha ? '%s%s' : 'the %s month %s';
        my $n = year2en($date_hash->{year});

        $date .= sprintf
            "%s week day %s, %s day %s of $month_string, year %s (%d), %s year %s of the %s vahid %s of the %s kull-i-shay",
            num2en_ordinal($date_hash->{dow}),
            $date_hash->{dow_name},
            num2en_ordinal($date_hash->{day}),
            $date_hash->{day_name},
            ($is_ayyam_i_ha ? '' : num2en_ordinal($date_hash->{month})),
            $date_hash->{month_name},
            $n,
            $date_hash->{year},
            num2en_ordinal($date_hash->{cycle_year}),
            $date_hash->{year_name},
            num2en_ordinal($date_hash->{cycle}),
            $date_hash->{cycle_name},
            num2en_ordinal($date_hash->{kull_i_shay});
    }
    elsif (!$args{size} && $args{numeric}) {
        # short numeric
        $date .= sprintf '%s/%s/%s', @$date_hash{qw(month day year)};
    }
    elsif ($args{size} && $args{numeric}) {
        # long numeric
        $date .= sprintf
            '%s day of the week, %s day of the %s month, year %s, %s year of the %s vahid of the %s kull-i-shay',
            num2en_ordinal($date_hash->{dow}),
            num2en_ordinal($date_hash->{day}),
            num2en_ordinal($date_hash->{month}),
            $date_hash->{year},
            num2en_ordinal($date_hash->{cycle_year}),
            num2en_ordinal($date_hash->{cycle}),
            num2en_ordinal($date_hash->{kull_i_shay});
    }
    elsif (!$args{size} && $args{alpha}) {
        # short alpha
        $date .= sprintf '%s, %s of %s, %s of %s',
            @$date_hash{qw(
                dow_name day_name month_name year_name cycle_name
            )};
    }
    else {
        # long alpha
        my $month_string = $is_ayyam_i_ha ? '%s' : 'month %s';
        my $n = year2en($date_hash->{year});

        $date .= sprintf
            "week day %s, day %s of $month_string, year %s, %s of the vahid %s of the %s kull-i-shay",
            @$date_hash{qw(dow_name day_name month_name)},
            $n,
            @$date_hash{qw(year_name cycle_name)},
            num2en_ordinal($date_hash->{kull_i_shay});
    }

    if ($date_hash->{holy_day} && $args{size}) {
        $date .= ', holy day: ' . join '', keys %{ $date_hash->{holy_day} };
    }

    return $date;
}

sub next_holy_day {
    my ($year, $month, $day) = @_;

    # Use today if we are not provided with a date.
    ($year, $month, $day) = _ymd(
        year  => $year,
        month => $month,
        day   => $day,
    );

    # Construct our lists of pseudo real number dates.
    my %inverted = _invert_holy_days($year);
    my @sorted = sort { $a <=> $b } keys %inverted;

    # Make the month and day a pseudo real number.
    my $m_d = "$month.$day";
    my $holy_date;

    # Find the first date greater than the one provided.
    for (@sorted) {
        if ($m_d < $_) {
            $holy_date = $_;
            last;
        }
    }

    # If one was not found, grab the last date in the list.
    $holy_date = $sorted[-1] unless $holy_date;

    # Make this look like a date again.
    (my $date = $holy_date) =~ s/\./\//;

    return wantarray
        ? ($inverted{$holy_date}, $date)
        : "$inverted{$holy_date} $date";
}

# Helper functions
# Date comparison gymnastics.
sub _setup_date_comparison {
    my ($y, $m, $d, $s, $e) = @_;

    # Dates are encoded as decimals.
    my ($start_month, $start_day) = split /\./, $s;
    my ($end_month, $end_day) = split /\./, $e;

    # Slide either the start or end year, given the month we're
    # looking at.
    my ($start_year, $end_year) = ($y, $y);
    if ($end_month < $start_month) {
        if ($m == $start_month) {
            $end_year++;
        }
        elsif ($m == $end_month) {
            $start_year--;
        }
    }

    return
        Date_to_Days($y, $m, $d),
        Date_to_Days($start_year, $start_month, $start_day),
        Date_to_Days($end_year, $end_month, $end_day);
}

sub _build_date {
    my ($year, $month, $day, $new_month, $new_day, %args) = @_;

    my %date;
    @date{qw(month day)} = ($new_month, $new_day);

    # Set the day of the week (rotated by 2).
    $date{dow} = Day_of_Week($year, $month, $day);
    $date{dow} += 2;
    $date{dow} = $date{dow} - 7 if $date{dow} > 7;
    $date{dow_name} = (DOW_NAME)[$date{dow} - 1];

    # Set the day.
    $date{day_name} = (MONTH_DAY)[$date{day}];
    $date{day}++;

    # Set the the month.
    $date{month_name} = (MONTH_DAY)[$date{month}];
    # Fix the month number, unless we are in Ayyam-i-Ha.
    $date{month}++ unless $date{month} == -1;

    # Set the year.
    # Algorithm lifted from Danesh's "bahaidate".
    $date{year} = ($month < MARCH) ||
        ($month == MARCH && $day < YEAR_START_DAY)
        ? $year - FIRST_YEAR
        : $year - (FIRST_YEAR - 1);

    $date{year_name} = (CYCLE_YEAR)[($date{year} - 1) % FACTOR];
    $date{cycle_year} = $date{year} % FACTOR;

    # Set the cycle.
    $date{cycle} = int($date{year} / FACTOR) + 1;
    $date{cycle_name} = (CYCLE_YEAR)[($date{cycle} - 1) % FACTOR];

    # Set the Kull-i-Shay.
    $date{kull_i_shay} = int($date{cycle} / FACTOR) + 1;

#    $date{timezone} = tz_local_offset();

    # Get the holy day.
    my %inverted = _invert_holy_days($year);
    my $m_d = sprintf '%d.%d', $month, $day;
    $date{holy_day} = $inverted{$m_d} if exists $inverted{$m_d};

    return wantarray ? %date : as_string(\%date, %args);
}

sub _invert_holy_days {
    my $year = shift || (localtime)[5] + ADJUST_YEAR;

    my %inverted;

    while (my ($name, $date) = each %{ HOLY_DAYS() }) {
        $inverted{$date->[0]} = $name;

        # Does this date contain a day span?
        if (@$date > 1) {
            # Increment the Ayyam-i-Ha day if we are in a leap year.
            $date->[1]++ if $name eq 'Ayyam-i-Ha' && leap_year($year);

            for (1 .. $date->[1] - 1) {
                (undef, my $month, my $day) = Add_Delta_Days(
                    $year, split(/\./, $date->[0]), $_
                );

                # Pre-pad the day number with a zero.
                $inverted{ sprintf '%d.%d', $month, $day } = $name;
            }
        }
    }

    return %inverted;
}

# Return a ymd date array but try to honor the epoch and use_gmtime settings.
sub _ymd {
    my %args = @_;

    # Use the system time, if a ymd is not provided.
    unless($args{year} && $args{month} && $args{day}) {
        $args{epoch} ||= time;
        ($args{year}, $args{month}, $args{day}) = $args{use_gmtime}
            ? (gmtime $args{epoch})[5,4,3]
            : (localtime $args{epoch})[5,4,3];
        # Fix the year and the month.
        $args{year} += ADJUST_YEAR;
        $args{month}++;
    }

    return $args{year}, $args{month}, $args{day};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Date::Baha::i - Convert to and from Baha'i dates

=head1 VERSION

version 0.1903

=head1 SYNOPSIS

  perl -MDate::Baha::i -le'print scalar from_bahai(epoch=>time)'

  use Date::Baha'i;

  $bahai_date = to_bahai();
  $bahai_date = to_bahai(epoch => time);
  $bahai_date = to_bahai(
      year  => $year,
      month => $month,
      day   => $day,
  );

  %bahai_date = to_bahai();
  %bahai_date = to_bahai(epoch => time);
  %bahai_date = to_bahai(
      year  => $year,
      month => $month,
      day   => $day,
  );

  $date = from_bahai(
      year  => $bahai_year,
      month => $bahai_month,
      day   => $bahai_day,
  );

  ($year, $month, $day) = from_bahai(
      year  => $bahai_year,
      month => $bahai_month,
      day   => $bahai_day,
  );

  $day = next_holy_day();
  $day = next_holy_day($year, $month, $day);

  @cycles = cycles();
  @years = years();
  @months = months();
  @days = days();
  @days = days_of_the_week();
  %days = holy_days();

=head1 DESCRIPTION

This package renders the Baha'i date from two standard date formats -
epoch time and a (year, month, day) triple.  It also converts a Baha'i 
date to standard ymd format.

=head2 CYCLES

Each cycle of nineteen years is called a Vahid.  Nineteen cycles constitute a
period called Kull-i-Shay.

The names of the years in each cycle are: 

  1.  Alif   - The Letter "A"
  2.  Ba     - The letter "B"
  3.  Ab     - Father
  4.  Dal    - The letter "D"
  5.  Bab    - Gate
  6.  Vav    - The letter "V"
  7.  Abad   - Eternity
  8.  Jad    - Generosity
  9.  Baha   - Splendour
  10. Hubb   - Love
  11. Bahhaj - Delightful
  12. Javab  - Answer
  13. Ahad   - Single
  14. Vahhab - Bountiful
  15. Vidad  - Affection
  16. Badi   - Beginning
  17. Bahi   - Luminous
  18. Abha   - Most Luminous
  19. Vahid  - Unity

=head2 MONTH NAMES

The names of the months in the Baha'i (Badi) calendar were given by the Bab, who
drew them from the nineteen names of God invoked in a prayer said during the
month of fasting in Shi'ih Islam. They are:

  1.  Baha       - Splendour (21 March - 8 April)
  2.  Jalal      - Glory (9 April - 27 April)
  3.  Jamal      - Beauty (28 April - 16 May)
  4.  'Azamat    - Grandeur (17 May - 4 June)
  5.  Nur        - Light (5 June - 23 June)
  6.  Rahmat     - Mercy (24 June - 12 July)
  7.  Kalimat    - Words (13 July - 31 July)
  8.  Kamal      - Perfection (1 August - 19 August)
  9.  Asma'      - Names (20 August - 7 September)
  10. 'Izzat     - Might (8 September - 26 September)
  11. Mashiyyat  - Will (27 September - 15 October)
  12. 'Ilm       - Knowledge (16 October - 3 November)
  13. Qudrat     - Power (4 November - 22 November)
  14. Qawl       - Speech (23 November - 11 December)
  15. Masa'il    - Questions (12 December - 30 December)
  16. Sharaf     - Honour (31 December - 18 January)
  17. Sultan     - Sovereignty (19 January - 6 February)
  18. Mulk       - Dominion (7 February - 25 February)
  * Ayyam-i-Ha   - Days of Ha (26 February - 1 March))
  19. 'Ala       - Loftiness (2 March - 20 March)

=head3 AYYAM-I-HA

Intercalary Days: Four (or five) days in a leap year, before the last month.

=head2 DAY NAMES

The days of the Baha'i week are:
  1. Jalal    - Glory (Saturday)
  2. Jamal    - Beauty (Sunday)
  3. Kaml     - Perfection (Monday)
  4. Fidal    - Grace (Tuesday)
  5. 'Idal    - Justice (Wednesday)
  6. Istijlal - Majesty (Thursday)
  7. Istiqlal - Independence (Friday)

The Baha'i day of rest is Isiqlal (Friday) and the Baha'i day begins and ends at
sunset.

=head2 HOLY DAYS

There are 11 Holy Days:

* Naw Ruz - The Spring Equinox

Generally March 21.

If the equinox falls after sunset on 21 March, Naw Ruz is observed on 22 March,
since the Baha'i day begins at sunset.

* Ridvan - Declaration of Baha'u'llah in 1863

   1st day - 21 April
   9th day - 29 April
  12th day -  2 May

* Declaration of the Bab - 23 May, 1844

* Ascension of Baha'u'llah - 29 May, 1892

* Martyrdom of the Bab - 9 July, 1850

* Birth of the Bab - 20 October, 1819

* Birth of Baha'u'llah - 12 November, 1817

* Ascension of 'Abdu'l-Baha - 28 November, 1921

* Ayyam-i-Ha (the Intercalary Days) 26 February to 1 March

* The Fast - 2-20 March in the month 'Ala - 19 days from sunrise to sunset

=head1 NAME

Date::Baha::i - Convert to and from Baha'i dates

=head1 FUNCTIONS

=head2 to_bahai()

  # Return a string in scalar context.
  $bahai_date = to_bahai();
  $bahai_date = to_bahai(
      epoch => time,
      use_gmtime => $use_gmtime,
      %args,
  );
  $bahai_date = to_bahai(
      year  => $year,
      month => $month,
      day   => $day,
      %args,
  );

  # Return a hash in array context.
  %bahai_date = to_bahai();
  %bahai_date = to_bahai(
      epoch => time,
      use_gmtime => $use_gmtime,
      %args,
  );
  %bahai_date = to_bahai(
      year  => $year,
      month => $month,
      day   => $day,
      %args,
  );

This function returns either a string or a hash of the date names and numbers
from either epoch seconds, or a year, month, day named parameter triple.

If using epoch seconds, this function can be forced to use gmtime instead of
localtime.  If neither a epoch or a ymd triple are given, the system localtime
is used as the default.

The extra, optional arguments are used by the as_string function, detailed
below.

In a scalar context, this function returns a string sentence with the numeric or
named date.  In an array context, it returns a hash with the following keys:

  kull_i_shay,
  cycle, cycle_name, cycle_year,
  year, year_name,
  month, month_name,
  day, day_name,
  dow, dow_name and
  holy_day (if there is one)

=head2 from_bahai()

  # Return a y/m/d string in scalar context.
  $date = from_bahai(
      year  => $bahai_year,
      month => $bahai_month,
      day   => $bahai_day,
  );

  # Return a ymd triple in array context.
  ($year, $month, $day) = from_bahai(
      year  => $bahai_year,
      month => $bahai_month,
      day   => $bahai_day,
  );

This function returns either a string or a list of the given date.

Currently, this supports the Baha'i year, month and day, but not the
kull-i-shay, cycle, cycle name or cycle year.

=head2 as_string()

  $date = as_string(
      \%bahai_date,
      size     => $size,
      alpha    => $alpha,
      numeric  => $numeric,
  );

Return the Baha'i date as a friendly string.

This function takes a Baha'i date hash and Boolean arguments that determine the
format of the output.

The "size" argument toggles between short and long representations.  As the
names imply, the "alpha" and "numeric" flags turn the alphanumeric
representations on or off.  The defaults are as follows:

  alpha   => 1
  numeric => 0
  size    => 1

(Which mean that "long non-numeric alpha" is the default representation.)

Here are some handy examples (newlines added for readability):

  short numeric:
  1/1/159

  long numeric:
  7th day of the week, 1st day of the 1st month, year 159,
  7th year of the 9th vahid of the 1st kull-i-shay, holy day: Naw Ruz

  short alpha
  Istiqlal, Baha of Baha, Abad of Baha

  long alpha:
  week day Istiqlal, day Baha of month Baha,
  year one hundred fifty nine of year Abad of the vahid Baha of the
  1st kull-i-shay, holy day: Naw Ruz

  short alpha-numeric:
  Istiqlal (7), Baha (1) of Baha (1), year 159, Abad (7) of Baha (9)

  long alpha-numeric:
  7th week day Istiqlal, 1st day Baha of the 1st month Baha,
  year one hundred and fifty nine (159), 7th year Abad of the
  9th vahid Baha of the 1st kull-i-shay, holy day: Naw Ruz

=head2 next_holy_day()

  $d = next_holy_day();
  $d = next_holy_day($year, $month, $day);

Return the name of the first holy day after the provided date.

=head2 cycles()

  @c = cycles();

Return the 19 cycle names as an array.

=head2 years()

  @y = years();

Return the 19 year names as an array.

=head2 months()

  @m = months();

Return the 19 month names as an array, along with the intercalary days as the
last element.

=head2 days()

  @d = days();

Return the 19 day names as an array.

=head2 days_of_the_week()

  @d = days_of_the_week();

Return the seven day-of-the-week names as an array.

=head2 holy_days()

  %d = holy_days();

Return a hash with keys of the Holy Day names and values of the date or range.

These values are array references of either two or three elements:
B<month>, B<day> and the (optional) number of B<days observed>.

Dates are given in common, standard (non-Baha'i) format.

=head1 SEE ALSO

L<Date::Calc>

L<Lingua::EN::Numbers>

L<Lingua::EN::Numbers::Years>

L<http://www.projectpluto.com/calendar.htm#bahai>

L<http://www.moonwise.co.uk/year/160bahai.htm>

=head1 TO DO

Re-create the missing 01-as_string.t, 03-misc.t & 04-to_bahai.t tests!

Base the date computation on the time of day (Baha'i day begins at sunset).

Make this a L<DateTime> module.

Support cycles and Kull-i-Shay.

Overload localtime and gmtime, just to be cool?

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
