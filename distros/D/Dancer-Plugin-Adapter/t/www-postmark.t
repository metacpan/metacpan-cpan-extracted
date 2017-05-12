use strict;
use warnings;
use Test::More 0.96 import => ['!pass'];

use Class::Load qw/try_load_class/;
use Test::TCP;
use Dancer ':syntax';
use Dancer::Plugin::Adapter;

try_load_class('WWW::Postmark')
  or plan skip_all => "WWW::Postmark required to run these tests";

HTTP::Tiny->new->get("http://api.postmarkapp.com/")->{success}
  or plan skip_all => "api.postmarkapp.com not available";

test_tcp(
  client => sub {
    my $port = shift;
    my $url  = "http://localhost:$port/";

    my $ua  = HTTP::Tiny->new;
    my $res = $ua->get($url);
    ok( $res->{success}, "Request success" );
    like $res->{content}, qr/Mail sent/i, "WWW::Postmark pretended to send mail";
  },

  server => sub {
    my $port = shift;

    set confdir => '.';
    set port => $port, startup_info => 0;

    set show_errors => 0;

    set plugins => {
      Adapter => {
        postmark => {
          class   => 'WWW::Postmark',
          options => 'POSTMARK_API_TEST',
        },
      },
    };

    get '/' => sub {
      eval {
        service("postmark")->send(
          from    => 'me@domain.tld',
          to      => 'you@domain.tld, them@domain.tld',
          subject => 'an email message',
          body    => "hi guys, what's up?"
        );
      };

      return $@ ? "Error: $@" : "Mail sent";
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
