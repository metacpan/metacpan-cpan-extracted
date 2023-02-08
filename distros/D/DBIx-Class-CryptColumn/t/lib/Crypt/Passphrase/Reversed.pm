package Crypt::Passphrase::Reversed;

use strict;
use warnings;

use parent 'Crypt::Passphrase::Encoder';

use Encode 'decode_utf8';

sub new {
	my ($class, %args) = @_;
	return bless {}, $class;
}

sub hash_password {
	my ($self, $password) = @_;
	return scalar reverse decode_utf8($password);
}

sub needs_rehash {
	return 1;
}

sub accepts_hash {
	return 1;
}

sub verify_password {
	my ($class, $password, $hash) = @_;
	return scalar(reverse decode_utf8($password)) eq $hash;
}

1;
