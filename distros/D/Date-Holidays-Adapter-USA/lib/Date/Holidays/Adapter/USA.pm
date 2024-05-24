package Date::Holidays::Adapter::USA;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Adapter for USA holidays

use strict;
use warnings;

use base qw(Date::Holidays::Adapter);

our $VERSION = '0.0106';



sub holidays {
    my ($self, %params) = @_;

    my $dh = $self->{_adaptee}->new;

    if ($dh) {
        return $dh->holidays($params{year});
    } else {
        return;
    }
}


sub is_holiday {
    my ($self, %params) = @_;

    my $dh = $self->{_adaptee}->new;

    if ($dh) {
        return $dh->is_holiday($params{year}, $params{month}, $params{day});
    } else {
        return '';
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Date::Holidays::Adapter::USA - Adapter for USA holidays

=head1 VERSION

version 0.0106

=head1 DESCRIPTION

C<Date::Holidays::Adapter::USA> is the L<Date::Holidays> adapter for
L<Date::Holidays::USA>.

=head1 FUNCTIONS

=head2 holidays

  $holidays = holidays($year);

Return the known holidays for the given year.

=head2 is_holiday

  $holiday = is_holiday($year, $month, $day);

Return the holiday on the given day.

=head1 SEE ALSO

L<Date::Holidays>

L<Date::Holidays::Adapter>

L<Date::Holidays::USA>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Gene Boggs.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
