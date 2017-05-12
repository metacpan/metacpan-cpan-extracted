# Run this like so: `perl 19-Data-Math-string_handler.t'
#   doom@kzsu.stanford.edu     2016/01/24 04:34:22

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
  my $policy = 'default';
  my $test_name = "Testing string_handler";


  my @cases = (
               # [  $policy, $left, $right, $expected, $case_name  ]
               [ undef, "alpha", "romeo", "alpha|romeo", "differ" ],
               [ undef, "alpha", "alpha", "alpha", "identical" ],
               [ undef, "alpha", undef, "alpha", "missing right" ],
               [ undef, undef, "alpha", "alpha", "missing left" ],

               [ undef, "alpha", undef, "alpha", "missing right" ],
               [ undef, undef, undef, undef, "two undefs" ], # Is Right Thing?
               [ undef, '', '', "", "two empty strings" ],

               [ 'default', "alpha", "romeo", "alpha|romeo", "differ" ],
               [ 'default', "alpha", "alpha", "alpha", "identical" ],
               [ 'default', "alpha", undef, "alpha", "missing right" ],
               [ 'default', undef, "alpha", "alpha", "missing left" ],

               [ 'concat_if_differ', "alpha", "romeo", "alpha|romeo", "differ" ],
               [ 'concat_if_differ', "alpha", "alpha", "alpha", "identical" ],
               [ 'concat_if_differ', "alpha", undef, "alpha", "missing right" ],
               [ 'concat_if_differ', undef, "alpha", "alpha", "missing left" ],

               [ 'pick_one', "alpha", "romeo", "alpha", "differ" ],
               [ 'pick_one', "alpha", "alpha", "alpha", "identical" ],
               [ 'pick_one', "alpha", undef, "alpha", "missing right" ],
               [ 'pick_one', undef, "alpha", "alpha", "missing left" ],


               [ 'pick_2nd', "alpha", "romeo", "romeo", "differ" ],
               [ 'pick_2nd', "alpha", "alpha", "alpha", "identical" ],
               [ 'pick_2nd', "alpha", undef, "alpha", "missing right" ],
               [ 'pick_2nd', undef, "alpha", "alpha", "missing left" ],


              );

  foreach my $case ( @cases ) {

    my ( $policy, $left, $right, $expected, $case_name ) =
      @{ $case };

    my $dm;
    if( not( defined( $policy ) ) ) {
      $dm = Data::Math->new( );
      $policy = 'undefined';
    } else {
      $dm = Data::Math->new( string_policy => $policy );
    }

    my $result = $dm->string_handler( $left, $right );

    is( $result, $expected, "$test_name with policy $policy: $case_name" );
  }
}

done_testing();
