use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use Crypt::SecretBuffer qw( secret unmask_secrets_to memcmp );

subtest memcmp => sub {
   my $buf= secret("test");
   is( $buf->memcmp("test"),   0, 'memcmp eq' );
   is( $buf->memcmp("test0"), -1, 'memcmp lt' );
   is( $buf->memcmp("tesu"),  -1, 'memcmp lt' );
   is( $buf->memcmp("tes"),    1, 'memcmp gt' );
   is( $buf->memcmp("tess"),   1, 'memcmp gt' );

   subtest const_time => sub {
      plan skip_all => "Set SB_TEST_CONSTTIME to enable this test"
         unless $ENV{SB_TEST_CONSTTIME};
      
      my $long_string= "x" x 4_000_000;
      my $early_mismatch= secret($long_string);
      $early_mismatch->substr(0,1,'a');
      my $late_mismatch= secret($long_string);
      $late_mismatch->substr(-1,1,'a');
      my $bench= cmpthese(-2, {
            early_mismatch => sub { $early_mismatch->memcmp($long_string) },
            late_mismatch  => sub { $late_mismatch->memcmp($long_string) },
         });
      my @rate= map { $_->iters / $_->cpu_a } @{$bench}{'early_mismatch','late_mismatch'};
      note sprintf "early-mismatch %.6f/s / late-mismatch %.6f/s = %.1f%%",
         $rate[0], $rate[1], $rate[0] / $rate[1] * 100;
      is( $rate[0] / $rate[1], float(1, tolerance => .05), 'same speed' );
   };
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

   subtest const_time => sub {
      plan skip_all => "Set SB_TEST_CONSTTIME to enable this test"
         unless $ENV{SB_TEST_CONSTTIME};
      
      my $long_string= "x" x 4_000_000;
      my $early_mismatch= secret($long_string);
      $early_mismatch->substr(0,1,'a');
      ok( $early_mismatch->memcmp($long_string) < 1 );
      my $late_mismatch= secret($long_string);
      $late_mismatch->substr(-1,1,'a');
      ok( $late_mismatch->memcmp($long_string) < 1 );
      my $bench= cmpthese(-2, {
            early_mismatch => sub { memcmp($early_mismatch->span, $long_string) },
            late_mismatch  => sub { memcmp($late_mismatch->span, $long_string) },
         });
      my @rate= map { $_->iters / $_->cpu_a } @{$bench}{'early_mismatch','late_mismatch'};
      note sprintf "early-mismatch %.6f/s / late-mismatch %.6f/s = %.1f%%",
         $rate[0], $rate[1], $rate[0] / $rate[1] * 100;
      is( $rate[0] / $rate[1], float(1, tolerance => .05), 'same speed' );
   };
};

done_testing;
