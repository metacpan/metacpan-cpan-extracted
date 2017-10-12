package Crypt::Hill;

$Crypt::Hill::VERSION   = '0.10';
$Crypt::Hill::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Crypt::Hill - Interface to the Hill cipher (2x2).

=head1 VERSION

Version 0.10

=cut

use 5.006;
use Data::Dumper;
use Crypt::Hill::Utils qw(
    to_matrix_1_x_2
    to_matrix_2_x_1
    inverse_matrix
    generate_table
    get_determinant
    multiply_mod
);

use Moo;
use namespace::clean;

my $CHARSETS   = ['A'..'Z'];
my $KEY_LENGTH = 4;
my $BLOCK_SIZE = 2;

has 'table'       => (is => 'ro', default  => sub { generate_table($CHARSETS); });
has 'block_size'  => (is => 'ro', default  => sub { $BLOCK_SIZE                });
has 'key'         => (is => 'ro', required => 1);
has 'encrypt_key' => (is => 'rw');

=head1 DESCRIPTION

The Hill cipher  is  an  example of a block cipher. A block cipher is a cipher in
which groups of letters are enciphered together in equal length blocks. The  Hill
cipher was developed by Lester Hill & introduced in an article published in 1929.

The L<Crypt::Hill> module is using block size 2.Acceptable characters are A to Z.

=head1 CONSTRUCTOR

The constructor expects one parameter  i.e.  key to be used in the encryption and
decryption.The key should consists of no more than 4 ALPHABETS.

    use strict; use warnings;
    use Crypt::Hill;

    my $crypt = Crypt::Hill->new({ key => 'DDCF' });

=cut

sub BUILD {
    my ($self) = @_;

    my $encrypt_key = $self->_encrypt_key;
    $self->encrypt_key($encrypt_key);
}

=head1 METHODS

=head2 encode($message)

Encodes the message using the key provided and returns encoded message.

    use strict; use warnings;
    use Crypt::Hill;

    my $crypt   = Crypt::Hill->new({ key => 'DDCF' });
    my $encoded = $crypt->encode('HELP');

    print "Encoded: [$encoded]\n";

=cut

sub encode {
    my ($self, $message) = @_;

    return $self->_process($self->encrypt_key, $message);
}

=head2 decode($encoded_message)

Decodes the encoded message using the key provided.

    use strict; use warnings;
    use Crypt::Hill;

    my $crypt   = Crypt::Hill->new({ key => 'DDCF' });
    my $encoded = $crypt->encode('HELP');
    my $decoded = $crypt->decode($encoded);

    print "Encoded: [$encoded]\n";
    print "Decoded: [$decoded]\n";

=cut

sub decode {
    my ($self, $message) = @_;

    return $self->_process($self->_decrypt_key, $message);
}

#
#
# PRIVATE METHODS

sub _process {
    my ($self, $key, $message) = @_;

    my @chars    = @$CHARSETS;
    my $modulos  = scalar(@chars);
    my $size     = $self->block_size;
    my $table    = $self->table;
    my $_message = to_matrix_2_x_1($message, $CHARSETS, $table, $size);
    my $result   = '';
    foreach (@$_message) {
        my $_matrix = multiply_mod($key, $_, $modulos);
        $result .= sprintf("%s%s", $chars[$_matrix->[0][0]], $chars[$_matrix->[1][0]]);
    }

    return $result;
}

# convert key to matrix (1x2)
sub _encrypt_key {
    my ($self)  = @_;

    my $table   = $self->table;
    my $key     = $self->key;
    die "ERROR: Key should be of length $KEY_LENGTH." unless (length($key) == $KEY_LENGTH);

    my $size    = $self->block_size;
    my $enc_key = to_matrix_1_x_2($key, $CHARSETS, $table, $size);
    die "ERROR: Invalid key [$key] supplied." if (get_determinant($enc_key) == 0);

    return $enc_key;
}

# descrypt key to matrix (2x2)
sub _decrypt_key {
    my ($self)  = @_;

    my $key     = $self->encrypt_key;
    my $modulus = scalar(@$CHARSETS);

    return inverse_matrix($key, $modulus);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Crypt-Hill>

=head1 BUGS

Please report any bugs/feature requests to C<bug-crypt-hill at rt.cpan.org>  or
through the web interface at  L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-Hill>.
I will be notified & then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::Hill

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-Hill>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-Hill>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-Hill>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-Hill/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 - 2017 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Crypt::Hill
