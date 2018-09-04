package Bit::Twiddling;

use strict;
use warnings;

=head1 NAME

Bit::Twiddling - Low-level bit-twiddling hacks

=head1 VERSION

Version 0.09 - 2018-08-31

=cut

our $VERSION = '0.09';

=head1 SYNOPSIS

    use Bit::Twiddling 'count_set_bits';
    my $number = 0b1111_0001;
    my $set_bits = count_set_bits($number); # 5
    printf "There are %d ones in 0b%b\n", $set_bits, $number
    #                         There are 5 ones in 0b11110001

    use Bit::Twiddling 'nearest_higher_power_of_2';
    print nearest_higher_power_of_2(   0); # 1
    print nearest_higher_power_of_2(1000); # 1024
    print nearest_higher_power_of_2(1024); # 1024

=head1 DESCRIPTION

This library is a collection of bit-manipulation functions written in
C, all taken from the L<Bit Twiddling
Hacks|http://graphics.stanford.edu/~seander/bithacks.html> webpage.

=cut

require XSLoader;
XSLoader::load('Bit::Twiddling', $VERSION);

use Exporter 'import';

our @EXPORT_OK = qw(
    count_set_bits
    nearest_higher_power_of_2
);

our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

1;

=head1 EXPORTS

Nothing is exported by default, but the following functions are
available for export by name

=over 4

count_set_bits

nearest_higher_power_of_2

=back

Additionally, you can request the export of all functions by C<use
Bit::Twiddling ':all'>.

=cut

=head1 FUNCTIONS

The functions in this module all expect a single 64-bit integer
argument, but will convert string to numeric if needed (and give an
C<Argument "whatevs" isn't numeric in subroutine entry> warning). If
the argument is C<undef>, it will also be treated as if it were zero
and generate a C<Use of uninitialized value in subroutine entry>
warning.

This distribution is designed to work with 64-bit ints and has NOT
BEEN TESTED WITH 32-BIT PERLS. I think it should be OK but I know one
test in C<nearest.t> will definately fail.

=head2 count_set_bits

    $bits = count_set_bits($number);

C<count_set_bits> will return the count of how many bits are set (1)
in the binary representation of C<$number>. C<$number> is assumed to
be compatible with C's C<long int> type (probably 64-bits).

=head2 nearest_higher_power_of_2

    $power_of_2 = nearest_higher_power_of_2($number);

C<nearest_higher_power_of_2> will return the largest power-of-two that
is greater-than-or-equal-to C<$number>.

=head1 EXAMPLES

There are two scripts in the C<examples> folder of the dist.

=head2 c.pl

This script contains the original C code that was used with
C<Inline::C> to generate the module's XS.

=head2 benchmarks.pl

Some benchmarks of this module versus various pure Perl
implementations.

=head1 AUTHOR

Brian Greenfield <briang at cpan dot org>

=head1 REPOSITORY

L<https://github.com/briang/p5-bit-twiddling>

=head1 BUGS

Please use report any bugs you find to L<GitHub
issues|https://github.com/briang/p5-bit-twiddling/issues>.

=head1 ACKNOWLEDGEMENTS

=over

* Steve Bertrand's
L<Wrapping a C shared library with Perl and XS|http://blogs.perl.org/users/steve_bertrand/2017/03/wrapping-a-c-shared-library-with-perl-and-c.html>
tutorial

* L<Bit Twiddling
  Hacks|http://graphics.stanford.edu/~seander/bithacks.html>

* L<MetaCPAN's online POD renderer|https://metacpan.org/pod2html>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Brian Greenfield

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See L<The "Artistic License"|http://dev.perl.org/licenses/artistic.html>

=cut
