#!perl
use warnings;
use strict;

use Test::More tests => 22;

use Convert::Ascii85 qw(ascii85_encode ascii85_decode);

my @pairs = (
	['Man is distinguished, not only by his reason, but by this singular passion from other animals, which is a lust of the mind, that by a perseverance of delight in the continued and indefatigable generation of knowledge, exceeds the short vehemence of any carnal pleasure.', q~9jqo^BlbD-BleB1DJ+*+F(f,q/0JhKF<GL>Cj@.4Gp$d7F!,L7@<6@)/0JDEF<G%<+EV:2F!,O<DJ+*.@<*K0@<6L(Df-\0Ec5e;DffZ(EZee.Bl.9pF"AGXBPCsi+DGm>@3BB/F*&OCAfu2/AKYi(DIb:@FD,*)+C]U=@3BN#EcYf8ATD3s@q?d$AftVqCh[NqF<G:8+EV:.+Cf>-FD5W8ARlolDIal(DId<j@<?3r@:F%a+D58'ATD4$Bl@l3De:,-DJs`8ARoFb/0JMK@qB4^F!,R<AKZ&-DfTqBG%G>uD.RTpAKYo'+CT/5+Cei#DII?(E,9)oF*2M7/c~],
	["\0" x 8, 'zz'],
	["\0" x 8, 'zz', {compress_zero => 1}],
	["\0" x 8, '!' x 10, {compress_zero => 0}],
	['asdf    rew', '@<5sk+<VdLEb0F'],
	['asdf    rew', '@<5sk+<VdLEb0F', {compress_space => 0}],
	['asdf    rew', '@<5skyEb0F', {compress_space => 1}],
	['', ''],
	["\0", '!!'],
	["\0\0", '!!!'],
	["\0\0\0", '!!!!'],
);


for my $pair (@pairs) {
	my ($plain, $encoded, $options) = @$pair;

	is ascii85_encode($plain, $options || {}), $encoded;
	is ascii85_decode($encoded), $plain;
}
