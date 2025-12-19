use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use Scalar::Util 'weaken';
use Crypt::SecretBuffer qw( secret unmask_secrets_to );

package FalseException;
use overload '""' => sub { '' };
sub new { bless {}, shift }
package main;

subtest unmask_to => sub {
   my $buf= secret("test");

   # in void context
   my $wref;
   $buf->unmask_to(sub {
      is( \@_, [ 'test' ], 'args' );
      is( wantarray, undef, 'undef wantarray' );
      my $ref= [];
      weaken( $wref= $ref );
      return $ref;
   });
   ok( !defined $wref, 'ref was freed' );

   # in scalar context
   my $ret= $buf->unmask_to(sub {
      is( \@_, [ 'test' ], 'args' );
      is( wantarray, F, 'false wantarray' );
      return @{[5,6,7]};
   });
   is( $ret, 3, 'list in scalar context' ); # list in scalar context

   # in list context with more params
   my @ret= $buf->unmask_to(sub {
      is( \@_, [ 'test' ], 'args' );
      is( wantarray, T, 'wantarray' );
      return 1,2,3;
   });
   is( \@ret, [1,2,3] );

   # propagate exception
   $@= '';
   @ret= eval { $buf->unmask_to(sub { die "failed\n"; }) };
   is( \@ret, [], 'died, no return value' );
   is( $@, "failed\n", 'exception propagated' );

   # don't clobber exception
   $buf->unmask_to(sub { });
   is( $@, "failed\n", 'exception unchanged' );

   $@= '';
   $ret= eval { $buf->unmask_to(sub { die FalseException->new }); 1 };
   is( ref $@, 'FalseException', 'caught false exception object' );
   is( $ret, undef, 'died, no return value' );
};

subtest unmask_secrets_to => sub {
   my $buf1= secret("buf1");
   my $buf2= secret("buf2");

   # in void context
   my $wref;
   unmask_secrets_to(sub {
      is( \@_, [ 'buf1', 'buf2', 1, 2, 7 ], 'args' );
      is( wantarray, undef, 'undef wantarray' );
      my $ref= [];
      weaken( $wref= $ref );
      return $ref;
   }, $buf1, $buf2, 1, 2, 7);
   ok( !defined $wref, 'ref was freed' );

   # in scalar context
   my $ret= unmask_secrets_to(sub {
      is( \@_, [ 'buf1', 'buf2', 'buf1', 'buf1' ], 'args' );
      is( wantarray, F, 'false wantarray' );
      return @{[]};
   }, $buf1, $buf2, $buf1, $buf1);
   is( $ret, 0, 'list in scalar context' );

   # in list context
   my @ret= unmask_secrets_to(sub {
      is( \@_, [ 2, 'buf2' ], 'args' );
      is( wantarray, T, 'wantarray' );
      return 1,2,3;
   }, 2, $buf2 );
   is( \@ret, [1,2,3] );

   # with no args at all
   my @list= unmask_secrets_to(sub {});
   is( \@list, [], 'no args, empty ret' );

   # propagate exception
   $@= '';
   @ret= eval { unmask_secrets_to(sub { die "failed\n"; }) };
   is( \@ret, [], 'died, no return value' );
   is( $@, "failed\n", 'exception propagated' );

   # don't clobber exception
   unmask_secrets_to(sub { });
   is( $@, "failed\n", 'exception unchanged' );

   $@= '';
   $ret= eval { unmask_secrets_to(sub { die FalseException->new }); 1 };
   is( ref $@, 'FalseException', 'caught false exception object' );
   is( $ret, undef, 'died, no return value' );
};

done_testing;
