package Aut::Crypt;

# $Id: Crypt.pm,v 1.2 2004/04/08 16:55:13 cvs Exp $ 

use Crypt::CBC;
use strict;

sub new {
  my $class=shift;
  my $key=shift;
  my $self;

  $self->{"key"}=$key;

  bless $self,$class;
return $self;
}

sub encrypt {
  my $self=shift;
  my $text=shift;
  my $cbc=new Crypt::CBC( { 'key' => $self->{"key"}, 'cipher' => 'Blowfish' } );
return $cbc->encrypt($text);
}

sub decrypt {
  my $self=shift;
  my $text=shift;
  my $cbc=new Crypt::CBC( { 'key' => $self->{"key"}, 'cipher' => 'Blowfish' } );
return $cbc->decrypt($text);
}

1;
__END__

=head1 NAME

Aut::Crypt - Symmetric encryption for Aut

=head1 ABSTRACT

This module provides an easy interface to L<Crypt::CBC> to use
with the Aut framework. It uses blowfish to encrypt/decrypt
stuff.

=head1 DESCRIPTION

=head2 C<new(seed) --E<gt> Aut::Crypt>

=over 1

Instantiates a new C<Aut::Crypt> object with given seed value as 
encryption key.

=back

=head2 C<encrypt(plaintext) --E<gt> ciphertext>

=over 1

Encrypts the given plaintext using Crypt::CBC's encrypt function with key 'seed' 
and cipher 'Blowfish'. Returns the encrypted ciphertext as is.

=back

=head2 C<decrypt(ciphertext) --E<gt> plaintext>

=over 1

Decrypts the given ciphertext using Crypt::CBC's decrypt function with key 'seed' 
and cipher 'Blowfish'. Returns the plaintext as is. There's no check weather the
decryption resulted in anything valid. This has to be checked by the caller.

A simple practice is to prepend a plaintext with some other known plaintext and
use the other plaintext to check if the decryption resulted in anything really plain. 

=back

=cut
