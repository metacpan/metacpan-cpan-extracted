package Crypt::Dummy;

use strict;
use warnings;

sub keysize	{ 16 }
sub blocksize	{ 16 }

sub new
{
	my ($class, $key) = @_;

	my $len = length $key;
	my $ks  = __PACKAGE__->keysize;

	die "Expected key of length $ks, got $len bytes ('$key')\n" unless $len == $ks;

	return bless \$key, $class;
}

sub encrypt
{
	my ($key, $data) = @_;

	my $len = length $data;
	my $bs  = __PACKAGE__->blocksize;

	die "Expected data of length $bs, got $len bytes ('$data')\n" unless $len == $bs;

	return $data ^ $$key;
}

sub decrypt
{
	my ($key, $data) = @_;

	my $len = length $data;
	my $bs  = __PACKAGE__->blocksize;

	die "Expected data of length $bs, got $len bytes ('$data')\n" unless $len == $bs;

	return $data ^ $$key;
}

'END';
