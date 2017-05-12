#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::Most;

use t::lib::TestApp;

use Dancer::Test;
use Dancer::Config;

subtest "Ensure legacy_any directs to correct controller" => sub {
    route_exists [ GET => '/legacy/any/get' ],
      "GET is handled by ANY";
    route_exists [ POST => '/legacy/any/post' ],
      "POST is handled by ANY";
    route_exists [ PUT => '/legacy/any/put' ],
      "PUT is handled by ANY";
    route_exists [ DELETE => '/legacy/any/delete' ],
      "DELETE is handled by ANY";
};

done_testing;
