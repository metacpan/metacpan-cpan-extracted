#!perl

my $have_PDL;
my $ntests;
BEGIN {
    $have_PDL = eval 'use PDL qw(); 1;';

    $ntests = $have_PDL ? 144 : 80;
}


use Test::More tests => $ntests;



#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Astro::QDP::Parse ':all';
use List::Util qw( max );

chdir 'data';


my %check =
  (
   'foobish.qdp' =>  {

                      hdg => 2,
                      vdg => 6,
                      nelem => [ 62, 62, 64, 65, 201, 178 ],

                      validate => [
                                   # first and last lines of first vertical group
                                   [ qw( 0 x data  0 0.32249999     ) ],
				   [ qw( 0 x err   0 0.00750000775  ) ],
				   [ qw( 0 y data  0 0.88324523     ) ],
				   [ qw( 0 y err   0 0.0564284697   ) ],
				   [ qw( 1 y data  0 0.893682718    ) ],

				   [ qw( 0 x data 61 6.19500017     ) ],
                                   [ qw( 0 x err  61 0.315000057    ) ],
                                   [ qw( 0 y data 61 0.00429176865  ) ],
                                   [ qw( 0 y err  61 0.000606947753 ) ],
                                   [ qw( 1 y data 61 0.00357131264  ) ],


                                   # first and last lines of last vertical group
                                   [ qw( 10 x data   0 0.306535482   ) ],
                                   [ qw( 10 x err    0 0.00262950361 ) ],
                                   [ qw( 10 y data   0 0.167014718   ) ],
                                   [ qw( 10 y err    0 0.0348249786  ) ],
                                   [ qw( 11 y data   0 0.129219562   ) ],

                                   [ qw( 10 x data 177 6.93999958    ) ],
                                   [ qw( 10 x err  177 0.0499999523  ) ],
                                   [ qw( 10 y data 177 0.00801955629 ) ],
                                   [ qw( 10 y err  177 0.00175001065 ) ],
                                   [ qw( 11 y data 177 0.0116647892  ) ],
                                  ],
                     },

   'goobish.qdp' => {
                     hdg => 1,
                     vdg => 4,
                     nelem => [ 8, 1, 9, 5 ],

                     validate => [
                                   # first and last lines of first vertical group
                                   [ qw( 0 x data  0  0.3   ) ],
				   [ qw( 0 x err   0  0.001 ) ],
				   [ qw( 0 y data  0  0.8   ) ],
				   [ qw( 0 y elo  0  0.14  ) ],
				   [ qw( 0 y ehi  0 -0.11  ) ],

				   [ qw( 0 x data  7  1.01  ) ],
                                   [ qw( 0 x err   7  0.008 ) ],
                                   [ qw( 0 y data  7  7.8   ) ],
                                   [ qw( 0 y elo  7  0.84  ) ],
                                   [ qw( 0 y ehi  7 -0.18  ) ],

                                   # first and last lines of last vertical group
                                   [ qw( 3 x data  0  0.3   ) ],
                                   [ qw( 3 x err   0  0.001 ) ],
                                   [ qw( 3 y data  0  0.8   ) ],
                                   [ qw( 3 y elo  0  0.14  ) ],
                                   [ qw( 3 y ehi  0 -0.11  ) ],

                                   [ qw( 3 x data  4  0.7   ) ],
                                   [ qw( 3 x err   4  0.005 ) ],
                                   [ qw( 3 y data  4  4.8   ) ],
                                   [ qw( 3 y elo  4  0.54  ) ],
                                   [ qw( 3 y ehi  4 -0.15  ) ],
                                  ],
                    },

   'nopu1.qdp' => {
                   hdg => 3,
                   vdg => 1,
                   nelem => [ 1000 ],


                     validate => [
                                   [ qw( 0 x data   0 0.300526887    ) ],
				   [ qw( 0 x err    0 0.00052690506  ) ],
				   [ qw( 0 y data   0 0.00323150633  ) ],
				   [ qw( 1 y data   0 0.000613998622 ) ],
				   [ qw( 2 y data   0 0.00261750771  ) ],

				   [ qw( 0 x data 999 9.98249817     ) ],
                                   [ qw( 0 x err  999 0.0175013542   ) ],
                                   [ qw( 0 y data 999 1.28469296e-07  ) ],
                                   [ qw( 1 y data 999 1.15185236e-19 ) ],
                                   [ qw( 2 y data 999 1.28469296e-07  ) ],

                                  ],
                  },

   'phvavn1.qdp' => {
                   hdg => 3,
                   vdg => 1,
                   nelem => [ 63 ],

                     validate => [
                                   [ qw( 0 x data   0 0.211699992   ) ],
				   [ qw( 0 x err    0 0.00729999691 ) ],
				   [ qw( 0 y data   0 0.847264409   ) ],
				   [ qw( 0 y err    0 0.00455949642 ) ],
				   [ qw( 1 y data   0 1.01259172    ) ],
				   [ qw( 2 y data   0 -36.2599945   ) ],
				   [ qw( 2 y err    0 1             ) ],

				   [ qw( 0 x data  62 2.91269994     ) ],
                                   [ qw( 0 x err   62 0.0657000542   ) ],
                                   [ qw( 0 y data  62 -5.22391474E-6 ) ],
                                   [ qw( 0 y err   62 6.65455591E-5  ) ],
                                   [ qw( 1 y data  62 7.86789315E-6  ) ],
                                   [ qw( 2 y data  62 -0.196734503   ) ],
                                   [ qw( 2 y err   62 1              ) ],
                                  ],
                  },

);


while( my ( $file, $check ) = each %check )
{

    die "Can't read qdpfile >$file<"
      unless -e $file;

    my ($data, $hdr ) = parse_qdpfile( $file );

    # read in the correct number of groups
    is ( (max map { $_->{y}{hdg} } @$data ), $check->{hdg}, "$file: no. horizontal groupings" );
    is ( (max map { $_->{x}{vdg} } @$data )+1, $check->{vdg}, "$file: no. vertical groupings" );
    is( scalar @$data, $check->{hdg} * $check->{vdg}, "$file: no. groups" );

    # read in the correct number of elements in a horizontal group
    ok( eq_array( [ map { scalar @{$data->[$_]{x}{data}} }
                          map { $_ * $check->{hdg} }
                                  0..$check->{vdg}-1
                  ],
                  $check->{nelem}
                ),
        "$file: no. elements in groups"
      );

    for my $vd ( @{ $check->{validate} } )
    {
        my ( $group, $vec, $comp, $idx, $exp ) = @$vd;

        is( $data->[$group]{$vec}{$comp}[$idx] + 0, $exp + 0,
            "$file: $group $vec $comp $idx" );
    }

    if ( $have_PDL )
    {
        my ( $data ) = parse_qdpfile( $file, { as_pdl => 1 } );
        for my $vd ( @{ $check->{validate} } )
        {
            my ( $group, $vec, $comp, $idx, $exp ) = @$vd;

            is( $data->[$group]{$vec}{$comp}->at($idx) + 0, $exp + 0,
                "$file: pdl: $group $vec $comp $idx" );
        }
    }
}



