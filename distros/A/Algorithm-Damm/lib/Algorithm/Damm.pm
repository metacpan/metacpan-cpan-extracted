package Algorithm::Damm;

use strict;
use Exporter;

use vars qw/$VERSION @ISA @EXPORT @EXPORT_OK $ERROR/;

@ISA       = qw/Exporter/;
@EXPORT    = qw//;
@EXPORT_OK = qw/check_digit is_valid/;

$VERSION = '1.001.002';

=pod

=head1 NAME

Algorithm::Damm - Calculate the Damm error correction check digit.

=head1 SYNOPSIS

  use Algorithm::Damm qw/check_digit is_valid/;

  $c = check_digit("43881234567");
  print "It works\n" if is_valid("43881234567$c");

=head1 DESCRIPTION

This module implements the Damm algorithm for calculating a check
digit.

You can find information about the algorithm by searching the web for
"Damm ECC".  In particular, see the L<SEE ALSO> section (below).

=head1 FUNCTIONS

=over 4

=cut

=item is_valid CHECKSUMMED_NUM

This function returns 1 if the final character of CHECKSUMMED_NUM is
the correct checksum for the rest of the number, 0 if not, and undef
if CHECKSUMMED_NUM contains an invalid character or does not contain
at least two digits (one for the number, and one for the checksum).

This function is equivalent to

  substr $N,length($N)-1 eq check_digit(substr $N,0,length($N)-1)

Additionally, due to the way this algorithm works, if you crank the
checksum calculation through the last digit (checkdigit included), you
will end up with a value of 0.

=cut

sub is_valid {
    my $N = shift;

    return undef unless defined( $N );
    return undef unless length( $N ) >= 2;
    return undef unless $N =~ /^\d+$/;

    return check_digit( $N ) == 0;
}

=item check_digit NUM

This function returns the checksum of the given number.  It will
return undef if it is not able to calculate the checksum.

=cut

{
    # This table is defined at
    # http://en.wikipedia.org/wiki/Damm_algorithm
    my @table = (
        [ qw( 0 3 1 7 5 9 8 6 4 2 ) ],
        [ qw( 7 0 9 2 1 5 4 8 6 3 ) ],
        [ qw( 4 2 0 6 8 7 1 3 5 9 ) ],
        [ qw( 1 7 5 0 9 8 3 4 2 6 ) ],
        [ qw( 6 1 2 3 0 4 5 9 7 8 ) ],
        [ qw( 3 6 7 4 2 0 9 5 8 1 ) ],
        [ qw( 5 8 6 9 7 2 0 1 3 4 ) ],
        [ qw( 8 9 4 5 3 6 2 0 1 7 ) ],
        [ qw( 9 4 3 8 6 1 7 2 0 5 ) ],
        [ qw( 2 5 8 1 4 3 6 7 9 0 ) ],
        );

    sub check_digit {
        my $N = shift;

        return undef unless defined( $N );
        return undef unless length( $N );
        return undef unless $N =~ /^\d+$/;

        my $c = 0;
        my @digits = split(//, $N);
        $c = $table[$c][$_] for @digits;

        return $c;
    }
}

=back

=cut

1;

__END__

=head1 HISTORY

This module came about as I was reverse engineering a checksum method
being used on another project of mine.  History of the method used was
lost to the sands of time, and I needed something to run some quick
tests on various checksum algorithms.

This module is a reimplementation of one of the algorithms I had
tested.

=head1 SEE ALSO

=over 4

=item Algorithm::CheckDigits

L<Algorithm::CheckDigits> is a module that this probably should have
been written as a part of.  There is an open issue
(L<https://github.com/MidLifeXis/perl-algorithm-damm/issues/1>) to add
an integration layer for this module to L<Algorithm::CheckDigits>.

=item Algorithm::LUHN

Original code based on L<Algorithm::LUHN> by Tim Ayers.

=item Math::CheckDigits

Slightly different approach to generating check digits.

=item Wikipedia

L<http://en.wikipedia.org/wiki/Damm_algorithm> - Article explaining
the Damm error correction algorithm.

=back

=head1 REPOSITORY

You can find the source at
L<https://www.github.org/MidLifeXis/perl-algorithm-damm>.

=head1 BUGS

None known at this time, but feel free to submit them to RT or the
issue tracker for this source at GitHub.

=head1 AUTHOR

This module was written by Brian T. Wightman
(http://search.cpan.org/search?author=MLX) based on the module
Algorithm::LUHN by Tim Ayers.

=head1 COPYRIGHT

Copyright (c) 2013 Brian T. Wightman. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
