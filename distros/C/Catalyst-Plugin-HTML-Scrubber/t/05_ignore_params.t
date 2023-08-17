use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Catalyst::Test 'MyApp05';
use HTTP::Request::Common;
use HTTP::Status;
use Test::More;

{
    diag "Simple request with no params";
    my $req = GET('/');
    my ($res, $c) = ctx_request($req);
    ok($res->code == RC_OK, 'response ok');
    is($res->content, 'index', 'content ok');
}
{
    diag "Request wth one param, nothing to strip";
    my $req = POST('/', [foo => 'bar']);
    my ($res, $c) = ctx_request($req);
    ok($res->code == RC_OK, 'response ok');
    is($c->req->param('foo'), 'bar', 'parameter ok');
}
{
    diag "Request with XSS attempt gets stripped";
    my $req = POST('/', [foo => 'bar<script>alert("0");</script>']);
    my ($res, $c) = ctx_request($req);
    ok($res->code == RC_OK, 'response ok');
    is($c->req->param('foo'), 'bar', 'XSS was stripped');
}
{
    diag "HTML left alone in ignored field - by regex match";
    my $value = '<h1>Bar</h1><p>Foo</p>';
    my $req = POST('/', [foo_html => $value]);
    my ($res, $c) = ctx_request($req);
    ok($res->code == RC_OK, 'response ok');
    is($c->req->param('foo_html'), $value, 'HTML left alone in ignored field');
}
{
    diag "HTML left alone in ignored field - by name";
    my $value = '<h1>Bar</h1><p>Foo</p>';
    my $req = POST('/', [ignored_param => $value]);
    my ($res, $c) = ctx_request($req);
    ok($res->code == RC_OK, 'response ok');
    is($c->req->param('ignored_param'), $value, 'HTML left alone in ignored field');
}



done_testing();

