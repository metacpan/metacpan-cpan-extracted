# Run this like so: perl 40-Data-Math-many_args.t
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
  my $test_name = "Testing calc on multiple arguments";
  my $dm = Data::Math->new();

  my %a1 = ( alpha => 3, beta => 13, gamma => 1000 );
  my %a2 = ( alpha => 5, beta => 17, gamma => 1 );
  my %a3 = ( alpha => 7, beta => 10, gamma => 3 );

  my $result =
    $dm->calc( '+', \%a1, \%a2, \%a3 );

  my %e  = ( alpha => 15, beta => 40, gamma => 1004 );

  is_deeply( $result, \%e, "$test_name: adding three hashes" );

  #2
  my $result2 =
    $dm->calc( '-', \%a3, \%a2, \%a1 );

  my %e2  = ( alpha => -1, beta => -20, gamma => ( 3 -1 -1000 ) );

  is_deeply( $result2, \%e2, "$test_name: subtracting three hashes" );
}



done_testing();
