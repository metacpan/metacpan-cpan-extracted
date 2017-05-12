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

    my $res = $ua->get( $url . "public" );
    like $res->content, qr/index/i, "GET /public works";

    $res = $ua->get( $url . "private" );
    like $res->content, qr/login/i, "GET /private redirects to login";
    like $res->content, qr/${url}private/i, "GET /login knows to return to /private";

    $res = $ua->get( $url . "private" );
    like $res->content, qr/private/i, "GET /private now works";

    $res = $ua->get( $url . "logout" );
    like $res->content, qr/index/i, "GET /logout redirects to public";

    $res = $ua->get( $url . "private" );
    like $res->content, qr/login/i, "GET /private redirects to login again";
  },

  server => sub {
    my $port = shift;

    set confdir     => '.';
    set port        => $port, startup_info => 0;
    set show_errors => 1;
    set session     => 'Simple';
    set plugins     => {
      "Auth::Tiny" => {
        login_route   => '/signin',
        logged_in_key => 'user_id',
        callback_key  => 'next_url',
      },
    };

    get '/public' => sub { return 'index' };

    get '/private' => needs login => sub { return 'private' };

    get '/signin' => sub {
      session "user_id" => "Larry Wall";
      return "login and to back to " . params->{next_url};
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
