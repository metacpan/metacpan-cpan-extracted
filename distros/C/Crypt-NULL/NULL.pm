# $Id: NULL.pm,v 1.02 2001/05/04 08:04:27 ams Exp $
# Copyright 2001 Abhijit Menon-Sen <ams@wiw.org>

package Crypt::NULL;

use strict;
use Carp;
use vars qw( $VERSION );

($VERSION) = q$Revision: 1.02 $ =~ /(\d+\.\d+)/;

sub keysize   () { 16 }
sub blocksize () { 16 }

sub new
{
    my ($class, $key) = @_;

    croak "Usage: ".__PACKAGE__."->new(\$key)" unless $key;
    return bless {}, $class;
}

sub encrypt
{
    my ($self, $data) = @_;

    croak "Usage: \$cipher->encrypt(\$data)" unless ref($self) && $data;
    return $data;
}

sub decrypt
{
    my ($self, $data) = @_;

    croak "Usage: \$cipher->decrypt(\$data)" unless ref($self) && $data;
    return $data;
}

1;

__END__

=head1 NAME

Crypt::NULL - NULL Encryption Algorithm

=head1 SYNOPSIS

use Crypt::NULL;

$cipher = Crypt::NULL->new($key);

$ciphertext = $cipher->encrypt($plaintext);

$plaintext  = $cipher->decrypt($ciphertext);

=head1 DESCRIPTION

The NULL Encryption Algorithm is a symmetric block cipher described in
RFC 2410 by Rob Glenn and Stephen Kent. 

This module implements NULL encryption. It supports the Crypt::CBC
interface, with the following functions.

=head2 Functions

=over

=item blocksize

Returns the size (in bytes) of the block (16, in this case).

=item keysize

Returns the size (in bytes) of the key (16, in this case).

=item new($key)

This creates a new Crypt::NULL object with the specified key.

=item encrypt($data)

Encrypts blocksize() bytes of $data and returns the corresponding
ciphertext.

=item decrypt($data)

Decrypts blocksize() bytes of $data and returns the corresponding
plaintext.

=back

=head1 SEE ALSO

Crypt::CBC, Crypt::TEA, Crypt::Twofish

=head1 AUTHOR

Abhijit Menon-Sen <ams@wiw.org>

Copyright 2001 Abhijit Menon-Sen. All rights reserved.

This software is distributed under the terms of the Artistic License
<URL:http://ams.wiw.org/code/artistic.txt>.
