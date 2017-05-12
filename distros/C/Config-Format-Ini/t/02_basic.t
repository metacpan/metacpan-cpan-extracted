use Test::More qw(no_plan);
use Config::Format::Ini;
use File::Slurp qw(slurp);

my $dir  = $ENV{PWD} =~ m#\/t$#  ? './data' : 't/data';

my $b0 = { 
	person => { name   => [ 'Little Anthony'                  ],
                    genra  => [ 'Rhythm  &  Blues'                ],
	            lyrics => [ 'Now please' , 'please', 'please' ],
                  }
};

my $c0 = { 
	cars   => { fiat=> [qw/ green blue /],
		    bmw => [qw/ green blue /],
		    reno=> [qw/ white      /],
                  },
	person => { john=> [qw/ 38         /],
	            sun => [qw/ 99 100     /],
                  },
};

my $c1 = { 
	cars   => { fiat=> [qw/ green blue /],
		    bmw => [qw/ green blue /],
		    reno=> [qw/ white      /],
                  },
};
my $c2 = {
	person => { john=> [qw/ 38         /],
	            sun => [qw/ 99 100     /],
                  },
};
my $res ;

$res =  read_ini <$dir/tiny*>;
is_deeply( $res, $c0)  ;

$res =  read_ini <$dir/basic1>;
is_deeply( $res, $b0)  ;

$res =  read_ini <$dir/tiny1>;
is_deeply( $res, $c1)  ;


$res =  read_ini <$dir/tiny2>;
is_deeply( $res, $c2)  ;
