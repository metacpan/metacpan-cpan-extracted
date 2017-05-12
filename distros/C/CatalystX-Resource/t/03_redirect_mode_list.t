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

# populate DB
$schema->resultset('Resource::Artist')->create({
    id => 1,
    name => 'davewood',
    password => 'asdf',
});
my $artist = $schema->resultset('Resource::Artist')->create({
    id => 2,
    name => 'flipper',
    password => 'asdf',
});
lives_ok(sub { $artist->albums->create({ id => 1, name => 'Mach et einfach!' }); }, 'create album');

# check redirection for redirect_mode = 'list'
# DELETE
{
    my $path ='/artists/1/delete';
    my $res = request(POST $path);
    ok($res->is_redirect, "$path returns HTTP 302");
    my $uri = URI->new($res->header('location'));
    is($uri->path, '/artists/list', 'redirect location is correct');
    my $cookie = $res->header('Set-Cookie');
    my $content = request(GET $uri->path, Cookie => $cookie)->decoded_content;
    unlike($content, '/>davewood<\/a>/', 'resource has been deleted');
    like($content, '/davewood deleted/', 'check delete success notification');
    ok(request(POST $path)->code == 404, "Already deleted $path returns HTTP 404");
}

# CREATE
{
    my $path ='/artists/create';
    my $res = request($path);
    ok($res->is_success, "$path returns HTTP 200");
    like($res->decoded_content, '/method="post"/', "$path content contains 'method=\"post\"'");
    $res = request(POST $path, [ name => 'simit', password => 'asdf', password_repeat => 'asdf' ]);
    ok($res->is_redirect, "$path returns HTTP 302");
    my $uri = URI->new($res->header('location'));
    is($uri->path, '/artists/list', 'redirect location is correct');
    my $cookie = $res->header('Set-Cookie');
    my $content = request(GET $uri->path, Cookie => $cookie)->decoded_content;
    like($content, '/>simit<\/a>/', 'resource has been created');
    like($content, '/simit created/', 'check create success notification');
}

# EDIT
{
    my $path ='/artists/2/edit';
    my $res = request($path);
    ok($res->is_success, "$path returns HTTP 200");
    like($res->decoded_content, '/method="post"/', "$path content contains 'method=\"post\"'");
    $res = request(POST $path, [ name => 'foobar' ]);
    ok($res->is_redirect, "$path returns HTTP 302");
    my $uri = URI->new($res->header('location'));
    is($uri->path, '/artists/list', 'redirect location is correct');
    my $cookie = $res->header('Set-Cookie');
    my $content = request(GET $uri->path, Cookie => $cookie)->decoded_content;
    like($content, '/>foobar<\/a>/', 'resource has been edited');
    like($content, '/foobar updated/', 'check edit success notification');
}

# for nested resources
# CREATE
{
    my $path ='/artists/2/albums/create';
    my $res = request($path);
    ok($res->is_success, "$path returns HTTP 200");
    like($res->decoded_content, '/method="post"/', "$path content contains 'method=\"post\"'");
    $res = request(POST $path, [ name => 'I Brake Together' ]);
    ok($res->is_redirect, "$path returns HTTP 302");
    my $uri = URI->new($res->header('location'));
    is($uri->path, '/artists/2/albums/list', 'redirect location is correct');
    my $cookie = $res->header('Set-Cookie');
    my $content = request(GET $uri->path, Cookie => $cookie)->decoded_content;
    like($content, '/>I Brake Together<\/a>/', 'resource has been created');
    like($content, '/I Brake Together created/', 'check create success notification');
}

# EDIT
{
    my $path ='/artists/2/albums/2/edit';
    my $res = request($path);
    ok($res->is_success, "$path returns HTTP 200");
    like($res->decoded_content, '/method="post"/', "$path content contains 'method=\"post\"'");
    $res = request(POST $path, [ name => 'Es gibt Reis, Baby' ]);
    ok($res->is_redirect, "$path returns HTTP 302");
    my $uri = URI->new($res->header('location'));
    is($uri->path, '/artists/2/albums/list', 'redirect location is correct');
    my $cookie = $res->header('Set-Cookie');
    my $content = request(GET $uri->path, Cookie => $cookie)->decoded_content;
    like($content, '/>Es gibt Reis, Baby<\/a>/', 'resource has been edited');
    like($content, '/Es gibt Reis, Baby updated/', 'check edit success notification');
}

# DELETE
{
    my $path ='/artists/2/albums/2/delete';
    my $res = request(POST $path);
    ok($res->is_redirect, "$path returns HTTP 302");
    my $uri = URI->new($res->header('location'));
    is($uri->path, '/artists/2/albums/list', 'redirect location is correct');
    my $cookie = $res->header('Set-Cookie');
    my $content = request(GET $uri->path, Cookie => $cookie)->decoded_content;
    unlike($content, '/>Es gibt Reis, Baby<\/a>/', 'resource has been deleted');
    like($content, '/Es gibt Reis, Baby deleted/', 'check delete success notification');
    ok(request(POST $path)->code == 404, "Already deleted $path returns HTTP 404");
}

done_testing;
