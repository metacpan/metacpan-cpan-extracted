package Date::Holidays::Adapter::UK;

use strict;
use warnings;

use base qw(Date::Holidays::Adapter::GB);

use vars qw($VERSION);

$VERSION = '1.28';

1;

__END__

=pod

=head1 NAME

Date::Holidays::Adapter::UK - adapter dummy class for Date::Holidays::UK

=head1 VERSION

This POD describes version 1.25 of Date::Holidays::Adapter::UK

=head1 DESCRIPTION

The is the an adapter class. It adapts:

=over

=item * L<Date::Holidays::GB>

=back

It can be used to specify the country code B<UK>, do note that this
is not a standard country code so the C<nocheck> parameter has to
be specified in addition.

=head1 SUBROUTINES/METHODS

Please see L<Date::Holidays::Adapter::GB>

=head1 DIAGNOSTICS

Please refer to DIAGNOSTICS in L<Date::Holidays>

=head1 DEPENDENCIES

=over

=item * L<Date::Holidays::GB>

=back

=head1 INCOMPATIBILITIES

L<Date::Holidays::UK> is not supported instead, L<Date::Holidays::GB> is used.

This adapter is implemented to support the country code: B<UK>, which is not included

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
