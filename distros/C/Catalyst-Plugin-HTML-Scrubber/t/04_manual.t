use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Catalyst::Test 'MyApp04';
use HTTP::Request::Common;
use HTTP::Status;
use Test::More;

{
    my $req = GET('/');
    my ($res, $c) = ctx_request($req);
    ok($res->code == RC_OK, 'response ok');
    is($res->content, 'index', 'content ok');
}

{
    my $req = POST('/', [foo => 'bar']);
    my ($res, $c) = ctx_request($req);
    ok($res->code == RC_OK, 'response ok');
    is($c->req->param('foo'), 'bar', 'parameter ok');
}

{
    my $req = POST('/', [foo => 'bar<script>alert("0");</script>']);
    my ($res, $c) = ctx_request($req);
    ok($res->code == RC_OK, 'response ok');
    is($c->req->param('foo'), 'bar<script>alert("0");</script>', 'scrub ok');
}

{
    my $req = POST('/', [foo => 'bar<br />']);
    my ($res, $c) = ctx_request($req);
    ok($res->code == RC_OK, 'response ok');
    is($c->req->param('foo'), 'bar<br />', 'scrub ok');
}

{
    my $req = POST('/scrub', [foo => 'bar<script>alert("0");</script>']);
    my ($res, $c) = ctx_request($req);
    ok($res->code == RC_OK, 'response ok');
    is($c->req->param('foo'), 'bar', 'scrub ok');
}

{
    my $req = POST('/scrub', [foo => '<b>bar</b>']);
    my ($res, $c) = ctx_request($req);
    ok($res->code == RC_OK, 'response ok');
    is($c->req->param('foo'), '<b>bar</b>', 'scrub ok');
}

done_testing();

