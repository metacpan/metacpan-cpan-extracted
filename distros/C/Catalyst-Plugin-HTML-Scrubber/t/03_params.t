use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Catalyst::Test 'MyApp03';
use HTTP::Request::Common;
use HTTP::Status;
use Test::More;

{
    my $req = GET('/');
    my ($res, $c) = ctx_request($req);
    is($res->code, RC_OK, 'response ok');
    is($res->content, 'index', 'content ok');
}
{
    my $req = POST('/', [foo => 'bar']);
    my ($res, $c) = ctx_request($req);
    is($res->code, RC_OK, 'response ok');
    is($c->req->param('foo'), 'bar', 'Normal POST body param, nothing to strip, left alone');
}
{
    my $req = POST('/', [foo => 'bar<script>alert("0");</script>']);
    my ($res, $c) = ctx_request($req);
    is($res->code, RC_OK, 'response ok');
    is($c->req->param('foo'), 'bar', 'XSS stripped from normal POST body param');
}
{
    # we allow <b> in the test app config so this should not be stripped
    my $req = POST('/', [foo => '<b>bar</b>']);
    my ($res, $c) = ctx_request($req);
    is($res->code, RC_OK, 'response ok');
    is($c->req->param('foo'), '<b>bar</b>', 'Allowed tag not stripped');
}
{
    diag "HTML left alone in ignored field - by regex match";
    my $value = '<h1>Bar</h1><p>Foo</p>';
    my $req = POST('/', [foo_html => $value]);
    my ($res, $c) = ctx_request($req);
    is($res->code, RC_OK, 'response ok');
    is(
        $c->req->param('foo_html'),
        $value,
        'HTML left alone in ignored (by regex) field',
    );
}
{
    diag "HTML left alone in ignored field - by name";
    my $value = '<h1>Bar</h1><p>Foo</p>';
    my $req = POST('/', [ignored_param => $value]);
    my ($res, $c) = ctx_request($req);
    is($res->code, RC_OK, 'response ok');
    is(
        $c->req->param('ignored_param'),
        $value,
        'HTML left alone in ignored (by name) field',
    );
}

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
    my $req = POST('/', 
        Content_Type => 'application/json', Content => $json_body
    );
    my ($res, $c) = ctx_request($req);
    is($res->code, RC_OK, 'response ok');
    is(
        $c->req->body_data->{foo}, 
        'Top-level ', # note trailing space where img was removed
        'Top level body param scrubbed',
    );
    is(
        $c->req->body_data->{baz}{one},
        'Second-level ',
        'Second level body param scrubbed',
    );
    is(
        $c->req->body_data->{arr}[0],
        'one test ',
        'Second level array contents scrubbbed',
    );
    is(
        $c->req->body_data->{some_html},
        'Leave <b>this</b> alone: <img src=allowed.gif>',
        'Body data param matching ignore_params left alone',
    );
}

{
    diag "HTML left alone for ignored path exact match";
    my $value = '<h1>Bar</h1><p>Foo</p>';
    my $req = POST('/exempt_path_name', [ foo => $value]);
    my ($res, $c) = ctx_request($req);
    is($res->code, RC_OK, 'response ok');
    is(
        $c->req->param('foo'),
        $value,
        'HTML left alone for ignored path (by name)',
    );
}

{
    diag "HTML left alone for ignored path - regex match";
    my $value = '<h1>Bar</h1><p>Foo</p>';
    my $req = POST('/all_exempt/foo', [ foo => $value]);
    my ($res, $c) = ctx_request($req);
    is($res->code, RC_OK, 'response ok');
    is(
        $c->req->param('foo'),
        $value,
        'HTML left alone for ignored path (by regex match)',
    );
}

# multi-part file upload testing - ensure that an uploaded file's contents are
# not fiddled with, and that we don't explode trying to process it 
# (e.g. by calling $c->req->body_data causing an exception because there's
# no data handler for this content type)
{
    my $content = "<p>File content, <b>with HTML</b> in it.</p>";
    diag "Uploaded file left alone, but other form fields still scrubbed";
    my $req = POST '/upload',
     Content_Type => 'form-data',
     Content      => [
         foo  => 'Form field <script>window.alert("with XSS!");</script>',
         myfile => [ 
             undef, "fake.file", 'Content-Type' => 'text/fake', Content => $content
         ],
    ];
    my ($res, $c) = ctx_request($req);
    is($res->code, RC_OK, 'response ok');
    is(
        $c->req->param('foo'),
        'Form field ',
        'XSS still stripped from normal POST body param in multi-part upload',
    );
    is(
        $c->req->upload('myfile')->slurp,
        "<p>File content, <b>with HTML</b> in it.</p>",,
        "File content left alone",
    );

}
{
    my $req = POST('/', [foo => '>= 3']);
    my ($res, $c) = ctx_request($req);
    is($res->code, RC_OK, 'response ok');
    is(
        $c->req->param('foo'),
        '&gt;= 3',
        'HTML entities are encoded by default',
    );

    # Now flip on no_encode_entities and check that HTML entities are
    # no longer encoded...
    MyApp03->config->{scrubber}{no_encode_entities}++;
    ($res, $c) = ctx_request($req);
    is($res->code, RC_OK, 'response ok');
    is(
        $c->req->param('foo'), 
        '>= 3',
        'no_encode_entities works - no HTML entity encoding',
    );
}



done_testing();

