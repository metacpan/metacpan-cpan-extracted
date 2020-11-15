package Date::Holidays::Adapter::ES;

use strict;
use warnings;

use base 'Date::Holidays::Adapter';
use Module::Load; # load

use vars qw($VERSION);

$VERSION = '1.29';

sub holidays {
    my ($self, %params) = @_;

    my $dh = $self->{_adaptee}->new();

    my $holidays_es_hashref = {};
    my $holidays_ca_es_hashref = {};

    if ($dh) {
        $holidays_es_hashref = $dh->holidays(year => $params{year});

        if ($params{region} and $params{region} eq 'ca') {

            eval { load 'Date::Holidays::CA_ES'; }; # From Module::Load
            if ($@) {
                warn "Unable to load: Date::Holidays::CA_ES - $@\n";
                return $holidays_es_hashref;
            }

            my $dh_ca_es = Date::Holidays::CA_ES->new();
            $holidays_ca_es_hashref = $dh_ca_es->holidays(year => $params{year});
        }
    } else {
        return;
    }

    foreach my $key (keys %{$holidays_ca_es_hashref}) {
        $holidays_es_hashref->{$key} = $holidays_ca_es_hashref->{$key};
    }

    return $holidays_es_hashref;
}

sub is_holiday {
    my ($self, %params) = @_;

    my $dh = $self->{_adaptee}->new();

    if ($dh) {
        my $holiday = $dh->is_holiday(year => $params{year}, month => $params{month}, day => $params{day});

        if ($params{region} and $params{region} eq 'ca') {

            eval { load 'Date::Holidays::CA_ES'; }; # From Module::Load
            if ($@) {
                warn "Unable to load: Date::Holidays::CA_ES - $@\n";
                return $holiday;
            }

            my $dh_ca_es = Date::Holidays::CA_ES->new();

            my $holidays = $dh_ca_es->holidays(year => $params{year}, region => $params{region});

            my $holiday_date = sprintf('%02s%02s', $params{month}, $params{day});

            $holiday = $holidays->{$holiday_date};

            if ($holiday) {
                return $holiday;
            } else {
                return '';
            }
        }

        return $holiday
    } else {
        return '';
    }
}

1;

__END__

=pod

=head1 NAME

Date::Holidays::Adapter::ES - adapter class for Date::Holidays::ES and Date::Holidays::CA_ES

=head1 VERSION

This POD describes version 1.25 of Date::Holidays::Adapter::ES

=head1 DESCRIPTION

The is the an adapter class. It adapts:

=over

=item * L<Date::Holidays::ES>

=item * L<Date::Holidays::CA_ES>

=back

The adapter merges the information on holidays from the two distributions mentioned above.

The L<Date::Holidays::ES> acts as the primary holiday indication, holidays special for the
Catalan region is accessible when the optional C<region> parameter is used. Please see the
descriptions for the methods below.

=head1 SUBROUTINES/METHODS

=head2 new

The constructor is inherited from L<Date::Holidays::Adapter>

=head2 is_holiday

The C<is_holiday> method, takes 3 named arguments, C<year>, C<month> and C<day>

Returns an indication of whether the day is a holiday in the calendar of the
country referenced by C<countrycode> in the call to the constructor C<new>.

It supports the optional parameter C<region> for specifying a region within Spain.

=head2 holidays

The L<holidays> method, takes a single named argument, C<year>

Returns a reference to a hash holding the calendar of the country referenced by
C<countrycode> in the call to the constructor L<new>.

The calendar will spand for a year and the keys consist of C<month> and C<day>
concatenated.

It supports the optional parameter C<region> for specifying a region within Spain.

=head1 DIAGNOSTICS

Please refer to DIAGNOSTICS in L<Date::Holidays>

=head1 DEPENDENCIES

=over

=item * L<Date::Holidays::ES>

=item * L<Date::Holidays::CA_ES>

=item * L<Date::Holidays::Adapter>

=back

=head1 INCOMPATIBILITIES

Please refer to INCOMPATIBILITIES in L<Date::Holidays>

=head1 BUGS AND LIMITATIONS

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
