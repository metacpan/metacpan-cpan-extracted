use strict;
use warnings;
use Test::More 0.96 import => ['!pass'];

use File::Temp 0.19; # newdir
use LWP::UserAgent;
use Test::TCP;

use Dancer ':syntax';
use Dancer::Plugin::Auth::Tiny;

test_tcp(
  client => sub {
    my $port = shift;
    my $url  = "http://localhost:$port/";

    my $ua = LWP::UserAgent->new( cookie_jar => {} );
    push @{ $ua->requests_redirectable }, 'POST';

    my $res = $ua->get( $url . "public" );
    like $res->content, qr/index/i, "GET /public works";

    $res = $ua->post( $url . "private", { foo => 'bar', user => 'Larry' } );
    like $res->content, qr/params:\s*$/i,
      "POST /private doesn't leak post params in redirect"
        or diag explain $res;

    $res = $ua->post( $url . "private", { foo => 'bar' } );
    like $res->content, qr/params: foo:bar/i,
      "POST /private after login has parameters";
  },

  server => sub {
    my $port = shift;

    set confdir     => '.';
    set port        => $port, startup_info => 0;
    set show_errors => 1;
    set session     => 'Simple';

    get '/public' => sub { return 'index' };

    any [qw/get post/] => '/private' => needs login =>
      sub { return "params: " . join( ":", params ) };

    get '/login' => sub {
      session "user" => params->{user};
      redirect params->{return_url}, 303;
    };

    get '/logout' => sub {
      session->destroy;
      redirect uri_for('/public');
    };

    Dancer->dance;
  },
);

done_testing;
#
# This file is part of Dancer-Plugin-Auth-Tiny
#
# This software is Copyright (c) 2012 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
