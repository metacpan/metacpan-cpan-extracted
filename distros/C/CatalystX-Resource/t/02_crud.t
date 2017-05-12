#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use CatalystX::Resource::TestKit;
use Test::Exception;
use HTTP::Request::Common;
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
my $concert = $artist->concerts->create({
    location => 'Madison Cube Garden',
});

lives_ok(sub { $artist->albums->create({ id => 1, name => 'Mach et einfach!' }); }, 'create album');

# test / for no special reason
{
    my $path = '/';
    my $res = request($path);
    ok($res->is_success, "$path returns HTTP 200");
    like($res->decoded_content, '/TestApp/', "$path content contains string 'TestApp'");
}

# identifier_candidates
{
    my $path = '/artists/' . $artist->id . '/concerts/'. $concert->id .  '/edit';
    #my $res = request(POST $path);
    my $res = request(POST $path, [ location => 'Madison Square Garden' ]);
    ok($res->is_redirect, "$path returns HTTP 302");
    my $uri = URI->new($res->header('location'));
    is($uri->path, '/artists/' . $artist->id . '/concerts/list', 'redirect location is correct');
    my $cookie = $res->header('Set-Cookie');
    my $content = request(GET $uri->path, Cookie => $cookie)->decoded_content;
    like($content, '/Madison Square Garden updated/', 'check update success notification');
}

# SHOW
{
    my $path ='/artists/1/show';
    my $res = request($path);
    ok($res->is_success, "$path returns HTTP 200");
    like($res->decoded_content, '/davewood/', "$path content contains string 'davewood'");
    $path = '/artists/99/show';
    ok(request($path)->code == 404, "Unknown resource $path returns HTTP 404");
}

# LIST
{
    my $path ='/artists/list';
    my $res = request($path);
    ok($res->is_success, "Get $path");
    like($res->decoded_content, '/davewood[\s\S]*flipper/', "$path content contains 'davewood' and 'flipper'");
}

# DELETE
{
    my $path ='/artists/1/delete';
    my $res = request($path);
    ok($res->is_error, "delete with GET returns HTTP 404");
    $res = request(POST $path);
    ok($res->is_redirect, "$path returns HTTP 302");
    ok(request(POST $path)->code == 404, "Already deleted $path returns HTTP 404");
}

# CREATE
{
    my $path ='/artists/create';
    my $res = request($path);
    ok($res->is_success, "$path returns HTTP 200");
    like($res->decoded_content, '/method="post".*password/s', "$path content contains 'method=\"post\"'");
    $res = request(POST $path, [ name => 'simit', password => 'asdf', password_repeat => 'asdf' ]);
    ok($res->is_redirect, "$path returns HTTP 302");
    $path ='/artists/list';
    $res = request($path);
    like($res->decoded_content, '/simit/', "$path content contains 'simit'");
}

# EDIT
{
    my $path ='/artists/2/edit';
    my $res = request($path);
    ok($res->is_success, "$path returns HTTP 200");
    my $content = $res->decoded_content;
    like($content, '/method="post"/', "$path content contains 'method=\"post\"'");
    like($content, '/flipper/', "$path content contains 'flipper'");
    unlike($content, '/password/', "$path does not contain 'password'");
    $res = request(POST $path, [ name => 'willy' ]);
    ok($res->is_redirect, "$path returns HTTP 302");
    $path ='/artists/2/show';
    $res = request($path);
    like($res->decoded_content, '/willy/', "$path content contains 'willy'");
}

# and now for nested resources
# SHOW
{
    my $path ='/artists/2/albums/1/show';
    my $res = request($path);
    ok($res->is_success, "$path returns HTTP 200");
    like($res->decoded_content, '/Mach et einfach/', "$path content contains string 'Mach et einfach'");
    $path = '/artists/2/albums/99/show';
    ok(request($path)->code == 404, "Unknown resource $path returns HTTP 404");
}

# LIST
{
    my $path ='/artists/2/albums/list';
    my $res = request($path);
    ok($res->is_success, "Get $path");
    like($res->decoded_content, '/Mach et einfach/', "$path content contains 'Mach et einfach'");
}

# DELETE
{
    my $path ='/artists/2/albums/1/delete';
    my $res = request($path);
    ok($res->is_error, "delete with GET returns HTTP 404");
    $res = request(POST $path);
    ok($res->is_redirect, "$path returns HTTP 302");
    ok(request(POST $path)->code == 404, "Already deleted $path returns HTTP 404");
}

# CREATE
{
    my $path ='/artists/2/albums/create';
    my $res = request($path);
    ok($res->is_success, "$path returns HTTP 200");
    like($res->decoded_content, '/method="post"/', "$path content contains 'method=\"post\"'");
    $res = request(POST $path, [ name => 'I Brake Together' ]);
    ok($res->is_redirect, "$path returns HTTP 302");
    $path ='/artists/2/albums/list';
    $res = request($path);
    like($res->decoded_content, '/I Brake Together/', "$path content contains 'I Brake Together'");
}

# EDIT
{
    my $path ='/artists/2/albums/1/edit';
    my $res = request($path);
    ok($res->is_success, "$path returns HTTP 200");
    like($res->decoded_content, '/method="post"/', "$path content contains 'method=\"post\"'");
    like($res->decoded_content, '/I Brake Together/', "$path content contains 'I Brake Together'");
    $res = request(POST $path, [ name => 'Es gibt Reis, Baby' ]);
    ok($res->is_redirect, "$path returns HTTP 302");
    $path ='/artists/2/albums/1/show';
    $res = request($path);
    like($res->decoded_content, '/Es gibt Reis, Baby/', "$path content contains 'Es gibt Reis, Baby'");
}

done_testing;
