package Date::Holidays::Adapter::FR;

use strict;
use warnings;
use vars qw($VERSION);
use Carp;

use base 'Date::Holidays::Adapter';

$VERSION = '1.28';

sub holidays {
    croak "holidays is unimplemented for ".__PACKAGE__;
}

sub is_holiday {
    my ($self, %params) = @_;

    my $sub = $self->{_adaptee}->can('is_fr_holiday');

    if ($sub) {
        return &{$sub}($params{'year'}, $params{'month'}, $params{'day'});
    } else {
        return;
    }
}

1;

__END__

=pod

=head1 NAME

Date::Holidays::Adapter::FR - an adapter class for Date::Holidays::FR

=head1 VERSION

This POD describes version 1.25 of Date::Holidays::Adapter::FR

=head1 DESCRIPTION

The is the adapter class for L<Date::Holidays::FR>.

=head1 SUBROUTINES/METHODS

=head2 new

The constructor is inherited from L<Date::Holidays::Adapter>

=head2 new

The constructor, takes a single named argument, B<countrycode>

The constructor is inherited from L<Date::Holidays::Adapter>

=head2 is_holiday

The B<holidays> method, takes named 3 arguments, B<year>, B<month> and B<day>

Returns an indication of whether the day is a holiday in the calendar of the
country referenced by B<countrycode> in the call to the constructor B<new>.

=head2 holidays

Not implemented in L<Date::Holidays::FR>, calls to this throw the
L<Date::Holidays::Exception::UnsupportedMethod>

=head1 DIAGNOSTICS

Please refer to DIAGNOSTICS in L<Date::Holidays>

=head1 DEPENDENCIES

=over

=item * L<Date::Holidays::FR>

=item * L<Date::Holidays::Adapter>

=back

=head1 INCOMPATIBILITIES

Please refer to INCOMPATIBILITIES in L<Date::Holidays>

=head1 BUGS AND LIMITATIONS

B<holidays> or similar method is not implemented in L<Date::Holidays::FR> as
of version 0.02.

Additional methods of L<Date::Holidays::FR> are not supported currently.

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
