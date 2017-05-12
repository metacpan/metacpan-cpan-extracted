#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Apache::Test qw(:withtestmore);
use Apache::TestRequest qw(POST POST_BODY);
use JSON::Syck;

our $TEST_COUNT = 10;

plan tests => $TEST_COUNT;

my $config   = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport($config) || '';
my $path = "/json-rpc-session";

# use cookies
Apache::TestRequest::user_agent(cookie_jar => {});

TODO: {
    local $TODO = "Sessions are currently a bit borked...";
    

SKIP: { 
    skip('Need CGI::Session and mod_perl2 to run',$TEST_COUNT) unless have_module('CGI::Session') && have_module('mod_perl2');

    {
        my $response = POST $path, [], 'Content-Type' => 'text/json';
        is(
            $response->code, 400,
            "POSTing without good JSON data results in bad request error"
        );
    }


    {
        my $request = {
            id      =>      1,
            method  =>      "fooze",
            params  =>      [ ],
        };
        my $response = POST_BODY $path, content => JSON::Syck::Dump($request),
            'Content-Type' => 'text/json';
        like($response, qr{\Q"error":"Can't call}, "Can't call a method without a package");
    }

    {
        my $request = {
            id      =>      1,
            method  =>      "new",
            params  =>      [ 'IO::File' ],
        };
        
        my $response = POST_BODY $path, content => JSON::Syck::Dump($request),
            'Content-Type' => 'text/json';
        like($response, qr{\Q"error":"Can't locate\E.*jsonrpc_new}, "Can't call a method in a non-jsonrpc package");
    }

    {
        my $request = {
            id      =>      1,
            method  =>      "foobar",
            params  =>      [ 'Count' ],
        };
        
        my $response = POST_BODY $path, content => JSON::Syck::Dump($request),
            'Content-Type' => 'text/json';
        like($response, qr{\Q"error":"Can't locate\E.*foobar}, "Can't call a non-existant method");
    }


    {
        my $request = {
            id      =>      1,
            method  =>      "increment",
            params  =>      [ 'Count' ],
        };
        
        my $response = POST_BODY $path, content => JSON::Syck::Dump($request),
            'Content-Type' => 'text/json';
        like($response, qr{"result":}, "Get a result: block back from a good method");
        my $data = (JSON::Syck::Load($response))[0];
        is_deeply($data, { id => 1, result => [ 1 ] }, "Get expected result from a good method");
    }
    {
        my $request = {
            id      =>      1,
            method  =>      "increment",
            params  =>      [ 'Count' ],
        };
        
        my $response = POST_BODY $path, content => JSON::Syck::Dump($request),
            'Content-Type' => 'text/json';
        like($response, qr{"result":}, "Get a result: block back from a good method");
        my $data = (JSON::Syck::Load($response))[0];
        is_deeply($data, { id => 1, result => [ 2 ] }, "Get expected result from a good method");
    }

    # make sure we can still marshall non cgi classes
    {
        my $request = {
            id      =>      1,
            method  =>      "who_am_i",
            params  =>      [ 'Hello' ],
        };
        
        my $response = POST_BODY $path, content => JSON::Syck::Dump($request),
            'Content-Type' => 'text/json';
        like($response, qr{"result":}, "Get a result: block back from a good method in a non Session aware class");
        my $data = (JSON::Syck::Load($response))[0];
        is_deeply($data, { id => 1, result => [ '127.0.0.1' ] }, "Get expected result from a good method in a non Session aware class");
    }


}



}
