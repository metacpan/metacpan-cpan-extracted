use Test::More tests => 3;

use Crypt::Camellia_PP;

# keysize=128 msgsize=128
my $func = Crypt::Camellia_PP->new(pack 'H*', '0123456789abcdeffedcba9876543210');
my $ct = $func->encrypt(pack 'H*', '0123456789abcdeffedcba9876543210');
ok($ct eq pack 'H*', '67673138549669730857065648eabe43');

# keysize=192 msgsize=128
$func = Crypt::Camellia_PP->new(pack 'H*', '0123456789abcdeffedcba98765432100011223344556677');
$ct = $func->encrypt(pack 'H*', '0123456789abcdeffedcba9876543210');
ok($ct eq pack 'H*', 'b4993401b3e996f84ee5cee7d79b09b9');

# keysize=256 msgsize=128
$func = Crypt::Camellia_PP->new(pack 'H*', '0123456789abcdeffedcba987654321000112233445566778899aabbccddeeff');
$ct = $func->encrypt(pack 'H*', '0123456789abcdeffedcba9876543210');
ok($ct eq pack 'H*', '9acc237dff16d76c20ef7c919e3a7509');

