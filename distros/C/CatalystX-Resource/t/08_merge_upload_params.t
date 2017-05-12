#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use CatalystX::Resource::TestKit;
use Test::Exception;
use HTTP::Request::Common;
use URI;

use Catalyst::Test qw/TestApp/;

my ($res, $c) = ctx_request('/');
my $schema = $c->model('DB')->schema;

ok(defined $schema, 'got a schema');
lives_ok(sub { $schema->deploy }, 'deploy schema');

{
    my $path = '/artists/create';

    my ($res, $c);
    $res = request($path);
    ok($res->is_success, "GET $path returns HTTP 200");
    like($res->content, '/form.*Picture/s', 'GET requests returns a form');

    ($res, $c) = ctx_request(
        POST 
            $path,
            Content_Type => 'form-data',
            Content => [
                        name => 'simit',
                        password => 'asdf',
                        password_repeat => 'asdf',
                        picture => [ "$Bin/lib/TestApp.pm" ], # a file upload
                       ]
    );
    ok($res->is_redirect, "POST $path returns HTTP 302");
    my $uri = URI->new($res->header('location'));
    is($uri->path, '/artists/list', "redirect to '/artists/list'");
    is(ref $c->req->params->{picture}, 'Catalyst::Request::Upload', 'upload params are merged into req params');
}

done_testing;
