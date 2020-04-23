package Date::Holidays::Adapter::NZ;

use strict;
use warnings;
use vars qw($VERSION);

use base 'Date::Holidays::Adapter';

$VERSION = '1.21';

sub holidays {
    my ($self, %params) = @_;

    my $sub = $self->{_adaptee}->can('nz_holidays');

    if ($sub and $params{region}) {
        return &{$sub}($params{'year'}, $params{region});
    } elsif ($sub) {
        return &{$sub}($params{'year'});
    } else {
        return;
    }
}

sub is_holiday {
    my ($self, %params) = @_;

    my $sub = $self->{_adaptee}->can('is_nz_holiday');

    if ($sub and $params{region}) {
        return &{$sub}($params{'year'}, $params{'month'}, $params{'day'}, $params{region});
    } elsif ($sub) {
        return &{$sub}($params{'year'}, $params{'month'}, $params{'day'});
    } else {
        return;
    }
}

1;

__END__

=pod

=head1 NAME

Date::Holidays::Adapter::NZ - an adapter class for Date::Holidays::NZ

=head1 VERSION

This POD describes version 1.21 of Date::Holidays::Adapter::NZ

=head1 DESCRIPTION

The is an adapter class for L<Date::Holidays::NZ>

=head1 SUBROUTINES/METHODS

=head2 new

The constructor, takes a single named argument, B<countrycode>

=head2 is_holiday

The B<holidays> method, takes 3 named arguments, B<year>, B<month> and B<day>

Returns an indication of whether the day is a holiday in the calendar of the
country referenced by B<countrycode> in the call to the constructor B<new>.

It supports the optional parameter B<region> for specifying a region within New Zealand.

=head2 holidays

The B<holidays> method, takes a single named argument, B<year>

Returns a reference to a hash holding the calendar of the country referenced by
B<countrycode> in the call to the constructor B<new>.

The calendar will spand for a year and the keys consist of B<month> and B<day>
concatenated.

It supports the optional parameter B<region> for specifying a region within New Zealand.

=head1 DIAGNOSTICS

Please refer to DIAGNOSTICS in L<Date::Holidays>

=head1 DEPENDENCIES

=over

=item * L<Date::Holidays::NZ>

=item * L<Date::Holidays::Adapter>

=back

=head1 INCOMPATIBILITIES

Please refer to INCOMPATIBILITIES in L<Date::Holidays>

=head1 BUGS AND LIMITATIONS

No known bugs or limitations at this time

=head1 BUG REPORTING

Please refer to BUG REPORTING in L<Date::Holidays>

=head1 AUTHOR

Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

L<Date::Holidays> and related modules are (C) by Jonas B. Nielsen, (jonasbn)
2004-2020

Date-Holidays and related modules are released under the Artistic License 2.0

=cut
