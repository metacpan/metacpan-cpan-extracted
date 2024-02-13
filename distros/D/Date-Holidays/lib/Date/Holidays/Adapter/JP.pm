package Date::Holidays::Adapter::JP;

use strict;
use warnings;
use vars qw($VERSION);
use Locale::Country;
use Carp;

use base 'Date::Holidays::Adapter';

$VERSION = '1.35';

sub holidays {
    croak "holidays is unimplemented for ".__PACKAGE__;
}

sub is_holiday {
    my ($self, %params) = @_;

    my $sub = $self->{_adaptee}->can('is_japanese_holiday');

    if ($sub) {
        return &{$sub}($params{'year'}, $params{'month'}, $params{'day'});
    } else {
        return;
    }
}

sub _fetch {
    my ( $self, $params ) = @_;

    if ( !$self->{_countrycode} ) {
        croak "No country code specified";
    }

    my $module = 'Date::Japanese::Holiday';

    if ( !$params->{nocheck} ) {
        if ( !code2country($self->{_countrycode}) ) { #from Locale::Country
            croak "$self->{_countrycode} is not a valid country code";
        }
    }

    try {
        $self->_load($module);
    }

    return $module;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Date::Holidays::Adapter::JP - an adapter class for Date::Japanese::Holiday

=head1 VERSION

This POD describes version 1.35 of Date::Holidays::Adapter::JP

=head1 DESCRIPTION

The is the adapter class for L<Date::Japanese::Holiday>.

=head1 SUBROUTINES/METHODS

=head2 new

The constructor, takes a single named argument, B<countrycode>

The constructor is inherited from L<Date::Holidays::Adapter>

=head2 is_holiday

The B<holidays> method, takes 3 named arguments, B<year>, B<month> and B<day>

returns an indication of whether the day is a holiday in the calendar of the
country referenced by B<countrycode> in the call to the constructor B<new>.

=head2 holidays

Not implemented in L<Date::Japanese::Holiday>, calls to this throw the
L<Date::Holidays::Exception::UnsupportedMethod>

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

The adaptee module for this class is named: L<Date::Japanese::Holiday>, but the
adapter class is following the general adapter naming of
Date::Holidays::Adapter::<countrycode>.

B<holidays> method or similar isnot implemented in L<Date::Japanese::Holiday> as
of version 0.05.

The adapter does currently not support the object-oriented API of
L<Date::Japanese::Holiday>.

Please refer to BUGS AND LIMITATIONS in L<Date::Holidays>

=head1 BUG REPORTING

Please refer to BUG REPORTING in L<Date::Holidays>

=head1 SEE ALSO

=over

=item * L<Date::Holidays>

=back

=head1 AUTHOR

Jonas Brømsø, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

L<Date::Holidays> and related modules are (C) by Jonas Brømsø, (jonasbn)
2004-2024

Date-Holidays and related modules are released under the Artistic License 2.0

=cut
