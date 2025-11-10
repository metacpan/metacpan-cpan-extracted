package App::Bitcoin::PaperWallet;
$App::Bitcoin::PaperWallet::VERSION = '1.14';
use v5.12;
use warnings;

use Bitcoin::Crypto qw(btc_extprv);
use Bitcoin::Crypto::Network;
use Bitcoin::Crypto::Util qw(generate_mnemonic mnemonic_from_entropy);
use Digest::SHA qw(sha256);
use Encode qw(encode);

sub get_addresses
{
	my ($key, $purpose, $count) = @_;

	my @addrs;
	for my $ind (0 .. $count - 1) {
		my $priv = $key->derive_key_bip44(purpose => $purpose, index => $ind)->get_basic_key;
		my $addr = $priv->get_public_key->get_address;
		push @addrs, $addr;
	}

	return @addrs;
}

sub generate
{
	my ($class, $entropy, $pass, $opts) = @_;
	my $compat_addresses = $opts->{compat_addresses} // 1;
	my $segwit_addresses = $opts->{segwit_addresses} // 0;
	my $taproot_addresses = $opts->{taproot_addresses} // 3;
	my $entropy_length = $opts->{entropy_length} // 256;
	my $network = $opts->{network} ? Bitcoin::Crypto::Network->get($opts->{network}) : Bitcoin::Crypto::Network->get;
	$network->set_single;

	# warn about possible problem with entropy
	warn "WARNING: entered entropy is too short, this wallet is insecure!\n"
		if defined $entropy && length $entropy < 30;

	my $mnemonic = defined $entropy
		? mnemonic_from_entropy(substr sha256(encode 'UTF-8', $entropy), 0, $entropy_length / 8)
		: generate_mnemonic($entropy_length)
	;

	my $key = btc_extprv->from_mnemonic($mnemonic, $pass);
	my @address_purposes = $network->supports_segwit()
						 ? ([49 => $compat_addresses], [84 => $segwit_addresses], [86 => $taproot_addresses])
						 : ([44 => $compat_addresses + $segwit_addresses + $taproot_addresses]);

	return {
		mnemonic => $mnemonic,
		addresses => [
			map { get_addresses($key, @$_) } @address_purposes,
		],
	};
}

1;

__END__

=head1 NAME

App::Bitcoin::PaperWallet - Generate printable cold storage of bitcoins

=head1 SYNOPSIS

	use App::Bitcoin::PaperWallet;

	my $hash = App::Bitcoin::PaperWallet->generate($entropy, $password, {
		entropy_length => 128,
	});

	my $mnemonic = $hash->{mnemonic};
	my $addresses = $hash->{addresses};

=head1 DESCRIPTION

This module allows you to generate a Hierarchical Deterministic BIP49/84
compilant Bitcoin wallet.

This package contains high level cryptographic operations for doing that. See
L<paper-wallet> for the main script of this distribution.

=head1 FUNCTIONS

=head2 generate

	my $hash = $class->generate($entropy, $password, \%opts);

Not exported, should be used as a class method. Returns a hash containing two
keys: C<mnemonic> (string) and C<addresses> (array reference of strings).

C<$entropy> is meant to be user-defined entropy (string) that will be passed
through sha256 to obtain wallet seed. Can be passed C<undef> explicitly to use
cryptographically secure random number generator instead.

C<$password> is a password that will be used to secure the generated mnemonic.
Passing empty string will disable the password protection. Note that password
does not have to be strong, since it will only secure the mnemonic in case
someone obtained physical access to your mnemonic. Using a hard, long password
increases the possibility you will not be able to claim your bitcoins in the
future.

C<\%opts> can take following values:

=over

=item * C<compat_addresses>

A number of segwit compat (purpose 49) addresses to generate, 1 by default.

=item * C<segwit_addresses>

A number of segwit native (purpose 84) addresses to generate, 0 by default.

=item * C<taproot_addresses>

A number of taproot (purpose 86) addresses to generate, 3 by default.

=item * C<entropy_length>

A number between 128 and 256 with intervals of 32. 128 will generate 12 words
while 256 will generate 24 words. 256 by default.

=back

=head1 CAVEATS

=over

=item

This module should properly handle unicode in command line, but for in-Perl
usage it is required to pass UTF8-decoded strings to it (like with C<use
utf8;>).

Internally, passwords are handled as-is, while seeds are encoded into UTF8
before passing them to SHA256.

=item

An extra care should be taken when using this module on Windows command line.
Some Windows-specific quirks may not be handled properly. Verify before sending
funds to the wallet.

=back

=head2 Compatibility

=over

=item

Version 1.14 started generating taproot addresses in place of segwit
addresses by default.

=item

Version 1.12 changed the way optional parameters to L<generate> are provided.

=item

Versions 1.01 and older generated addresses with invalid derivation paths.
Funds in these wallets won't be visible in most HD wallets, and have to be
swept by revealing their private keys in tools like
L<https://iancoleman.io/bip39/>. Use derivation path C<m/44'/0'/0'/0> and
indexes C<0> throughout C<3> - sweeping these private keys will recover your
funds.

=item

Versions 1.02 and older incorrectly handled unicode. If you generated a wallet
with unicode password in the past, open an issue in the bug tracker.

=back

=head1 SEE ALSO

L<Bitcoin::Crypto>

=head1 AUTHOR

Bartosz Jarzyna, E<lt>bbrtj.pro@gmail.comE<gt>

Consider supporting my effort: L<https://bbrtj.eu/support>

=head2 Contributors

In no particular order:

=over

=item * chromatic

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021-2025 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

