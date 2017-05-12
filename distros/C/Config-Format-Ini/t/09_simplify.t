use Test::More qw(no_plan);
use Config::Format::Ini;
use File::Slurp qw(slurp);

my $dir  = $ENV{PWD} =~ m#\/t$#  ? './data' : 't/data';

$Config::Format::Ini::SIMPLIFY = 1;

my $b0 = { 
	person => { name   => 'Little Anthony'  , 
                    genra  => 'Rhythm  &  Blues', 
	            lyrics => [ 'Now please' , 'please', 'please' ],
                  }
};

my $c0 = { 
	cars   => { fiat=> [qw/ green blue /],
		    bmw => [qw/ green blue /],
		    reno=> 'white',
                  },
	person => { john=> '38',
	            sun => [qw/ 99 100     /],
                  },
};
my $b1 = { 
	person => { name   => 'Little Anthony'  , 
                    genra  => undef,
	            lyrics => [ 'Now please' , 'please', 'please' ],
                  },
	empty  => undef
};

my $res ;

$res =  read_ini <$dir/basic2>;
is_deeply( $res, $b1)  ;

$res =  read_ini <$dir/tiny*>;
is_deeply( $res, $c0)  ;

$res =  read_ini <$dir/basic1>;
is_deeply( $res, $b0)  ;

