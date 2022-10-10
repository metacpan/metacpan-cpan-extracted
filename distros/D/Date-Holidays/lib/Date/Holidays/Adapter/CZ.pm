package Date::Holidays::Adapter::CZ;

use strict;
use warnings;

use base 'Date::Holidays::Adapter';

use vars qw($VERSION);

$VERSION = '1.33';

my $format = '%#:%m%d';

# Lifted from Date::Holidays::CZ example: svatky.plx
# Ref: https://metacpan.org/source/SMITHFARM/Date-Holidays-CZ-0.13/example/svatky.plx
my %holiday_names = (
    'obss' => 'Restoration Day of the Independent Czech State',
    'veln' => 'Easter Sunday',
    'velp' => 'Easter Monday',
    'svpr' => 'Labor Day',
    'dvit' => 'Liberation Day',
    'cyme' => 'Saints Cyril and Methodius Day',
    'mhus' => 'Jan Hus Day',
    'wenc' => 'Feast of St. Wenceslas (Czech Statehood Day)',
    'vzcs' => 'Independent Czechoslovak State Day',
    'bojs' => 'Struggle for Freedom and Democracy Day',
    'sted' => 'Christmas Eve',
    'van1' => 'Christmas Day',
    'van2' => 'Feast of St. Stephen',
);

sub holidays {
    my ($self, %params) = @_;

    my $sub = $self->{_adaptee}->can('holidays');

    if ($sub) {
        return &{$sub}(YEAR => $params{'year'});
    } else {
        return {};
    }
}

sub is_holiday {
    my ($self, %params) = @_;

    my $holidays = Date::Holidays::CZ::holidays(
        YEAR   => $params{'year'},
        FORMAT => $format,
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

=encoding UTF-8

=head1 NAME

Date::Holidays::Adapter::CZ - an adapter class for Date::Holidays::CZ

=head1 VERSION

This POD describes version 1.33 of Date::Holidays::Adapter::CZ

=head1 DESCRIPTION

The is the adapter class for L<Date::Holidays::CZ>.

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

=head1 DIAGNOSTICS

Please refer to DIAGNOSTICS in L<Date::Holidays>

=head1 DEPENDENCIES

=over

=item * L<Date::Japanese::Holiday>

=item * L<Date::Holidays::Adapter>

=back

=head1 INCOMPATIBILITIES

Please refer to INCOMPATIBILITIES in L<Date::Holidays>

=head1 BUGS AND LIMITATIONS

B<is_holiday> or similar method is not implemented in L<Date::Holidays::CZ> as
of version 0.13.

The adapter does currently not support the complex API of
L<Date::Holidays::CZ> B<holidays>.

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
