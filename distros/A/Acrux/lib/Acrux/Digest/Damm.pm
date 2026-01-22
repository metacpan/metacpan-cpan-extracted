package Acrux::Digest::Damm;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

Acrux::Digest::Damm - interface for Damm check digit calculation

=head1 SYNOPSIS

    use Acrux::Digest::Damm;

    my $damm = Acrux::Digest::Damm->new();
    my $d = $damm->checkdigit( "123456789" ); # 4
       $damm->checkdigit( "123456789$d" );    # 0 - correct

=head1 DESCRIPTION

This is a Digest backend module that provides calculation
of the Damm check digit

=head1 METHODS

This class inherits all methods from L<Acrux::Digest> and implements the following new ones

=head2 checkdigit

See L</digest>

=head2 digest

    my $damm = Acrux::Digest::Damm->new();
    my $digest = $damm->digest( "123456789" ); # 4
       $damm->digest( "123456789$digest" );    # 0 - correct
    my $digest = $damm->digest( "987654321" ); # 5
       $damm->digest( "987654321$digest" );    # 0 - correct

Returns Damm checkdigit by specified digits-string

See also L<https://en.wikipedia.org/wiki/Damm_algorithm>

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Acrux::Digest>, L<https://en.wikipedia.org/wiki/Damm_algorithm>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2026 D&D Corporation

=head1 LICENSE

This program is distributed under the terms of the Artistic License Version 2.0

See the C<LICENSE> file or L<https://opensource.org/license/artistic-2-0> for details

=cut

use Carp;

use parent qw/Acrux::Digest/;

use constant DAMM_MAP => [
        [0,3,1,7,5,9,8,6,4,2],
        [7,0,9,2,1,5,4,8,6,3],
        [4,2,0,6,8,7,1,3,5,9],
        [1,7,5,0,9,8,3,4,2,6],
        [6,1,2,3,0,4,5,9,7,8],
        [3,6,7,4,2,0,9,5,8,1],
        [5,8,6,9,7,2,0,1,3,4],
        [8,9,4,5,3,6,2,0,1,7],
        [9,4,3,8,6,1,7,2,0,5],
        [2,5,8,1,4,3,6,7,9,0],
    ];

sub digest {
    my $self = shift;
    my $data = shift;
       $self->data($data) if defined $data;
    my $test = $self->data;
    croak "Incorrect input digit-string" if !defined($test) || $test =~ m/[^0-9]/g;

    my @digits = split(//, $test); # Get all digits from input string of chars
    my $sum = 0;
    foreach my $d (@digits) {
        $sum = DAMM_MAP->[$sum][$d];
    }

    return $sum;
}
sub checkdigit { goto &digest }

1;

__END__
