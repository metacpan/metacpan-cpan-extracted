use Test::More qw(no_plan);
use Config::Format::Ini;
use File::Slurp qw(slurp);

my $dir  = $ENV{PWD} =~ m#\/t$#  ? './data' : 't/data';

my $b0 = { 
	cars => { reno  => [qw/  white       /],
                  bmw   => [qw/  white       /],
                  fiat  => [qw/  blue  green /],
                  ford  => [qw/  blue  green /],
                  mini  => [qw/              /],
                }
};
my $b1 = { cars =>{}, person =>{} , vin=>{} };
my $res ;

$res =  read_ini <$dir/comments2>;
is_deeply( $res, $b1 )  ;

$res =  read_ini <$dir/comments1>;
is_deeply( $res, $b0, 'comments')  ;



