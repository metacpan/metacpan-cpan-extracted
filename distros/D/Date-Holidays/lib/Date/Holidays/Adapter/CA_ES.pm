package Date::Holidays::Adapter::CA_ES;

use strict;
use warnings;

use base qw(Date::Holidays::Adapter::ES);

use vars qw($VERSION);

$VERSION = '1.25';

1;

__END__

=pod

=head1 NAME

Date::Holidays::Adapter::CA_ES - adapter dummy class for Date::Holidays::CA_ES

=head1 VERSION

This POD describes version 1.25 of Date::Holidays::Adapter::CA_ES

=head1 SYNOPSIS

    # Recommended use via Date::Holidays

    use Date::Holidays;

    my $dh = Date::Holidays->new( countrycode => 'es' );

    if ($dh->is_holiday(year => 2017, month  => 6, day => 24, region => 'ca')) {
        print "Yes it is a Catalan holiday\n";
    }

    my $holidays = $dh->holidays( year => 2006, region => 'ca' );


    # CA_ES identifier directly via Date::Holidays

    use Date::Holidays;

    my $dh = Date::Holidays->new( countrycode => 'CA_ES', nocheck => 1 );

    if ($dh->is_holiday(year => 2017, month  => 6, day => 24)) {
        print "Yes it is a Catalan holiday\n";
    }

    my $holidays = $dh->holidays( year => 2006);

=head1 DESCRIPTION

The is the an adapter class. It adapts:

=over

=item * L<Date::Holidays::CA_ES>

=back

This adapter is a placeholder supporting the implementation in the distribution: L<Date::Holidays::CA_ES>.

The actual implementation is located in L<Date::Holidays::Adapter::ES>, which adapts and combines the two.

=head1 SUBROUTINES/METHODS

Please see L<Date::Holidays::Adapter::ES>

=head1 DIAGNOSTICS

Please refer to DIAGNOSTICS in L<Date::Holidays>

=head1 DEPENDENCIES

=over

=item * L<Date::Holidays::ES>

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
