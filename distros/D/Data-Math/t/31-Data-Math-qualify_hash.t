# Run this like so: perl 31-Data-Math-qualify_hash.t
#   doom@kzsu.stanford.edu     2016/01/19 02:43:17

use warnings;
use strict;
$|=1;
my $DEBUG = 1;              # TODO set to 0 before ship
use Data::Dumper;
use File::Path      qw( mkpath );
use File::Basename  qw( fileparse basename dirname );
use File::Copy      qw( copy move );
use Fatal           qw( open close mkpath copy move );
use Cwd             qw( cwd abs_path );
use Env             qw( HOME );
use List::MoreUtils qw( any );

use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/../lib";
use_ok( 'Data::Math' );

{
  my $test_name = "Testing qualify_hash: holes opposite strings";
  my $dm = Data::Math->new();

  my %a = ( alpha => 'A', beta => 'B', gamma => 'C',   delta => 'D', epsilon => undef );
  my %b = ( alpha => 'A', flat => 'B', gamma => undef, delta => 'D', epsilon => 'E',    krebs => 'G' );

  my %a_copy = %a;
  my %b_copy = %b;

   my ( $keys, $a_href, $b_href ) = $dm->qualify_hash( \%a, \%b );

   # print STDERR "keys: ", Dumper( $keys ), "\n";
  my @exp_raw =
        ( 'gamma',
          'epsilon',
          'delta',
          'alpha',
          'beta',
          'krebs',
          'flat');
  my @exp_keys = sort ( @exp_raw );

  my @keys_sorted =  sort @{ $keys };

  is_deeply( \@keys_sorted, \@exp_keys, "$test_name: unified keys" );

  my $exp_a_href = {
          'gamma'   => 'C',
          'krebs'   => '',
          'alpha'   => 'A',
          'delta'   => 'D',
          'epsilon' => '',
          'beta'    => 'B',
          'flat'    => ''
        };

  #print STDERR Dumper( $b_href ), "\n";

  my $exp_b_href = {
          'gamma'   => '',
          'krebs'   => 'G',
          'alpha'   => 'A',
          'delta'   => 'D',
          'epsilon' => 'E',
          'beta'    => '',
          'flat'    => 'B'
        };

   is_deeply( $b_href, $exp_b_href, "$test_name: b " )
       or print STDERR "qualified b_href: ", Dumper( $b_href ), "\n";

   is_deeply( $a_href, $exp_a_href, "$test_name: a" )
       or print STDERR "qualified a_href: ", Dumper( $a_href ), "\n";


   # print STDERR Dumper( \%a ), "\n";
   # print STDERR Dumper( \%b ), "\n";

  is_deeply( \%a, \%a_copy, "$test_name: original hash a has not been modified " );
  is_deeply( \%b, \%b_copy, "$test_name: original hash b has not been modified " );

  $test_name .= " (reverse direction)";

  ( $keys, $b_href, $a_href ) = $dm->qualify_hash( \%b, \%a );

  is_deeply( $b_href, $exp_b_href, "$test_name: short array filled out with empty strings" )
       or print STDERR "qualified b_href: ", Dumper( $b_href ), "\n";

  is_deeply( $a_href, $exp_a_href, "$test_name: returned ref to long array matches original" )
       or print STDERR "qualified a_href: ", Dumper( $a_href ), "\n";

}


{
  my $test_name = "Testing qualify_hash: holes opposite refs";
  my $dm = Data::Math->new();

  my %a =
    ( alpha => 'A', beta => 'B', gamma => { xtra => [ 0, 1, 3] }, delta => 'D', epsilon => undef );
  my %b =
    ( alpha => 'A', flat => 'B', gamma => undef, delta => 'D',
      epsilon =>
      [ { wuhn => 1 }, { tew  => 2 }, { thuree => 3 } ],
      krebs => 'G' );

  my %a_copy = %a;
  my %b_copy = %b;

  my ( $keys, $a_href, $b_href ) = $dm->qualify_hash( \%a, \%b );

  my @exp_keys =  sort ( 'gamma', 'epsilon', 'delta', 'alpha', 'beta', 'krebs', 'flat' );

  my @keys_sorted =  sort @{ $keys };

  is_deeply( \@keys_sorted, \@exp_keys, "$test_name: unified keys" );

#  print STDERR Dumper( $a_href ), "\n";

  my $exp_a_href = {
          'gamma' => { xtra => [ 0, 1, 3 ] },
          'krebs' => '',
          'alpha' => 'A',
          'delta' => 'D',
#          'epsilon' => [ {}, {}, {} ],  # No: qualify_hash does not recurse
          'epsilon' => [ ],
          'beta' => 'B',
          'flat' => ''
        };

#  print STDERR Dumper( $b_href ), "\n";

  my $exp_b_href = {
#          'gamma' => { xtra => [] },  # Again: qualify_hash does not recurse by itself
          'gamma' => { },
          'krebs' => 'G',
          'alpha' => 'A',
          'delta' => 'D',
          'epsilon' => [ { wuhn => 1 }, { tew  => 2 }, { thuree => 3 } ],
          'beta' => '',
          'flat' => 'B'
        };

   is_deeply( $a_href, $exp_a_href, "$test_name: a" )
       or print STDERR "qualified a_href: ", Dumper( $a_href ), "\n";

   is_deeply( $b_href, $exp_b_href, "$test_name: b " )
       or print STDERR "qualified b_href: ", Dumper( $b_href ), "\n";

   # print STDERR Dumper( \%a ), "\n";
   # print STDERR Dumper( \%b ), "\n";

  is_deeply( \%a, \%a_copy, "$test_name: original hash a has not been modified " );
  is_deeply( \%b, \%b_copy, "$test_name: original hash b has not been modified " );

  $test_name .= " (reverse direction)";

  ( $keys, $b_href, $a_href ) = $dm->qualify_hash( \%b, \%a );

  is_deeply( $b_href, $exp_b_href, "$test_name  " )
       or print STDERR "qualified b_href: ", Dumper( $b_href ), "\n";

  is_deeply( $a_href, $exp_a_href, "$test_name " )
       or print STDERR "qualified a_href: ", Dumper( $a_href ), "\n";

}


done_testing();
