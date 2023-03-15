package Crypt::Passphrase::Reversed;

use strict;
use warnings;

use Crypt::Passphrase -encoder;

use Encode 'decode_utf8';

sub new {
	my ($class, %args) = @_;
	return bless {}, $class;
}

sub hash_password {
	my ($self, $password) = @_;
	return '$reversed$' . reverse decode_utf8($password);
}

sub needs_rehash {
	my ($self, $hash) = @_;
	return substr($hash, 0, 10) ne '$reversed$';
}

sub crypt_subtypes {
	return 'reversed';
}

sub verify_password {
	my ($class, $password, $hash) = @_;
	return 0 unless substr($hash, 0, 10) eq '$reversed$';
	return scalar(reverse decode_utf8($password)) eq substr $hash, 10;
}

1;
