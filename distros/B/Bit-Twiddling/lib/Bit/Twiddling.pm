package Bit::Twiddling;

use strict;
use warnings;

=head1 NAME

Bit::Twiddling - Low-level bit-twiddling hacks

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

    use Bit::Twiddling 'count_set_bits';
    my $number = 0b1111_0001;
    my $set_bits = count_set_bits($number); # 5

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

The functions in this module expect a single integer argument, but
will convert string to numeric if needed (and give an C<Argument "..."
isn't numeric in subroutine entry> warning). If the argument is
C<undef>, it will be treated as if it were zero and generate a C<Use
of uninitialized value in subroutine entry> warning.

This distribution was designed to work with a perl compiled with
C<use64bitint> and C<uselongdouble>. It should, however, be OK without
these options.

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

=head1 REPORTING BUGS & OTHER WAYS TO CONTRIBUTE

The code for this module is maintained on
L<GitHub|https://github.com/briang/p5-bit-twiddling>.

If you have a patch, feel free to fork the repository and submit a
pull request. If you find a bug, please open an issue on the project
at GitHub (L<https://github.com/briang/p5-bit-twiddling/issues>).

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
