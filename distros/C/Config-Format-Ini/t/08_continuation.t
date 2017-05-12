use Test::More qw(no_plan);
use Config::Format::Ini;
use File::Slurp qw(slurp);

my $dir  = $ENV{PWD} =~ m#\/t$#  ? './data' : 't/data';

my $b0 = { person    => { name   => [ 'Johnny Walker'], 
                          title    => [ 'Sr.'], },
 }; 
my $b1 = { person    => { name   => [ 'Johnny Walker', 'John', 'JW'], 
                          title    => [ 'Sr.'], },
}; 


my $res;

$res =  read_ini <$dir/contin1>;
is_deeply( $res, $b0 )  ;
$res =  read_ini <$dir/contin2>;
is_deeply( $res, $b1 )  ;
$res =  read_ini <$dir/contin3>;
is_deeply( $res, $b1 )  ;

