use Test::More qw(no_plan);
use Config::Format::Ini;
use File::Slurp qw(slurp);

my $dir  = $ENV{PWD} =~ m#\/t$#  ? './data' : 't/data';

my $b0 = { person    => { first   => [ 'johnny'], 
                          last    => [ 'walker'], },
           song      => { elvis   => [ 'Cruel' ], }
 }; 

my $b2 = { person  => { name    => [ 'The King'       ],
                        lyrics  => [ 'Cruel'          ],
	              },
           cars    => { reno    => [ 'white'          ], },
           jukebox => { last    => [ 'The King'       ], },
};

my $b1 = { person  => { age    => [  40       ], },
           song    => { young  => [  'stars'  ], },
};

my $res;

$res =  read_ini <$dir/r4>;
is_deeply( $res, $b1 )  ;

$res =  read_ini <$dir/r0>;
is_deeply( $res, $b0 )  ;

$res =  read_ini <$dir/r1>;
is_deeply( $res, $b0 )  ;
$res =  read_ini <$dir/r2>;
is_deeply( $res, $b0 )  ;

$res =  read_ini <$dir/resync3>;
is_deeply( $res, $b1 )  ;

$res =  read_ini <$dir/resync2>;
is_deeply( $res, $b2 )  ;

