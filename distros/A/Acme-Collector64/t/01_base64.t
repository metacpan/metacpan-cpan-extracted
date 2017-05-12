use strict;
use warnings;
use utf8;
use Test::More;
use Acme::Collector64;
use Encode;

my $base64 = Acme::Collector64->new();

cmp_ok $base64->encode(':)'), 'eq', 'Oik=';
cmp_ok $base64->encode('Perl'), 'eq', 'UGVybA==';

cmp_ok decode_utf8($base64->decode('44GT44KT44Gr44Gh44Gv44CB5LiW55WM')), 'eq', 'こんにちは、世界';
cmp_ok decode_utf8($base64->decode('KCDvvp/QtO++nyk=')), 'eq', '( ﾟдﾟ)';

done_testing;
