use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Test::More;


eval 'use Catalyst::Controller::REST';
plan skip_all => 'Catalyst::Controller::REST not available, skip REST tests' if $@;

use Catalyst::Test 'MyApp05';
use HTTP::Request::Common;
use HTTP::Status;

{
    # Test that data in a JSON body POSTed gets scrubbed too
    my $json_body = <<JSON;
{
    "foo": "Top-level <img src=foo.jpg title=fun>", 
    "baz":{
        "one":"Second-level <img src=test.jpg>"
    },
    "arr": [ 
        "one test <img src=arrtest1.jpg>",
        "two <script>window.alert('XSS!');</script>"
    ],
    "some_html": "Leave <b>this</b> alone: <img src=allowed.gif>"
}
JSON
    my $req = POST('/foo', 
        Content_Type => 'application/json', Content => $json_body
    );
    my ($res, $c) = ctx_request($req);
    is($res->code, RC_OK, 'response ok');
    is(
        $c->req->data->{foo}, 
        'Top-level ', # note trailing space where img was removed
        'Top level body param scrubbed',
    );
    is(
        $c->req->data->{baz}{one},
        'Second-level ',
        'Second level body param scrubbed',
    );
    is(
        $c->req->data->{arr}[0],
        'one test ',
        'Second level array contents scrubbbed',
    );
    is(
        $c->req->data->{some_html},
        'Leave <b>this</b> alone: <img src=allowed.gif>',
        'Body data param matching ignore_params left alone',
    );
}

done_testing();

