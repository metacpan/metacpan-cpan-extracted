package Crypt::Passphrase::Argon2::Rot;

use strict;
use warnings;

use parent 'Crypt::Passphrase::Argon2::Encrypted';
use Crypt::Passphrase 0.010 -encoder;

use Carp 'croak';

sub new {
	my ($class, %args) = @_;
	return $class->SUPER::new(%args, cipher => 'rot');
}

sub encrypt_hash {
	my ($self, $cipher, $id, $iv, $raw) = @_;
	return $raw =~ s/(.)/chr((ord($1) + $id) % 256)/gers;
}

sub decrypt_hash {
	my ($self, $cipher, $id, $iv, $raw) = @_;
	return $raw =~ s/(.)/chr((ord($1) + (256 - $id)) % 256)/gers;
}

1;
