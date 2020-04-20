package Date::Holidays::UA;

use 5.006;
use strict;
use warnings;
use Carp;
use DateTime;
use DateTime::Event::Easter;

use Exporter qw(import);

our %EXPORT_TAGS = ( 'all' => [ qw(
    is_holiday
    is_ua_holiday
    is_holiday_dt
    holidays
    ua_holidays
    holidays_dt
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

use constant {
    DEFAULT_LANG => 'UA',
    WEEKEND_MAP => {
        6 => 1,
        7 => 1
    },
    HOLIDAY_RULES => [
        {name => 'New Year', local_name => 'Новий рік', month => 1, day => 1},
        {name => 'Labour Day', local_name => 'День праці', month => 5, day => 1},
        {name => 'Labour Day', local_name => 'День праці', month => 5, day => 2, end_year => 2018},
        {name => 'Defender Of Ukraine day', local_name => 'День захисника України', month => 10, day => 14, start_year => 2015},
        {name => 'Catholic Christmas day', local_name => 'Різдво Христове(католицьке)', month => 12, day => 25, start_year => 2017},
        {name => 'Orthodox Christmas day', local_name => 'Різдво Христове', month => 1, day => 7},
        {name => 'Women Day', local_name => 'Міжнародний жіночий день', month => 3, day => 8},
        {name => 'Victory Day', local_name => 'День перемоги над нацизмом у Другій світовій війні', month => 5, day => 9},
        {name => 'Constitution Day', local_name => 'День Конституції України', month => 6, day => 28},
        {name => 'Independence Day', local_name => 'День незалежності України', month => 8, day => 24},
        {name => 'Orthodox Easter Day', local_name => 'Великдень', is_easter_depend => 1, easter_offset_day => 0},
        {name => 'Orthodox Pentecost Day', local_name => 'Трійця', is_easter_depend => 1, easter_offset_day => 49},
    ]
};

=head1 NAME

Date::Holidays::UA - Holidays module for Ukraine

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    # procedural approach

    use Date::Holidays::UA qw(:all);

    my ($year, $month, $day) = (localtime)[5, 4, 3];
    $year  += 1900;
    $month += 1;

    print 'Holiday!' if is_holiday($year, $month, $day);

    my $calendar = holidays($year, {language => 'en'});
    print $calendar->{'0824'};


    # object-oriented approach

    use DateTime;
    use Date::Holidays::UA;

    my $ua = Date::Holidays::UA->new({ language => 'en' });
    print 'Holiday!' if $ua->is_holiday_dt(DateTime->today);

    my $calendar = $ua->holidays(DateTime->today->year);
    print join("\n", value(%$calendar)); # list of holiday names for Ukraine

=head1 SUBROUTINES/METHODS

=head2 new()

Create a new Date::Holidays::UA object. Parameters should be given as
a hashref of key-value pairs.

    my $ua = Date::Holidays::UA->new();

    my $ua = Date::Holidays::UA->new({
        language => 'en'
    });

One parameters can be specified: B<language>.

=cut

sub new {
    my $class = shift;
    my $args_ref = shift || {};

    croak('Wrong language parameter') if (!ref($args_ref));

    return bless {
        language => $args_ref->{language} || DEFAULT_LANG
    }, $class;
}

=head2 is_holiday()

For a given year, month (1-12) and day (1-31), return 1 if the given
day is a holiday; 0 if not.  When using procedural calling style, an
additional hashref of options can be specified.

    $holiday_p = is_holiday($year, $month, $day);

    $holiday_p = is_holiday($year, $month, $day, {
        language => 'en'
    });

    $holiday_p = $ua->is_holiday($year, $month, $day);

=cut

sub is_holiday {
    return (is_ua_holiday(@_) ? 1 : 0);
}

=head2 is_holiday_dt()

As is_holiday, but accepts a DateTime object in place of a numeric year,
month, and day.

    $holiday_p = is_holiday_dt($dt, {language => 'en'});

    $holiday_p = $ua->is_holiday_dt($dt);

=cut

sub is_holiday_dt {
  my @args = map {
    ref $_ eq 'DateTime' ? ($_->year, $_->month, $_->day) : $_
  } @_;

  return is_holiday(@args);
}

=head2 is_ua_holiday()

Similar to C<is_holiday>. Return the name of the holiday occurring on
the specified date if there is one; C<undef> if there isn't.

    print $ua->is_ua_holiday(2020, 1, 1); # "New Year"

=cut

sub is_ua_holiday {
    my $self;
    $self = shift if (ref $_[0]);

    my $year  = shift;
    my $month = shift;
    my $day   = shift;
    my $opt   = shift;

    _assert_valid_date($year, $month, $day);

    if (!defined($self)) {
        $self = __PACKAGE__->new($opt);
    }

    my $holiday_name = undef;
    my $calendar = $self->_generate_calendar($year);

    for my $holiday(@{$calendar || []}) {
        my $holiday_dt = $holiday->{dt};

        if (($holiday_dt->month == $month) && ($holiday_dt->day == $day)) {
            $holiday_name = $self->_get_holiday_name($holiday);
            last;
        }
    }

    return $holiday_name;
}

=head2 holidays()

For the given year, return a hashref containing all the holidays for
that year.  The keys are the date of the holiday in C<mmdd> format
(eg '1225' for December 25); the values are the holiday names.

    my $calendar = holidays($year, {language => 'en'});
    print $calendar->{'0824'}; # "Independence Day"

    my $calendar = $ua->holidays($year);
    print $calendar->{'0628'}; # "Constitution Day"

=cut

sub holidays {
    my $self;
    $self = shift if (ref $_[0]);

    my $year     = shift;
    my $args_ref = shift;

    unless (defined $self) {
        $self = __PACKAGE__->new($args_ref);
    }

    my $calendar = $self->_generate_calendar($year);
    my %holidays = map {
        $_->{dt}->strftime('%m%d') => $self->_get_holiday_name($_)
    }@{$calendar || []};

    return \%holidays;
}

=head2 ua_holidays()

Same as C<holidays()>.

=cut

sub ua_holidays {
    return holidays(@_);
}

=head2 holidays_dt()

Similar to C<holidays()>, The keys are the date of the holiday in C<mmdd> format
(eg '1225' for December 25); and DateTime objects as the values.

    my $calendar = $ua->holidays_dt($year);

=cut

sub holidays_dt {
    my $self;
    $self = shift if (ref $_[0]);

    my $year     = shift;
    my $args_ref = shift;

    unless (defined $self) {
        $self = __PACKAGE__->new($args_ref);
    }

    my $calendar = $self->_generate_calendar($year);
    my %holidays = map {
        $_->{dt}->strftime('%m%d') => $_->{dt}
    }@{$calendar || []};

    return \%holidays;
}

# _get_holiday_name
#
# accepts: holiday item
# returns: holiday name
#
# generate a holiday calendar for the specified year
sub _get_holiday_name {
    my $self = shift;
    my $holiday = shift;

    croak('Missing or wrong holiday item') if (!$holiday || !keys(%{$holiday || {}}));

    my $holiday_name = (lc($self->{language}) eq lc(DEFAULT_LANG)) ? $holiday->{local_name} : $holiday->{name};
    return $holiday_name;
}

# _generate_calendar
#
# accepts: numeric year
# returns: arrayref of hashref
#
# generate a holiday calendar for the specified year
sub _generate_calendar {
    my $self = shift;
    my $year = shift;
    my $calendar = [];

    croak('Missing year parameter') if (!$year);

    for my $holiday_rule(@{${\HOLIDAY_RULES}}) {
        next if ($holiday_rule->{start_year} && ($year <= $holiday_rule->{start_year}));
        next if ($holiday_rule->{end_year} && ($year >= $holiday_rule->{end_year}));

        if ($holiday_rule->{is_easter_depend}) {
            my $dt = DateTime->new(year => $year);
            my $easter = DateTime::Event::Easter->new(easter => "eastern");
            my $easter_offset_day = $holiday_rule->{easter_offset_day};

            push @{$calendar}, {
                name => $holiday_rule->{name},
                local_name => $holiday_rule->{local_name},
                dt => $easter->following($dt)->add(days => $easter_offset_day)
            };
        }
        else {
            my $dt = DateTime->new(
                year => $year,
                month => $holiday_rule->{month},
                day => $holiday_rule->{day}
            );
            push @{$calendar}, {name => $holiday_rule->{name}, local_name => $holiday_rule->{local_name}, dt => $dt};
        }
    }

    return _spread_on_weekend($calendar);
}

# _spread_on_weekend
#
# accepts: calendar of holidays
# returns: arrayref of hashref
#
# spread weekend holidays on other non-weekend days

sub _spread_on_weekend {
    my $calendar = shift;

    croak('Missing calendar') if (!scalar(@{$calendar || []}));
    my $calc = [];

    for my $holiday(@{$calendar || []}) {
        next if (!$holiday->{dt});

        push(@{$calc}, $holiday);

        my $dt = $holiday->{dt}->clone();
        my $is_weekend = WEEKEND_MAP->{$dt->day_of_week()} ? 1 : 0;

        if ($is_weekend) {
            for (my $offset_day = 1; $offset_day <= 2; $offset_day++) {
                my $dt_next = $dt->clone()->add(days => $offset_day);
                next if (WEEKEND_MAP->{$dt_next->day_of_week()});

                my $is_holiday = scalar(grep{ DateTime->compare($dt_next, $_->{dt}) == 0 }@{$calc || []}) ? 1 : 0;

                if (!$is_holiday) {
                    push(@{$calc}, {name => $holiday->{name}, local_name => $holiday->{local_name}, dt => $dt_next});
                    last;
                }
            }
        }
    }

    return $calc;
}

# _assert_valid_date
#
# accepts: numeric year, month, day
# returns: nothing
#
# throw an exception on invalid dates; otherwise, do nothing.

sub _assert_valid_date {
  my ($year, $month, $day) = @_;

  # DateTime does date validation when a DT object is created.
  my $dt = DateTime->new(
    year => $year, month => $month, day => $day,
  );
}

=head1 AUTHOR

Denis Boyun, C<< <denisboyun at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-date-holidays-ua at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Holidays-UA>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Date::Holidays::UA


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Holidays-UA>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Date-Holidays-UA>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Date-Holidays-UA>

=item * Search CPAN

L<https://metacpan.org/release/Date-Holidays-UA>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Denis Boyun.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1; # End of Date::Holidays::UA
