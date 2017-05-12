use strict;
use warnings;
use Test::More 0.96 import => ['!pass'];

use File::Temp 0.19; # newdir
use HTTP::Tiny;
use Test::TCP;

use Dancer ':syntax';
use Dancer::Plugin::Adapter;

test_tcp(
  client => sub {
    my $port = shift;
    my $url  = "http://localhost:$port/";

    my $ua  = HTTP::Tiny->new;
    my $res = $ua->get($url);
    ok( $res->{success}, "Request success" );
    like $res->{content}, qr/Hello World/i, "Request content correct";
  },

  server => sub {
    my $port = shift;

    set confdir => '.';
    set port => $port, startup_info => 0;

    set show_errors => 0;

    set plugins => {
      Adapter => {
        tempdir => {
          class      => 'File::Temp',
          constructor => 'newdir',
        },
      },
    };

    get '/' => sub {
      if ( -d service("tempdir") ) {
        return 'Hello World';
      }
      else {
        return "Goodbye World";
      }
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
