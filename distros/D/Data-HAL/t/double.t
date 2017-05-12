use strictures;
use Test::More import => [qw(done_testing is)];
use Data::HAL qw();
use File::Slurp qw(read_file);

my $hal = Data::HAL->from_json(scalar read_file 't/example.json');
my $json1 = $hal->as_json;
my $json2 = $hal->as_json;
is $json2, $json1;

done_testing;
