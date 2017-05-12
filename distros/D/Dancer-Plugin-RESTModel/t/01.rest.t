use Test::More tests => 5;
use Dancer::Plugin::RESTModel;

my $client = Dancer::Plugin::RESTModel->new(
    server => 'http://localhost:5000',
    type   => 'application/json',
);

ok $client, 'Created REST client instance';
isa_ok $client => 'Dancer::Plugin::RESTModel';
can_ok $client, qw( get post put delete options head );
ok my $res = $client->get('/test'), 'get OK';
isa_ok $res, 'Role::REST::Client::Response';
