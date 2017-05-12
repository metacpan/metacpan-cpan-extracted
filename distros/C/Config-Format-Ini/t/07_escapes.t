use Test::More qw(no_plan);
use Config::Format::Ini;
use File::Slurp qw(slurp);

my $dir  = $ENV{PWD} =~ m#\/t$#  ? './data' : 't/data';


my $b1 = { person  => { name  => [  'johnny'             ],
                        full  => [   'E.	Walker'  ],
                      },
};
my $b2 = { person  => { first  => [  'johnn\\y'      ] ,
                        last   => [  'walke\\\\r'    ] ,
	              },
};

my $res;


$res =  read_ini <$dir/escape0>;
is_deeply( $res, $b1 )  ;

__END__
my $name = ${$b2->{person}{first}}[0] ;
$res =  read_ini <$dir/escape1>;
is_deeply( $res, $b2 )  ;
