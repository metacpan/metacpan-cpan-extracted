# Run this like so: perl 30-Data-Math-qualify_array.t
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
  my $test_name = "Testing qualify_array: unequal length arrays of strings";
  my $dm = Data::Math->new();

  my @a = ( 'A', 'B', 'C', 'D', 'E' );
  my @b = ( 'a', 'b', 'c',  );

  my @a_copy = @a;
  my @b_copy = @b;

   my ( $limit, $a_aref, $b_aref ) = $dm->qualify_array( \@a, \@b );

#   print STDERR "limit: $limit\n";
#   print STDERR Dumper( $a_aref ), "\n";
#   print STDERR Dumper( $b_aref ), "\n";

#   print STDERR Dumper( \@a ), "\n";
#   print STDERR Dumper( \@b ), "\n";

  my $exp_b_aref = [
          'a',
          'b',
          'c',
          '',
          ''
        ];

   is_deeply( $b_aref, $exp_b_aref, "$test_name: short array filled out with empty strings" )
       or print STDERR "qualified b_aref: ", Dumper( $b_aref ), "\n";

  is( $limit, $#a, "$test_name: limit is max index of longer array" );

  my $exp_a_aref =  [
          'A',
          'B',
          'C',
          'D',
          'E'
        ];

   is_deeply( $a_aref, $exp_a_aref, "$test_name: returned ref to long array matches original" )
       or print STDERR "qualified a_aref: ", Dumper( $a_aref ), "\n";

  is_deeply( \@a, \@a_copy, "$test_name: original long array has not been modified " );
  is_deeply( \@b, \@b_copy, "$test_name: original short array has not been modified " );

#   is_deeply( $ds_sum, \@exp, "$test_name" )
#       or print STDERR "ds_sum: ", Dumper( $ds_sum ), "\n";


  $test_name .= " (reverse direction)";

   ( $limit, $b_aref, $a_aref ) = $dm->qualify_array( \@b, \@a );

   is_deeply( $b_aref, $exp_b_aref, "$test_name: short array filled out with empty strings" )
       or print STDERR "qualified b_aref: ", Dumper( $b_aref ), "\n";

   is_deeply( $a_aref, $exp_a_aref, "$test_name: returned ref to long array matches original" )
       or print STDERR "qualified a_aref: ", Dumper( $a_aref ), "\n";

}


{
  my $test_name = "Unequal length arrays of numerics";
  my $dm = Data::Math->new();

  my @a = ( 1, 2, 3, 4, 5, 6  );
  my @b = ( 1, 2, 3  );

  my @a_copy = @a;
  my @b_copy = @b;

   my ( $limit, $a_aref, $b_aref ) = $dm->qualify_array( \@a, \@b );

#    print STDERR "limit: $limit\n";
#    print STDERR Dumper( $a_aref ), "\n";
#    print STDERR Dumper( $b_aref ), "\n";

#    print STDERR Dumper( \@a ), "\n";
#    print STDERR Dumper( \@b ), "\n";

  my $exp_b_aref = [ 1, 2, 3, 0, 0, 0 ];

  is_deeply( $b_aref, $exp_b_aref, "$test_name: short array filled out with empty strings" )
       or print STDERR "qualified b_aref: ", Dumper( $b_aref ), "\n";

  is( $limit, $#a, "$test_name: limit is max index of longer array" );

  my $exp_a_aref =  [ 1, 2, 3, 4, 5, 6 ];

  is_deeply( $a_aref, $exp_a_aref, "$test_name: returned ref to long array matches original" )
       or print STDERR "qualified a_aref: ", Dumper( $a_aref ), "\n";

  is_deeply( \@a, \@a_copy, "$test_name: original long array has not been modified " );
  is_deeply( \@b, \@b_copy, "$test_name: original short array has not been modified " );

  # skipping the reverse test for numerics
}

{
  my $test_name = "Unequal length arrays of references";
  my $dm = Data::Math->new();

  my @a = (
           [ 'aref, ja?' ],
           { rem => 'href, ja?' },
           [ 'aref, again' ],
           { rem => 'href, again' },
          );
  my @b = (
           [ 'different aref', 'see?' ],
           { rem => 'different href', com => 'yes?' },
           # and that's all
          );

  my @a_copy = @a;
  my @b_copy = @b;

   my ( $limit, $a_aref, $b_aref ) = $dm->qualify_array( \@a, \@b );

#     print STDERR "limit: $limit\n";
#     print STDERR Dumper( $a_aref ), "\n";
#     print STDERR Dumper( $b_aref ), "\n";

#     print STDERR Dumper( \@a ), "\n";
#     print STDERR Dumper( \@b ), "\n";

  my $exp_b_aref = [
          [
            'different aref',
            'see?'
          ],
          {
            'rem' => 'different href',
            'com' => 'yes?'
          },
          [],
          {}
        ];

  is_deeply( $b_aref, $exp_b_aref, "$test_name: short array filled out with empty strings" )
       or print STDERR "qualified b_aref: ", Dumper( $b_aref ), "\n";

  is( $limit, $#a, "$test_name: limit is max index of longer array" );

  my $exp_a_aref =  [
          [
            'aref, ja?'
          ],
          {
            'rem' => 'href, ja?'
          },
          [
            'aref, again'
          ],
          {
            'rem' => 'href, again'
          }
        ];

  is_deeply( $a_aref, $exp_a_aref, "$test_name: returned ref to long array matches original" )
       or print STDERR "qualified a_aref: ", Dumper( $a_aref ), "\n";

  is_deeply( \@a, \@a_copy, "$test_name: original long array has not been modified " );
  is_deeply( \@b, \@b_copy, "$test_name: original short array has not been modified " );

  # skipping the reverse test for references
}

done_testing();
