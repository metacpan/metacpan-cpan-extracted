#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

# XS module load failure fatal in eval block -> eval string
eval "use YAML::XS; 1" or plan skip_all => "YAML::XS needed for this test";

plan tests => 3;

package MyApp::Controller::Foo;

sub bar { "Hello_World!" }

package MyApp;

use Dancer2;
use Dancer2::Plugin::Swagger2;

swagger2( url => "data://main/swagger2.yaml" );

package main;

use HTTP::Request::Common;
use Plack::Test;

ok( my $app = MyApp->to_app );
my $test = Plack::Test->create($app);

my $res = $test->request( GET '/api/welcome' );
like $res->content => qr/hello.+world/i;
is $res->code      => 200;

__DATA__
@@ swagger2.yaml
---
swagger: "2.0"
info:
  title: Example API
  version: "1.0"
basePath: /api
paths:
  /welcome:
    get:
      operationId: Foo::bar
      responses:
        200:
          description: success
