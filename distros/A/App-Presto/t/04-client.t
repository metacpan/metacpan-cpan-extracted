use strict;
use warnings;
use Test::More;
use Test::MockObject;
use App::Presto::Client;

my $config = Test::MockObject->new;
$config->set_always( endpoint => 'http://my-server.com');
my $rest_client = Test::MockObject->new;
$rest_client->set_true('GET','DELETE','PUT','POST','HEAD','request');

my %headers;
$rest_client->mock('addHeader', sub { shift; my($k,$v) = @_; $headers{$k} = $v; });
$rest_client->{_headers} = \%headers;

my $client = App::Presto::Client->new(config=>$config, _rest_client => $rest_client);

isa_ok($client, 'App::Presto::Client');

$client->GET('/foo');
{
	my ( $m, $args ) = $rest_client->next_call;
	is $m, 'GET', 'rest_client GET';
	is $args->[1], 'http://my-server.com/foo', 'constructs correct URI';
}

$client->DELETE('http://another-server.com/blah');
{
	my ( $m, $args ) = $rest_client->next_call;
	is $m, 'request', 'rest_client request';
	is $args->[2], 'http://another-server.com/blah', 'allows URI override';
}

$client->PUT('/bar', 'foobar');
{
	my ( $m, $args ) = $rest_client->next_call;
	is $m, 'PUT', 'rest_client PUT';
	is $args->[2], 'foobar', 'PUT body';
}

$config->set_always( endpoint => 'http://my-server.com*.json');
$client->PUT('/bar?blah=1', 'foobar');
{
	my ( $m, $args ) = $rest_client->next_call;
	is $m, 'PUT', 'rest_client PUT';
	is $args->[1], 'http://my-server.com/bar.json?blah=1', 'has suffix + query params';
}
$config->set_always( endpoint => 'http://my-server.com');

$client->HEAD;
{
	my ( $m, $args ) = $rest_client->next_call;
	is $m, 'HEAD', 'rest_client HEAD (no uri)';
	is $args->[1], 'http://my-server.com/', 'default URI';
}

$client->POST('/foo', q({"a":1}));
{
	my ( $m, $args ) = $rest_client->next_call;
	is $m, 'POST', 'rest_client POST';
	is $args->[1], 'http://my-server.com/foo', 'POST URI';
	is $args->[2], '{"a":1}', 'POST body';
}

$client->GET('/foo', 'a=1', 'b=2,3', 'a=4');
{
	my ( $m, $args ) = $rest_client->next_call;
	is $m, 'GET', 'rest_client GET with params';
	is $args->[1], 'http://my-server.com/foo?a=1&b=2%2C3&a=4', 'constructs correct URI with params';
}

$client->set_header(foo => 'bar');
is_deeply {$client->all_headers}, {foo => 'bar'}, 'set_header';
is $client->get_header('foo'), 'bar', 'get_header';
$client->clear_headers;
is_deeply {$client->all_headers}, {}, 'clear_headers';

done_testing;
