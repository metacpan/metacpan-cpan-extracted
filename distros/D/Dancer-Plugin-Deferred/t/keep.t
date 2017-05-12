use 5.010;
use strict;
use warnings;
use Test::More 0.96 import => ['!pass'];
use Test::TCP;

use Dancer ':syntax';
use Dancer::Plugin::Deferred;
use LWP::UserAgent;

test_tcp(
  client => sub {
    my $port = shift;
    my $url  = "http://localhost:$port/";

    my $ua = LWP::UserAgent->new( cookie_jar => {} );
    my $res;

    $res = $ua->get( $url . "show" );
    like $res->content, qr/^message:\s*$/sm, "no messages pending";

    $res = $ua->get( $url . "link" );
    my $location = $res->content;
    chomp $location;
    $res = $ua->get( $location );
    like $res->content, qr/^message: sayonara/sm,
      "message set and returned via keep/link";

    $res = $ua->get( $url . "show" );
    like $res->content, qr/^message:\s*$/sm, "no messages pending";

  },

  server => sub {
    my $port = shift;

    set confdir => '.';
    set port => $port, startup_info => 0;

    set show_errors => 1;

    set views => path( 't', 'views' );
    set session => 'Simple';

    get '/show' => sub {
      template 'index';
    };

    get '/link' => sub {
      deferred msg => "sayonara";
      template 'link' => { link => uri_for( '/show', {deferred_param} ) };
    };

    Dancer->dance;
  },
);
done_testing;

#
# This file is part of Dancer-Plugin-Deferred
#
# This software is Copyright (c) 2012 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
