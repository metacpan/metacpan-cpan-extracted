use strictures;
use Data::HAL qw();
use File::Slurp qw(read_file);
use Test::More import => [qw(done_testing is)];

is {Data::HAL->from_json(scalar read_file 't/example4.json')->http_headers}->{'Content-Type'},
  'application/hal+json; profile="http://example.com/shop/documentation"';
done_testing;
