use strict;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Catmandu::Store::Hash;
use Catmandu::Plack::unAPI;

my $store = Catmandu::Store::Hash->new();
$store->add({_id => 42, foo => 'bar'});

my $app = Catmandu::Plack::unAPI->new( store => $store );

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->(GET "?id=42&format=json");
    is $res->code, 200, '200 Ok';
    like $res->content, qr/^\{.+42/sm, 'get via store';
};

$app = Catmandu::Plack::unAPI->new( store => 'Hash' );
isa_ok $app->store, 'Catmandu::Store::Hash';

done_testing;
