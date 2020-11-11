package Date::Holidays::Adapter::DE;

use strict;
use warnings;
use Carp;

use base 'Date::Holidays::Adapter';

use vars qw($VERSION);

my $format = '%#:%m%d';

$VERSION = '1.28';

# Lifted from Date::Holidays::DE example: feiertage.pl
# Ref: https://metacpan.org/source/MSCHMITT/Date-Holidays-DE-1.9/example/feiertage.pl
my %holiday_names = (
    'neuj' => 'Neujahrstag',
    'hl3k' => 'Hl. 3 Koenige',
    'weib' => 'Weiberfastnacht',
    'romo' => 'Rosenmontag',
    'fadi' => 'Faschingsdienstag',
    'asmi' => 'Aschermittwoch',
    'grdo' => 'Gruendonnerstag',
    'karf' => 'Karfreitag',
    'kars' => 'Karsamstag',
    'osts' => 'Ostersonntag',
    'ostm' => 'Ostermontag',
    'pfis' => 'Pfingstsonntag',
    'pfim' => 'Pfingstmontag',
    'himm' => 'Himmelfahrtstag',
    'fron' => 'Fronleichnam',
    '1mai' => 'Maifeiertag',
    '17ju' => 'Tag der deutschen Einheit (1954-1990)',
    'mari' => 'Mariae Himmelfahrt',
    'frie' => 'Augsburger Friedensfest (regional)',
    '3okt' => 'Tag der deutschen Einheit',
    'refo' => 'Reformationstag',
    'alhe' => 'Allerheiligen',
    'buss' => 'Buss- und Bettag',
    'votr' => 'Volkstrauertag',
    'toso' => 'Totensonntag',
    'adv1' => '1. Advent',
    'adv2' => '2. Advent',
    'adv3' => '3. Advent',
    'adv4' => '4. Advent',
    'heil' => 'Heiligabend',
    'wei1' => '1. Weihnachtstag',
    'wei2' => '2. Weihnachtstag',
    'silv' => 'Silvester'
);

sub holidays {
    my ($self, %params) = @_;

    my $state = $params{'state'} ? $params{'state'} : ['all'];

    my $holidays;

    if ( $params{'year'} ) {
        $holidays = $self->_transform_arrayref_to_hashref(
            Date::Holidays::DE::holidays(
                YEAR   => $params{'year'},
                FORMAT => $format,
                WHERE  => $state,
            )
        );
    }
    else {
        $holidays = $self->_transform_arrayref_to_hashref(
            Date::Holidays::DE::holidays(
                FORMAT => $format,
                WHERE  => $state,
            )
        );
    }

    return $holidays;
}

sub is_holiday {
    my ($self, %params) = @_;

    my $state = $params{'state'} ? $params{'state'} : ['all'];

    my $holidays = Date::Holidays::DE::holidays(
        YEAR   => $params{'year'},
        FORMAT => $format,
        WHERE  => $state,
    );

    my $holidays_hashref = $self->_transform_arrayref_to_hashref($holidays);

    my $holiday_date = sprintf('%02s%02s', $params{month}, $params{day});

    my $holiday = $holidays_hashref->{$holiday_date};

    if ($holiday) {
        return $holiday;
    } else {
        return '';
    }
}

sub _transform_arrayref_to_hashref {
    my ($self, $arrayref_of_holidays) = @_;

    my $hashref_of_holidays;

    foreach my $entry (@{$arrayref_of_holidays}) {
        my ($shortname, $key) = split /:/, $entry;
        $hashref_of_holidays->{$key} = $holiday_names{$shortname};
    }

    return $hashref_of_holidays;
}

1;

__END__

=pod

=head1 NAME

Date::Holidays::Adapter::DE - an adapter class for Date::Holidays::DE

=head1 VERSION

This POD describes version 1.25 of Date::Holidays::Adapter::DE

=head1 DESCRIPTION

The is the adapter class for L<Date::Holidays::DE>.

=head1 SUBROUTINES/METHODS

=head2 new

The constructor, takes a single named argument, B<countrycode>

The constructor is inherited from L<Date::Holidays::Adapter>

=head2 is_holiday

The C<is_holiday> method, takes 3 named arguments, C<year>, C<month> and C<day>

Returns an indication of whether the day is a holiday in the calendar of the
country referenced by C<countrycode> in the call to the constructor C<new>.

=head2 holidays

The B<holidays> method, takes a single named argument, B<year>

returns a reference to a hash holding the calendar of the country referenced by
B<countrycode> in the call to the constructor B<new>.

The calendar will spand for a year and the keys consist of B<month> and B<day>
concatenated.

In addition from version 1.25 the adapter support the B<state> parameter, defaulting to
B<'all'>.

=head1 DIAGNOSTICS

Please refer to DIAGNOSTICS in L<Date::Holidays>

=head1 DEPENDENCIES

=over

=item * L<Date::Holidays::DE>

=item * L<Date::Holidays::Adapter>

=back

=head1 INCOMPATIBILITIES

Please refer to INCOMPATIBILITIES in L<Date::Holidays>

=head1 BUGS AND LIMITATIONS

B<is_holiday> or similar method is not implemented in L<Date::Holidays::DE> as
of version 0.06.

The adapter does currently not support the complex API of
L<Date::Holidays::DE> B<holidays>.

Please refer to BUGS AND LIMITATIONS in L<Date::Holidays>

=head1 BUG REPORTING

Please refer to BUG REPORTING in L<Date::Holidays>

=head1 AUTHOR

Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

L<Date::Holidays> and related modules are (C) by Jonas B. Nielsen, (jonasbn)
2004-2020

Date-Holidays and related modules are released under the Artistic License 2.0

=cut
