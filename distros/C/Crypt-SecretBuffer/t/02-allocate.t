use Test2::V0;
use Crypt::SecretBuffer qw( secret );

my $buf= Crypt::SecretBuffer->new();
is( $buf->capacity, 0, 'initial capacity = 0' );

$buf->capacity(5);
is( $buf->capacity, 5, 'set capacity = 5' );

$buf->capacity(100, 'AT_LEAST');
ok( $buf->capacity >= 100, 'set min capacity 100' );

$buf->capacity(10, 'AT_LEAST');
ok( $buf->capacity >= 100, 'at least 10, still at least 100' );

undef $buf;

done_testing;
