use Test2::V0;
use Crypt::SecretBuffer qw( secret unmask_secrets_to memcmp );

subtest memcmp => sub {
   my $buf= secret("test");
   is( $buf->memcmp("test"),   0, 'memcmp eq' );
   is( $buf->memcmp("test0"), -1, 'memcmp lt' );
   is( $buf->memcmp("tesu"),  -1, 'memcmp lt' );
   is( $buf->memcmp("tes"),    1, 'memcmp gt' );
   is( $buf->memcmp("tess"),   1, 'memcmp gt' );
};

subtest overload_cmp => sub {
   my $buf= secret("test");
   ok( $buf eq "test",  'eq' );
   ok( $buf lt "test0", 'lt' );
   ok( $buf lt "tesu",  'lt' );
   ok( $buf gt "tes",   'gt' );
   ok( $buf gt "tess",  'gt' );
   ok( "test0" gt $buf, 'reverse gt' );
   ok( "tesu"  gt $buf, 'reverse gt' );
   ok( "tes"   lt $buf, 'reverse lt' );
   ok( "tess"  lt $buf, 'reverse lt' );
};

subtest cmp_span => sub {
   my $buf= secret("ABCDEF");
   is( memcmp($buf->span(0,1), $buf->span(1,1)), -1, 'span lt span' );
   is( memcmp($buf->span(1,1), $buf->span(0,1)),  1, 'span gt span' );
   is( memcmp($buf->span(3,3), $buf->span(3,3)),  0, 'span eq span' );
};

done_testing;
