use strict;
use warnings;
use utf8;
use Test::More;
use Acme::Collector64;
use Encode;

my $index_table = '🐶🐺🐱🐭🐹🐰🐸🐯🐨🐻🐷🐽🐮🐗🐵🐒🐴🐑🐘🐼🐧🐦🐤🐥🐣🐔🐍🐢🐛🐝🐜🐞🐌🐙🐚🐠🐟🐬🐳🐋🐄🐏🐀🐃🐅🐇🐉🐎🐐🐓🐕🐖🐁🐂🐲🐡🐊🐫🐪🐆🐈🐩🐾💐✔';

my $emoji64 = Acme::Collector64->new(
    index_table => $index_table,
);

cmp_ok $emoji64->encode(encode_utf8('てへぺろ(・ω<)')) ,'eq', '🐊🐊🐸🐳🐊🐊🐸🐊🐊🐊🐸🐪🐊🐊🐷🐗🐷🐵🐵🐭🐉🐈🐾🐻🐒🐱🐟✔';

cmp_ok decode_utf8($emoji64->decode('🐷🐱🐃🐱🐇🐮🐾🐻🐆🐆🐲🐶🐷🐚🐟✔')), 'eq', '(*´ω｀*)';
cmp_ok decode_utf8($emoji64->decode('🐊🐊🐸🐝🐊🐊🐸🐉🐪🐍🐸🐧🐫🐏🐍🐯🐫🐍🐲🐥🐊🐊🐸🐎🐫🐃🐤🐺🐪🐷🐸🐮🐊🐊🐷🐻🐊🐊🐸🐀🐊🐊🐸🐹🐊🐊🐸🐥🐫🐃🐤🐺🐪🐷🐸🐮🐊🐊🐷🐻🐊🐊🐸🐢🐊🐊🐸🐀🐊🐊🐸🐹')), 'eq', 'その顔文字は流行らないし流行らせない';

done_testing;
