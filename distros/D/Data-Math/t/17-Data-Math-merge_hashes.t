# Perl test file, can be run like so:
#   perl 17-Data-Math-merge_hashes.t
#         jbrenner@ffn.com   December 04, 2015  17:10

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
  my $test_name = "Testing calc '+' with two unrelated hashes";
  my $dm = Data::Math->new();
  my %stuff = ( de => 2345.37,
                es => 1238.99,
                us => 1.98,
             );
  my %fur = ( cat => 'black',
              dog => 'bounce',
              hippie => '*bonk*',
             );
  my $merged = $dm->calc( '+', \%stuff, \%fur );
  # print STDERR "merged: ", Dumper( $merged ), "\n";

  my %exp =  ( de => 2345.37,
               es => 1238.99,
               us => 1.98,
               cat => 'black',
               dog => 'bounce',
               hippie => '*bonk*',
             );

  is_deeply( $merged, \%exp, "$test_name" )
          or print STDERR "merged: ", Dumper( $merged ), "\n";

  $test_name = "Testing calc '-' with two unrelated hashes";

  my $merged2 = $dm->calc( '-', \%stuff, \%fur );
  # print STDERR "merged: ", Dumper( $merged ), "\n";

  # Note: not change in expectations
  is_deeply( $merged2, \%exp, "$test_name: strings passed through" )
          or print STDERR "merged: ", Dumper( $merged ), "\n";



  my $merged3 = $dm->calc( '-', \%fur, \%stuff );
  # print STDERR "merged: ", Dumper( $merged ), "\n";

  my %exp3 =  ( de => -2345.37,
               es => -1238.99,
               us => -1.98,
               cat => 'black',
               dog => 'bounce',
               hippie => '*bonk*',
             );

  is_deeply( $merged3, \%exp3, "$test_name: numerics in 2nd go negative" )
          or print STDERR "merged: ", Dumper( $merged ), "\n";

}


done_testing();


