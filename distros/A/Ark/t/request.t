use strict;
use warnings;
use utf8;
use Encode;
use Test::More;
BEGIN { use_ok 'Ark::Request' }

my $query = 'foo=%E3%81%BB%E3%81%92&bar=%E3%81%B5%E3%81%8C1&bar=%E3%81%B5%E3%81%8C2';
my $host  = 'example.com';
my $path  = '/hoge/fuga';

my $req = Ark::Request->new({
    QUERY_STRING   => $query,
    REQUEST_METHOD => 'GET',
    HTTP_HOST      => $host,
    PATH_INFO      => $path,
});

isa_ok $req, 'Ark::Request';

subtest 'uri' => sub {
    my $uri = $req->uri;
    isa_ok $uri, 'URI';
    is $uri.'', "http://$host$path?$query";

    my $base = $req->base;
    isa_ok $base, 'URI';
    is $base.'', "http://$host/";
};

done_testing;
