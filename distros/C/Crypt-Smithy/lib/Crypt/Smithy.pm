package Crypt::Smithy;

use warnings;
use strict;

=head1 NAME

Crypt::Smithy - Perl implementation of the 'Smithycode' cipher.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

our @password = ( 1, 1, 25, 3, 5, 8, 13, 21 );

=head1 SYNOPSIS

    use Crypt::Smithy;

    my $s = Crypt::Smithy->new();
    print $s->encrypt_string('jackiefisterwhoareyoudreadnough');

    print $s->decrypt_string('jaeiextostgpsacgreamqwfkadpmqzv'), 

    $s->set_password(1, 1, 2, 3, 5, 8, 13, 21); # Fibonacci

=head1 DESCRIPTION

I<Crypt::Smithy> implements an algorithm used to embed a code in the
2006 judgement in the Da Vinci Code copyright case.
Crypthographically it is I<highly insecure> and is for entertainment
and educational purposes only.
    
=head1 METHODS

=head2 new

Constructor

=cut

sub new {
    my ( $class, %param ) = @_;
    my $self = {};
    bless( $self, $class );
    return $self;
}

=head2 set_password

Set another alphabet than the default (1, 1, 25, 3, 5, 8, 13, 21).

=cut

sub set_password { my $self = shift; @password = @_ }

# Return true if uppercase, otherwise false
sub _is_uppercase {
    my ( $self, $c ) = @_;
    ( $c =~ m/^[A-Z]$/ ) ? return 1 : return;
}

# Return index of 'A' or 'a' depending on case
sub _get_base {
    my ( $self, $c ) = @_;
    return ( $self->_is_uppercase($c) ) ? ord('A') : ord('a');
}

# Decrypt a character
sub _decrypt_char {
    my ( $self, $n, $c ) = @_;
    my $i = ord($c) - $self->_get_base($c);
    my $p = ( $i + $password[ $n % scalar(@password) ] - 1 ) % 26;
    return chr( $self->_get_base($c) + $p );
}

# Decrypt a character
sub _encrypt_char {
    my ( $self, $n, $c ) = @_;
    my $i = ord($c) - $self->_get_base($c);
    my $p = ( $i - $password[ $n % scalar(@password) ] + 1 ) % 26;
    return chr( $self->_get_base($c) + $p );
}

=head2 decrypt_string

Decrypt a string using the current password.

=cut

sub decrypt_string {
    my ( $self, $s ) = @_;
    my $n = 0;
    return join( '', map { $self->_decrypt_char( $n++, $_ ) } split( '', $s ) );
}

=head2 encrypt_string

Encrypt a string using the current password.

=cut

sub encrypt_string {
    my ( $self, $s ) = @_;
    my $n = 0;
    return join( '', map { $self->_encrypt_char( $n++, $_ ) } split( '', $s ) );
}

=head1 AUTHOR

Andreas Faafeng, C<< <aff at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-crypt-smithy at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-Smithy>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::Smithy

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-Smithy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-Smithy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-Smithy>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-Smithy/>

=back

=head1 ACKNOWLEDGEMENTS

The wikipedia article L<https://en.wikipedia.org/wiki/Smithycode> has
a lenghty explaination of the origin of the cipher.

=head1 SEE ALSO

L<http://search.cpan.org/dist/Crypt::Rot13/>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Andreas Faafeng.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your
option any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

A copy of the GNU General Public License is available in the source
tree; if not, write to the Free Software Foundation, Inc., 59 Temple
Place - Suite 330, Boston, MA 02111-1307, USA.


=cut

1;    # End of Crypt::Smithy
