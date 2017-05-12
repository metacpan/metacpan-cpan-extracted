use Data::Transform::SSL;
use Scalar::Util qw(blessed);

use Test::More;

plan tests => 5;

my $client = Data::Transform::SSL->new;

my $data = ["this line has to reach the other end"];
pass("sending data to the server");
my $client_data = $client->put($data);
is(@$client_data, 1, "... got a single chunk of data from the filter");

pass("pretend to have gotten garbage back");
$client->get_one_start(['garbage']);
$client_data = $client->get_one;
isa_ok($client_data->[0], 'Data::Transform::Meta::Error', "... gives an error");
like($client_data->[0]->data, qr/unknown protocol/, "... and it is the expected one");
