#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

# XS module load failure fatal in eval block -> eval string
eval "use YAML::XS; 1" or plan skip_all => "YAML::XS needed for this test";

package MyApp;

use Dancer2;
use Dancer2::Plugin::Swagger2;

set serializer => 'JSON';

sub invalid { { key => 'value' } }

sub valid { ['array'] }

swagger2( url => Mojo::URL->new("data://main/myApp.yaml") );

package main;

use HTTP::Request::Common;
use Plack::Test;

plan tests => 5;

my $app  = MyApp->to_app;
my $test = Plack::Test->create($app);

subtest "mssing optional parameter" => sub {
    local $TODO = "allow optional parameter missing";

    my $res = $test->request( GET '/valid' );
    is $res->code    => 200;
    is $res->content => q(["array"]);
};

subtest "successful request" => sub {
    my $res = $test->request( GET '/valid?param=foo' );
    is $res->code    => 200;
    is $res->content => q(["array"]);
};

subtest "invalid request" => sub {
    my $res = $test->request( GET '/valid?param=' );
    is $res->code      => 400;
    like $res->content => qr/^\{"errors":\["/;
};

subtest "invalid request 2" => sub {
    local $TODO = "validation of unknown parameters";

    my $res = $test->request( GET '/valid?invalid=param' );
    is $res->code    => 400;
    is $res->content => "";
};

subtest "invalid response" => sub {
    my $res = $test->request( GET '/invalid' );
    is $res->code      => 500;
    like $res->content => qr/^\{"errors":\["/;
};

__DATA__
@@ myApp.yaml
---
swagger: "2.0"
info:
  title: Example API
  version: "1.0"
paths:
  /valid:
    get:
      operationId: valid
      parameters:
      - name: param
        in: query
        type: string
        minLength: 1
      responses:
        200:
          description: success
          schema:
            "$ref": "#/definitions/MyResponse"
  /invalid:
    get:
      operationId: invalid
      responses:
        200:
          description: success
          schema:
            "$ref": "#/definitions/MyResponse"
definitions:
  MyResponse:
    type: array
    items:
      type: string
