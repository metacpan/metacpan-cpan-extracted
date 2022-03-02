package Date::Holidays::Adapter::AT;

use strict;
use warnings;
use Carp;

use base 'Date::Holidays::Adapter::DE';

use vars qw($VERSION);

my $format = '%#:%m%d';

$VERSION = '1.30';

# Lifted from Date::Holidays::AT source code
# Ref: https://metacpan.org/source/MDIETRICH/Date-Holidays-AT-v0.1.4/lib/Date/Holidays/AT.pm
my %holiday_names = (
    'neuj' => "New year's day",
    'hl3k' => 'Heilige 3 Koenige',
    'jose' => 'Josef',
    'tdar' => 'Staatsfeiertag (Tag der Arbeit)',
    'flor' => 'Florian',
    'mahi' => 'Mariae Himmelfahrt',
    'rupe' => 'Rupert',
    'volk' => 'Tag der Volksabstimmung',
    'nati' => 'Nationalfeiertag',
    'alhe' => 'Allerheiligen',
    'mart' => 'Martin',
    'leop' => 'Leopold',
    'maem' => 'Mariae Empfaengnis',
    'heab' => 'Heiliger Abend',
    'chri' => 'Christtag',
    'stef' => 'Stefanitag',
    'silv' => 'Silvester',
    'karf' => 'Karfreitag',
    'ostm' => 'Ostermontag',
    'himm' => 'Christi Himmelfahrt',
    'pfim' => 'Pfingstmontag',
    'fron' => 'Fronleichnam',
);

sub holidays {
    my ($self, %params) = @_;

    my $state = $params{'state'} ? $params{'state'} : ['all'];

    my $holidays;

    if ( $params{'year'} ) {
        $holidays = $self->_transform_arrayref_to_hashref(
            Date::Holidays::AT::holidays(
                YEAR   => $params{'year'},
                FORMAT => $format,
                WHERE  => $state,
            )
        );
    }
    else {
        $holidays = $self->_transform_arrayref_to_hashref(
            Date::Holidays::AT::holidays(
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

    my $holidays = Date::Holidays::AT::holidays(
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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Date::Holidays::Adapter::AT - an adapter class for Date::Holidays::AT

=head1 VERSION

This POD describes version 1.30 of Date::Holidays::Adapter::AT

=head1 DESCRIPTION

The is the adapter class for L<Date::Holidays::AT>.

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

=item * L<Date::Holidays::AT>

=item * L<Date::Holidays::Adapter::DE>

=item * L<Date::Holidays::Adapter>

=back

=head1 INCOMPATIBILITIES

Please refer to INCOMPATIBILITIES in L<Date::Holidays>

=head1 BUGS AND LIMITATIONS

B<is_holiday> or similar method is not implemented in L<Date::Holidays::AT> as of version v0.1.4.

The adapter does currently not support the complex API of
L<Date::Holidays::AT> B<holidays>.

Please refer to BUGS AND LIMITATIONS in L<Date::Holidays>

=head1 BUG REPORTING

Please refer to BUG REPORTING in L<Date::Holidays>

=head1 AUTHOR

Jonas Brømsø, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

L<Date::Holidays> and related modules are (C) by Jonas Brømsø, (jonasbn)
2004-2022

Date-Holidays and related modules are released under the Artistic License 2.0

=cut

