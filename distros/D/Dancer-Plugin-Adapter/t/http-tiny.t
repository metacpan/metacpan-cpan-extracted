use strict;
use warnings;
use Test::More 0.96 import => ['!pass'];

use HTTP::Tiny;
use Test::TCP;

HTTP::Tiny->new->get("http://google.com/")->{success}
  or plan skip_all => "google.com not available";

use Dancer ':syntax';
use Dancer::Plugin::Adapter;

test_tcp(
  client => sub {
    my $port = shift;
    my $ua  = HTTP::Tiny->new;
    my $res = $ua->get("http://localhost:$port/proxy");
    ok( $res->{success}, "Request success" );
    like $res->{content}, qr/google/i, "HTTP::Tiny got proxy response";
  },
  server => sub {
    my $port = shift;

    set confdir => '.';
    set port => $port, startup_info => 0;

    set show_errors => 1;

    set plugins => {
      Adapter => {
        http => {
          class   => 'HTTP::Tiny',
          options => { max_redirect => 10 },
        },
      },
    };

    get '/' => sub {
      diag "in /";
      return "Hello World";
    };

    get '/proxy' => sub {
      my $response = service("http")->get("http://google.com/");
      return $response->{content};
    };

    Dancer->dance;
  },
);

done_testing;
#
# This file is part of Dancer-Plugin-Adapter
#
# This software is Copyright (c) 2012 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
