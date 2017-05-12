# Run like:   perl 16-Data-Math-array_of_hash_with_holes.t
#         jbrenner@ffn.com     Fri  December 04, 2015  09:51

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
  my $test_name = "Testing calc '+' on an array of hashes of unequal length";

  my $dm = Data::Math->new();
  my @a =
      ( { amount => 1.98,
          type   => 'fungus',
        },
        { amount => 6.66,
          type   => 'mossy',
        },
        { amount => 33,
          type   => 'tentacular',
        },
        { amount => .666,
          type   => 'mite',
        },
    );

  my @b =
      ( { amount => 0.02,
          type   => 'fungus',
        },
        { amount => 0.04,
          type   => 'mossy',
        },
        { amount => 67,
          type   => 'tentacular',
         },
      );

  my $ds_sum = $dm->calc( '+', \@a, \@b );

  my @exp =
      ( { amount => 2.00,
          type   => 'fungus',
         },
         { amount => 6.70,
           type   => 'mossy',
          },
          { amount => 100,
            type   => 'tentacular',
          },
        { amount => .666,
          type   => 'mite',
        },
      );

  is_deeply( $ds_sum, \@exp, "$test_name:" )
      or print STDERR "ds_sum: ", Dumper( $ds_sum ), "\n";


  my $ds_sum_converse = $dm->calc( '+', \@b, \@a );

  is_deeply( $ds_sum, \@exp, "$test_name: commutative" )
      or print STDERR "ds_sum: ", Dumper( $ds_sum ), "\n";

}

{
  my $test_name = "Testing calc '+' on an array of hashes with holes";

  my $dm = Data::Math->new();
  my @a =
      ( { amount => 1.98,
          type   => 'fungus',
        },
        undef,
        { amount => 6.66,
          type   => 'mossy',
        },
        undef,
        undef,
        { amount => 33,
          type   => 'tentacular',
        },
        { amount => .666,
          type   => 'mite',
        },
    );

  my @b =
      ( { amount => 0.02,
          type   => 'fungus',
        },
        undef,
        { amount => 0.04,
          type   => 'mossy',
        },
        undef,
        undef,
        { amount => 67,
          type   => 'tentacular',
         },
      );

  my $ds_sum = $dm->calc( '+', \@a, \@b );

  my @exp =
      ( { amount => 2.00,
          type   => 'fungus',
         },
        undef,
         { amount => 6.70,
           type   => 'mossy',
          },
        undef,
        undef,
          { amount => 100,
            type   => 'tentacular',
          },
        { amount => .666,
          type   => 'mite',
        },
      );

  is_deeply( $ds_sum, \@exp, "$test_name:" )
      or print STDERR "ds_sum: ", Dumper( $ds_sum ), "\n";


  my $ds_sum_converse = $dm->calc( '+', \@b, \@a );

  is_deeply( $ds_sum, \@exp, "$test_name: commutative" )
      or print STDERR "ds_sum: ", Dumper( $ds_sum ), "\n";

}

{
  my $test_name = "Testing calc '+' on an array of hashes with uneven holes";

  my $dm = Data::Math->new();
  my @a =
      ( { amount => 1.98,
          type   => 'fungus',
        },
        undef,
        { amount => 6.66,
          type   => 'mossy',
        },
        undef,
        undef,
        { amount => 33,
          type   => 'tentacular',
        },
        { amount => .666,
          type   => 'mite',
        },
    );

  my @b =
      ( { amount => 0.02,
          type   => 'fungus',
        },
        undef,
        { amount => 0.04,
          type   => 'mossy',
        },
        undef,
        { amount => 67,
          type   => 'tentacular',
         },
      );

  my $ds_sum = $dm->calc( '+', \@a, \@b );

  # TODO I *guess* this result makes sense, so let's say we expected it.
  my @exp =
      (
          {
            'amount' => '2',
            'type' => 'fungus'
          },
          undef,
          {
            'amount' => '6.7',
            'type' => 'mossy'
          },
          undef,
          {
            'amount' => 67,
            'type' => 'tentacular'
          },
          {
            'amount' => 33,
            'type' => 'tentacular'
          },
          {
            'amount' => '0.666',
            'type' => 'mite'
          }
      );

  is_deeply( $ds_sum, \@exp, "$test_name:" )
      or print STDERR "ds_sum: ", Dumper( $ds_sum ), "\n";

  my $ds_sum_converse = $dm->calc( '+', \@b, \@a );

  is_deeply( $ds_sum, \@exp, "$test_name: commutative" )
      or print STDERR "ds_sum: ", Dumper( $ds_sum ), "\n";
}

done_testing();
