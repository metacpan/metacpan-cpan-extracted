#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all =>
      "please set the environment variable MEMCACHED_SERVER to run this test"
      unless exists $ENV{MEMCACHED_SERVER};

}

use Catalyst::Plugin::Session::Test::Store (
    backend => "Memcached::Fast",
    config  => { servers => [split(/\s+/, $ENV{MEMCACHED_SERVER})] },
);

