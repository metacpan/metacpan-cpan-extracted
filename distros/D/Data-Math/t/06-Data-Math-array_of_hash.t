# Perl test file, can be run like so:
#   perl 03-Data-Math-array_of_hash.t
#         jbrenner@ffn.com     2014/09/15 21:17:44

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
  my $test_name = "Testing calc '+' on an array of hashes";

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
      );

  is_deeply( $ds_sum, \@exp, "$test_name" )
      or print STDERR "ds_sum: ", Dumper( $ds_sum ), "\n";

}

{
  my $test_name = "Testing calc '-' on an array of hashes";

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

  my $ds_sum = $dm->calc( '-', \@a, \@b );

  my @exp =
      ( { amount => 1.96,
          type   => 'fungus',
         },
         { amount => 6.62,
           type   => 'mossy',
          },
          { amount => -34,
            type   => 'tentacular',
          },
      );

  is_deeply( $ds_sum, \@exp, "$test_name" )
      or print STDERR "ds_sum: ", Dumper( $ds_sum ), "\n";

}

{
  my $test_name = "Testing calc '-' on aoh with string differences and unequal length";
  my $dm = Data::Math->new();
  my @a =
      ( { amount => 1.98,
          type   => 'fungal', },
        { amount => 6.66,
          type   => 'mossy', },
        { amount => 33,
          type   => 'tentacular', },
        { amount => 23,
          type   => 'lovecrafian', },
    );
  my @b =
      ( { amount => 0.02,
          type   => 'fungal', },
        { amount => 67,
          type   => 'tentacular', },
        { amount => 3000,
          type   => 'brennerist', },
      );

  my $ds_sum = $dm->calc( '-', \@a, \@b );

  my $exp =
      [ { 'amount' => '1.96',
          'type' => 'fungal'
          },
        { 'amount' => '-60.34',
          'type' => 'mossy|tentacular'
          },
        { 'amount' => -2967,
          'type' => 'tentacular|brennerist'
          },
        { 'amount' => 23,
          'type' => 'lovecrafian'
          }
       ];

  is_deeply( $ds_sum, $exp, "$test_name: 1st longer" )
      or print STDERR "ds_sum: ", Dumper( $ds_sum ), "\n";

  ### subtracting in the opposite direction, a from b:
  my $exp_2 =
      [ { 'amount' => '-1.96',
          'type' => 'fungal'
          },
        { 'amount' => '60.34',
          'type' => 'tentacular|mossy'
          },
        { 'amount' => 2967,
          'type' => 'brennerist|tentacular'
          },
        { 'amount' => -23,
          'type' => 'lovecrafian'
          }
      ];

  my $ds_sum_2 = $dm->calc( '-', \@b, \@a );
  # print "zzz: ", Dumper $ds_sum_2, "\n";

  is_deeply( $ds_sum_2, $exp_2, "$test_name: 2nd longer" )
      or print STDERR "ds_sum: ", Dumper( $ds_sum ), "\n";

}

{
  my $test_name = "Testing calc '+' on hashes of arrays";

  my $dm = Data::Math->new();
  my %a =
      (  last_year => [ 660, 771, 882, 993, 114, 225, 336, 447, 558, 669, 610, 611, ],
         this_year => [ 960, 971, 382, 393, 314, 325, 836, 847, 858, 169, 110, 111, ],
         whenever  => [ 560, 571, 582, 593, 514, 525, 536, 547, 558, 569, 510, 511, ],
     );


  my %b =
      (  last_year => [ 606, 717, 828, 939, 141, 252, 363, 474, 585, 696, 106, 116, ],
         this_year => [ 996, 197, 238, 339, 431, 532, 683, 784, 885, 916, 911, 111, ],
         whenever  => [ 660, 671, 682, 693, 614, 625, 636, 647, 658, 669, 610, 611, ],
     );


  my $ds_sum = $dm->calc( '+', \%a, \%b );
  # print STDERR "ds_sum: ", Dumper( $ds_sum ), "\n";

  my %exp =
      ( 'last_year' =>
           [ 1266, 1488, 1710, 1932, 255, 477, 699, 921, 1143, 1365, 716, 727 ],
        'whenever' =>
           [ 1220, 1242, 1264, 1286, 1128, 1150, 1172, 1194, 1216, 1238, 1120, 1122 ],
        'this_year' =>
           [ 1956, 1168, 620, 732, 745, 857, 1519, 1631, 1743, 1085, 1021, 222 ]
       );

  is_deeply( $ds_sum, \%exp, "$test_name: equal lengths" )
      or print STDERR "ds_sum: ", Dumper( $ds_sum ), "\n";

}

{ ### TODO NEXT
  my $test_name = "Testing calc '-' on an aoh with mismatched keys";

  my $dm = Data::Math->new();
  my @a =
      ( { amount  => 1.98,
          type    => 'fungus',
          freeman => 6,
        },
        { amount => 6.66,
          type   => 'mossy',
          froyo  => 'lychee',
        },
        { amount => 33,
          type   => 'tentacular',
          fracas => 'foothills',
        },
    );

  my @b =
      ( { amount => 0.02,
          type   => 'fungus',
          froyo  => 'lychee',
        },
        { amount => 0.04,
          type   => 'mossy',
          freeman => 6,
        },
        { amount => 67,
          type   => 'tentacular',
          fracas => 'foothills',
         },
      );

  my $ds_sum = $dm->calc( '-', \@a, \@b );

  my @exp =
      ( { amount => 1.96,
          type   => 'fungus',
          froyo  => 'lychee',
          freeman => 6,
         },
         { amount  => 6.62,
           type    => 'mossy',
           freeman => -6,
           froyo  => 'lychee',
          },
          { amount => -34,
            type   => 'tentacular',
            fracas => 'foothills',
          },
      );

  is_deeply( $ds_sum, \@exp, "$test_name" )
      or print STDERR "ds_sum: ", Dumper( $ds_sum ), "\n";

}




done_testing();


