package Date::Holidays::Adapter::USFederal;

use strict;
use warnings;
use vars qw($VERSION);
use Carp; # croak
use Data::Dumper;

use base 'Date::Holidays::Adapter';

$VERSION = '1.23';

# sub new {
#     my $class = shift;

#     my $self = bless {}, ref $class;

#     return $self;
# }

sub holidays {
    croak "holidays is unimplemented for ".__PACKAGE__;
}

sub is_holiday {
    my ($self, %params) = @_;

    $self->_load($self->{_adaptee});

    return Date::Holidays::USFederal::is_usfed_holiday(
        $params{'year'}, $params{'month'}, $params{'day'}
    );
}

1;

__END__

=pod

=head1 NAME

Date::Holidays::Adapter::USFederal - an adapter class for Date::Holidays::USFederal

=head1 VERSION

This POD describes version 1.23 of Date::Holidays::Adapter::USFederal

=head1 DESCRIPTION

The is the adapter class for L<Date::Holidays::USFederal>.

=head1 SUBROUTINES/METHODS

=head2 new

The constructor, takes a single named argument, B<countrycode>

=head2 is_holiday

The B<holidays> method, takes 3 named arguments, B<year>, B<month> and B<day>

Returns an indication of whether the day is a holiday in the calendar of the
country referenced by B<countrycode> in the call to the constructor B<new>.

=head2 holidays

Not supported by L<Date::Holidays::USFederal>

=head1 DIAGNOSTICS

Please refer to DIAGNOSTICS in L<Date::Holidays>

=head1 DEPENDENCIES

=over

=item * L<Date::Holidays::USFederal>

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
