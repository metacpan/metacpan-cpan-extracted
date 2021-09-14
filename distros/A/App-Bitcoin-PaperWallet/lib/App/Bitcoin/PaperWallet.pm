package App::Bitcoin::PaperWallet;

our $VERSION = '1.01';

use v5.12;
use warnings;

use Bitcoin::Crypto qw(btc_extprv);
use Digest::SHA qw(sha256);

sub get_addresses
{
	my ($key, $count) = @_;
	$count //= 4;

	my @addrs;
	my $priv = $key->derive_key_bip44(index => 0)->get_basic_key;
	my $addr = $priv->get_public_key->get_compat_address;
	push @addrs, $addr;

	for my $ind (1 .. $count - 1) {
		my $priv = $key->derive_key_bip44(index => $ind)->get_basic_key;
		my $addr = $priv->get_public_key->get_segwit_address;
		push @addrs, $addr;
	}

	return @addrs;
}

sub generate
{
	my ($class, $entropy, $pass, $address_count) = @_;

	my $mnemonic = defined $entropy
		? btc_extprv->mnemonic_from_entropy(sha256($entropy))
		: btc_extprv->generate_mnemonic(256)
	;

	my $key = btc_extprv->from_mnemonic($mnemonic, $pass);

	return {
		mnemonic => $mnemonic,
		addresses => [get_addresses($key, $address_count)],
	};
}

1;

__END__

=head1 NAME

App::Bitcoin::PaperWallet - Generate printable cold storage of bitcoins

=head1 SYNOPSIS

	use App::Bitcoin::PaperWallet;

	my $hash = App::Bitcoin::PaperWallet->generate($entropy, $password, $address_count // 4);

	my $mnemonic = $hash->{mnemonic};
	my $addresses = $hash->{addresses};

=head1 DESCRIPTION

This module allows you to generate a Hierarchical Deterministic BIP44 compilant Bitcoin wallet.

This package contains high level cryptographic operations for doing that. See L<paper-wallet> for the main script of this distribution.

=head1 FUNCTIONS

=head2 generate

	my $hash = App::Bitcoin::PaperWallet->generate($entropy, $password, $address_count // 4);

Not exported, should be used as a class method. Returns a hash containing two keys: C<mnemonic> (string) and C<addresses> (array reference of strings).

C<$entropy> is meant to be user-defined entropy (string) that will be passed through sha256 to obtain wallet seed. Can be passed C<undef> explicitly to use cryptographically secure random number generator instead.

C<$password> is a password that will be used to secure the generated mnemonic. Passing empty string will disable the password protection. Note that password does not have to be strong, since it will only secure the mnemonic in case someone obtained physical access to your mnemonic. Using a hard, long password increases the possibility you will not be able to claim your bitcoins in the future.

Optional C<$address_count> is the number of addresses that will be generated (default 4). The first address is always SegWit compat address, while the rest are SegWit native addresses.

=head1 SEE ALSO

L<Bitcoin::Crypto>

=head1 AUTHOR

Bartosz Jarzyna, E<lt>brtastic.dev@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
