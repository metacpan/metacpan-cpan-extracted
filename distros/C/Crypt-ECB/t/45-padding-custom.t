#!/usr/bin/perl -w

use lib 't';
use Testdata;

my %padding =
(
	'custom'	=> "XX",
);

my $custom = sub
{
	my ($data, $bs, $mode) = @_;

	$data .= 'X' x ($bs - length($data) % $bs)	if ($mode eq 'e');
	$data =~ s/X+$//s				if ($mode eq 'd');

	return $data;
};

use Test::More tests => 2*@ciphers*1 + 1;

BEGIN { use_ok (Crypt::ECB) }

my $ecb = Crypt::ECB->new;

foreach my $cipher (@ciphers)
{
	eval { $ecb->cipher($cipher) };
	SKIP: {	skip "$cipher not installed", 2*(keys %padding) if $@;

		my $ks = $ecb->keysize || 56;
		$ecb->key( substr($key, 0, $ks) );

		foreach my $padstyle (keys %padding)
		{
			$ecb->padding($custom);
			my $enc = $ecb->encrypt($plaintext);
			ok($ecb->decrypt($enc) eq $plaintext, 				"$cipher, $padstyle padding: en- and decryption");

			$ecb->padding('none');
			ok($ecb->decrypt($enc) eq $plaintext . $padding{$padstyle},	"$cipher, $padstyle padding: padded bytes");
		}
	}
}
