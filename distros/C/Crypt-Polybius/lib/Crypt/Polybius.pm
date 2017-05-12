use 5.008;
use strict;
use warnings;

package Crypt::Polybius;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Moo;
use namespace::sweep;

with qw(
	MooX::Traits
	Crypt::Role::CheckerboardCipher
	Crypt::Role::LatinAlphabet
);

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Crypt::Polybius - implementation of the Polybius square

=head1 SYNOPSIS

   use Crypt::Polybius;
   
   #      1    2    3    4    5
   # 1    A    B    C    D    E
   # 2    F    G    H    I/J  K
   # 3    L    M    N    O    P
   # 4    Q    R    S    T    U
   # 5    V    W    X    Y    Z
   #
   # ATTACK  ->  11 44 44 11 13 25
   # AT      ->  11 44
   # DAWN    ->  14 11 52 33
   
   my $square = Crypt::Polybius->new;
   
   print $square->encipher('Attack at dawn.'), "\n";

=head1 DESCRIPTION

This module provides an object-oriented implementation of the
B<Polybius square>, or B<Polybius checkerboard>. This cipher is
not cryptographically strong, nor completely round-trip-safe.

=head2 Roles

This class performs the following roles:

=over

=item *

L<Crypt::Role::LatinAlphabet>

=item *

L<Crypt::Role::CheckerboardCipher>

=item *

L<MooX::Traits>

=back

=head2 Constructors

=over

=item C<< new(%attributes) >>

Moose-like constructor.

=item C<< new_with_traits(%attributes, traits => \@traits) >>

Alternative constructor provided by L<MooX::Traits>.

=back

=head2 Attributes

The following attributes exist. All of them have defaults, and should
not be provided to the constructor.

=over

=item C<< square >>

An array of arrays of letters. Provided by
L<Crypt::Role::CheckerboardCipher>.

=item C<< square_size >>

The length of one side of the square, as an integer. Provided by
L<Crypt::Role::CheckerboardCipher>.

=item C<< encipher_hash >>

Hashref used by the C<encipher> method. Provided by
L<Crypt::Role::CheckerboardCipher>.

=item C<< decipher_hash >>

Hashref used by the C<decipher> method. Provided by
L<Crypt::Role::CheckerboardCipher>.

=back

=head2 Object Methods

=over

=item C<< encipher($str) >>

Enciphers a string and returns the ciphertext. Provided by
L<Crypt::Role::CheckerboardCipher>.

=item C<< decipher($str) >>

Deciphers a string and returns the plaintext. Provided by
L<Crypt::Role::CheckerboardCipher>.

=item C<< preprocess($str) >>

Perform pre-encipher processing on a string. C<encipher> calls this, so
you are unlikely to need to call it yourself.

The implementation provided by L<Crypt::Role::LatinAlphabet> uppercases
any lower-case letters, and passes the string through Text::Unidecode.
It also replaces any letter B<J> with B<I> because the former is not
found in the alphabet provided by L<Crypt::Role::LatinAlphabet>.

=item C<< alphabet >>

Returns an arrayref of the known alphabet. Provided by
L<Crypt::Role::LatinAlphabet>.

=back

=head2 Class Method

=over

=item C<< with_traits(@traits) >>

Generates a new class based on this class, but adding traits.

L<Crypt::Role::ScrambledAlphabet> is an example of an interesting
trait that works with this class.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Crypt-Polybius>.

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Polybius_square>.

L<Crypt::Polybius::Greek>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

