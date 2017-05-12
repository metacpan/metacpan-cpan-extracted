#

use strict;
use lib qw(blib);
use Data::SimplePassword;

use Test::More;

use constant SUCCESS => 1;
use constant FAILURE => 0;

my $sp = Data::SimplePassword->new;
$sp->seed_num( 624 )    # up to 624
  if $ENV{RUN_HEAVY_TEST};

can_ok( $sp, 'make_password' );

# trying to use non-blocking RNG for quick test
$sp->provider("devurandom")
    if $sp->is_available_provider("devurandom");

my @test = (
  [ [] => 8, SUCCESS ],
  [ [ 0..9, 'a'..'Z' ] => 1, SUCCESS ],
  [ [ 0..9, 'a'..'Z' ] => 32, SUCCESS ],
  [ [ 0..9, 'a'..'Z' ] => $ENV{RUN_HEAVY_TEST} ? 1024 * 5 : 256, SUCCESS ],    # 5KB
  [ [ 0 ] => 8, SUCCESS ],
  [ [ 1 ] => 8, SUCCESS ],
  [ [ 'a'..'Z', qw(+ /) ] => 8, SUCCESS ],

  [ [ 0..9 ] => 'foo', FAILURE ],
);

for my $test ( @test ){
  my @chars = @{ $test->[0] };
  my ($len, $rc) = @{$test}[1,2];

#  diag("wait a moment ..")
#    if $len =~ /^\d+$/o && $len > 2000;

  $sp->chars( @chars ) if scalar @chars;
  my $password = eval { $sp->make_password( $len ) };

  if( $rc == SUCCESS ){
    my $regex = quotemeta join '', @chars;
    ok( $password =~ /^[$regex]+$/, "regex" ) if $regex;
    ok( length( $password ) == $len, "length" );
  }
  else{
    ok( ! ( defined $password and $password ne '' ), "fail" );
  }
}

done_testing;

__END__
