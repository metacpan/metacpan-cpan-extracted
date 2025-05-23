use Test2::V0;
use Crypt::SecretBuffer qw( secret );

my $buf= Crypt::SecretBuffer->new("test");
is( $buf->length, 4, 'buf->length' );

my $clone= secret($buf);
is( $clone->length, 4, 'clone->length' );

done_testing;
