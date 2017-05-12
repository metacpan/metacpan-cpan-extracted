use strict;
use warnings;
use utf8;
use Test::More;
use Acme::Collector64;
use Encode;

my $index_table = 'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもらりるれろがぎぐげござじずぜぞばびぶべぼぱぴぷぺぽやゆよわ=';

my $japanese64 = Acme::Collector64->new(
    index_table => $index_table,
);

cmp_ok $japanese64->encode('XD'), 'eq', 'ぬおち=';
cmp_ok $japanese64->encode(encode_utf8('こんにちは！こんにちは！')), 'eq', 'ぴぴきとぴぴさとぴぴきげぴぴきめぴぴきずぽぽばいぴぴきとぴぴさとぴぴきげぴぴきめぴぴきずぽぽばい';

cmp_ok decode_utf8($japanese64->decode('ぴぴさこぴぴきたぴぴきむ')), 'eq', 'らくだ';
cmp_ok decode_utf8($japanese64->decode('ぴぴきのぴぴさかぴぴさうぴぴさとぴぴきすけそそいがまそいらそそいめそそいずじそいれち==')), 'eq', 'じゅもんが ちがいます';

done_testing;
