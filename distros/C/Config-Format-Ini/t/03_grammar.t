use Test::More qw(no_plan);
#use Config::Format::Ini;
use Config::Format::Ini::Grammar;
use File::Slurp qw(slurp);

my $dir  = $ENV{PWD} =~ m#\/t$#  ? './data' : 't/data';

my $c1 = { 
	cars   => { fiat=> [qw/ green blue/],
		    reno=> [qw/ white     /],
                  },
	person => { john=> [qw/ 38        /],
	            sun => [qw/ 99 100    /],
                  },
};
my $count = { sea=>{},  cars=>{ fiat=>[qw//], reno=>[qw/white/] } };
my $quot1 = { cars=>{ fiat=>[ 'light blue', 'red'           ], 
	              reno=>[ 'light, blue, and gold', 'red'],
	              bmw =>[ 'light, blue'                 ],
	              other =>[ ''                          ],
}};


my $p = new Config::Format::Ini::Grammar;
is_deeply( $p->startrule($_), $quot1)  for map{ scalar slurp $_} <$dir/quote*>;

$p = new Config::Format::Ini::Grammar;
is_deeply( $p->startrule($_), $count)  for map{ scalar slurp $_} <data/count*>;

$p = new Config::Format::Ini::Grammar;
is_deeply( $p->startrule($_), $c1)   for map{ scalar slurp $_ } <data/test*>;

