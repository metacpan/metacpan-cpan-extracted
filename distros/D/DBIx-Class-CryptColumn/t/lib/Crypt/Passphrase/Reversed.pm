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
	return '$reversed$1$' . reverse decode_utf8($password);
}

sub needs_rehash {
	my ($self, $hash) = @_;
	return substr($hash, 0, 10) ne '$reversed$';
}

sub crypt_subtypes {
	return 'reversed';
}

sub recode_hash {
	my ($self, $hash) = @_;
	$hash =~ s/ (?<=\$) (\d+) (?=\$) / $1 + 1 /xe;
	return $hash;
}

sub verify_password {
	my ($class, $password, $hash) = @_;
	return 0 unless substr($hash, 0, 10) eq '$reversed$';
	return scalar(reverse decode_utf8($password)) eq substr $hash, 12;
}

1;
