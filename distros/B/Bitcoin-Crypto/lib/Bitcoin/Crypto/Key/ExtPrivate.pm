package Bitcoin::Crypto::Key::ExtPrivate;
$Bitcoin::Crypto::Key::ExtPrivate::VERSION = '3.001';
use v5.10;
use strict;
use warnings;
use Moo;
use Crypt::Mac::HMAC qw(hmac);
use Bitcoin::BIP39 qw(bip39_mnemonic_to_entropy);
use Types::Common -sigs, -types;
use Carp qw(carp);

use Bitcoin::Crypto::BIP44;
use Bitcoin::Crypto::Key::ExtPublic;
use Bitcoin::Crypto::Constants;
use Bitcoin::Crypto::Helpers qw(ensure_length ecc);
use Bitcoin::Crypto::Util qw(mnemonic_to_seed);
use Bitcoin::Crypto::Types -types;
use Bitcoin::Crypto::Exception;

use namespace::clean;

with qw(Bitcoin::Crypto::Role::ExtendedKey);

sub _is_private { 1 }

sub generate_mnemonic
{
	shift;
	carp 'Bitcoin::Crypto::Key::ExtPrivate->generate_mnemonic is deprecated.'
		. ' Use generate_mnemonic function from Bitcoin::Crypto::Util instead.';

	goto \&Bitcoin::Crypto::Util::generate_mnemonic;
}

sub mnemonic_from_entropy
{
	shift;
	carp 'Bitcoin::Crypto::Key::ExtPrivate->mnemonic_from_entropy is deprecated.'
		. ' Use mnemonic_from_entropy function from Bitcoin::Crypto::Util instead.';

	goto \&Bitcoin::Crypto::Util::mnemonic_from_entropy;
}

signature_for from_mnemonic => (
	method => Str,
	positional => [Str, Maybe [Str], {default => ''}, Maybe [Str], {default => undef}],
);

sub from_mnemonic
{
	my ($class, $mnemonic, $password, $lang) = @_;

	if (defined $lang) {

		# make sure no whitespace gets in the way (only when $lang is specified
		# to make it possible to recover key imported with such error)
		$mnemonic = join ' ', grep { length $_ } split /\s+/, $mnemonic;

		# checks validity of seed in given language
		# requires Wordlist::LANG::BIP39 module for given LANG
		Bitcoin::Crypto::Exception::MnemonicCheck->trap_into(
			sub {
				bip39_mnemonic_to_entropy(
					mnemonic => $mnemonic,
					language => $lang
				);
			}
		);
	}

	return $class->from_seed(mnemonic_to_seed($mnemonic, $password));
}

signature_for from_seed => (
	method => Str,
	positional => [ByteStr],
);

sub from_seed
{
	my ($class, $seed) = @_;

	my $bytes = hmac('SHA512', 'Bitcoin seed', $seed);
	my $key = substr $bytes, 0, 32;
	my $cc = substr $bytes, 32, 32;

	return $class->new(
		key_instance => $key,
		chain_code => $cc,
	);
}

signature_for get_public_key => (
	method => Object,
	positional => [],
);

sub get_public_key
{
	my ($self) = @_;

	my $public = Bitcoin::Crypto::Key::ExtPublic->new(
		key_instance => $self->raw_key('public'),
		chain_code => $self->chain_code,
		child_number => $self->child_number,
		parent_fingerprint => $self->parent_fingerprint,
		depth => $self->depth,
		network => $self->network,
		purpose => $self->purpose,
	);

	return $public;
}

signature_for derive_key_bip44 => (
	method => Object,
	positional => [HashRef, {slurpy => !!1}],
);

sub derive_key_bip44
{
	my ($self, $data) = @_;
	my $path = Bitcoin::Crypto::BIP44->new(
		%{$data},
		coin_type => $self,
	);

	return $self->derive_key($path);
}

sub _derive_key_partial
{
	my ($self, $child_num, $hardened) = @_;
	my $key = $self->raw_key;

	my $hmac_data;
	if ($hardened) {

		# zero byte + key data - 32 bytes
		$hmac_data = "\x00" . $key;
	}
	else {

		# public key data - SEC compressed form
		$hmac_data = $self->raw_key('public_compressed');
	}

	# child number - 4 bytes
	$hmac_data .= ensure_length pack('N', $child_num), 4;

	my $data = hmac('SHA512', $self->chain_code, $hmac_data);
	my $tweak = substr $data, 0, 32;
	my $chain_code = substr $data, 32, 32;

	Bitcoin::Crypto::Exception::KeyDerive->trap_into(
		sub {
			$key = ecc->add_private_key($key, $tweak);
			die 'verification failed' unless ecc->verify_private_key($key);
		},
		"key $child_num in sequence was found invalid"
	);

	return $self->new(
		key_instance => $key,
		chain_code => $chain_code,
		child_number => $child_num,
		parent_fingerprint => $self->get_fingerprint,
		depth => $self->depth + 1,
	);
}

### DEPRECATED

sub from_hex_seed
{
	my ($class, $seed) = @_;

	carp "$class->from_hex_seed(\$seed) is now deprecated. Use $class->from_seed([hex => \$seed]) instead";

	return $class->from_seed([hex => $seed]);
}

1;

__END__
=head1 NAME

Bitcoin::Crypto::Key::ExtPrivate - Bitcoin extended private keys

=head1 SYNOPSIS

	use Bitcoin::Crypto qw(btc_extprv);
	use Bitcoin::Crypto::Util qw(generate_mnemonic to_format)

	# generate mnemonic words first
	my $mnemonic = generate_mnemonic;
	print "Your mnemonic is: $mnemonic";

	# create ExtPrivateKey from mnemonic (without password)
	my $key = btc_extprv->from_mnemonic($mnemonic);
	my $ser_key = to_format [base58 => $key->to_serialized];
	print "Your exported master key is: $ser_key";

	# derive child private key
	my $path = "m/0'";
	my $child_key = $key->derive_key($path);
	my $ser_child_key = to_format [base58 => $child_key->to_serialized];
	print "Your exported $path child key is: $ser_child_key";

	# create basic keypair
	my $basic_private = $child_key->get_basic_key;
	my $basic_public = $child_key->get_public_key->get_basic_key;

=head1 DESCRIPTION

This class allows you to create an extended private key instance.

You can use an extended private key to:

=over

=item * generate extended public keys

=item * derive extended keys using a path

=item * restore keys from mnemonic codes, seeds and base58 format

=back

see L<Bitcoin::Crypto::Network> if you want to work with other networks than
Bitcoin Mainnet.

=head1 METHODS

=head2 new

Constructor is reserved for internal and advanced use only. Use
L</from_mnemonic>, L</from_seed> or L</from_serialized> instead.

=head2 generate_mnemonic

	$mnemonic = $class->generate_mnemonic($len = 128, $lang = 'en')

Deprecated - see L<Bitcoin::Crypto::Util/generate_mnemonic>.

=head2 mnemonic_from_entropy

	$mnemonic = $class->mnemonic_from_entropy($bytes, $lang = 'en')

Deprecated - see L<Bitcoin::Crypto::Util/mnemonic_from_entropy>.

=head2 from_mnemonic

	$key_object = $class->from_mnemonic($mnemonic, $password = '', $lang = undef)

Creates a new key from given mnemonic and password.

Note that technically any password is correct and there's no way to tell if it
was mistaken.

If you need to validate if C<$mnemonic> is a valid mnemonic you should specify
C<$lang>, e.g. C<'en'>. It will also get rid of any extra whitespace before /
after / in between words.

If no C<$lang> is given then any string passed as C<$mnemonic> will produce a
valid key. B<This means even adding whitespace (eg. trailing newline) will
produce a different key>. Be careful when using this method without C<$lang>
argument as you can easily create keys incompatible with other software due to
these whitespace problems.

Returns a new instance of this class.

B<Important note about unicode:> this function only accepts UTF8-decoded
strings (both C<$mnemonic> and C<$password>), but can't detect whether it got
it or not. This will only become a problem if you use non-ascii mnemonic and/or
password. If there's a possibility of non-ascii, always use utf8 and set
binmodes to get decoded (wide) characters to avoid problems recovering your
wallet.

=head2 from_seed

	$key_object = $class->from_seed($seed)

Creates and returns a new key from seed, which can be any data of any length.
C<$seed> is expected to be a byte string.

=head2 from_hex_seed

Deprecated. Use C<< $class->from_seed([hex => $seed]) >> instead.

=head2 to_serialized

	$serialized = $object->to_serialized()

Returns the key serialized in format specified in BIP32 as byte string.

=head2 to_serialized_base58

Deprecated. Use C<< to_format [base58 => $key->to_serialized] >> instead.

=head2 from_serialized

	$key_object = $class->from_serialized($serialized, $network = undef)

Tries to unserialize byte string C<$serialized> with format specified in BIP32.

Dies on errors. If multiple networks match serialized data specify C<$network>
manually (id of the network) to avoid exception.

=head2 from_serialized_base58

Deprecated. Use C<< $class->from_serialized([base58 => $base58]) >> instead.

=head2 set_network

	$key_object = $object->set_network($val)

Change key's network state to C<$val>. It can be either network name present in
L<Bitcoin::Crypto::Network> package or an instance of this class.

Returns current key instance.

=head2 get_public_key

	$public_key_object = $object->get_public_key()

Returns instance of L<Bitcoin::Crypto::Key::ExtPublic> generated from the
private key.

=head2 get_basic_key

	$basic_key_object = $object->get_basic_key()

Returns the key in basic format: L<Bitcoin::Crypto::Key::Private>

=head2 derive_key

	$derived_key_object = $object->derive_key($path)

Performs extended key derivation as specified in BIP32 on the current key with
C<$path>. Dies on error.

See BIP32 document for details on derivation paths and methods.

Returns a new extended key instance - result of a derivation.

=head2 derive_key_bip44

	$derived_key_object = $object->derive_key_bip44(%data)

A helper that constructs a L<Bitcoin::Crypto::BIP44> path from C<%data> and
calls L</derive_key> with it. Refer to L<Bitcoin::Crypto::BIP44/Attributes> to
see what you can include in C<%data>.

Using this method instead of specifying BIP44 path yourself will make sure all
features of BIP44 derivation will be enabled, like different prefixes for
extended keys (C<xprv> / C<yprv> / C<zprv>) and address type generation
checking.

I<Note: coin_type parameter will be ignored, and the current network
configuration set in the extended key will be used.>

=head2 get_fingerprint

	$fingerprint = $object->get_fingerprint($len = 4)

Returns a fingerprint of the extended key of C<$len> length (byte string)

=head1 EXCEPTIONS

This module throws an instance of L<Bitcoin::Crypto::Exception> if it
encounters an error. It can produce the following error types from the
L<Bitcoin::Crypto::Exception> namespace:

=over

=item * MnemonicGenerate - mnemonic couldn't be generated correctly

=item * MnemonicCheck - mnemonic didn't pass the validity check

=item * KeyDerive - key couldn't be derived correctly

=item * KeyCreate - key couldn't be created correctly

=item * NetworkConfig - incomplete or corrupted network configuration

=back

=head1 SEE ALSO

=over

=item L<Bitcoin::Crypto::Key::ExtPublic>

=item L<Bitcoin::Crypto::Network>

=back

=cut

