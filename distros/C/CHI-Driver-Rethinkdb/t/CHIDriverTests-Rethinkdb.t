#!perl -w
use strict;
use warnings;
use FindBin;
use Test::More;
use lib "$FindBin::Bin/../lib";

plan skip_all => 'set TEST_ONLINE to enable this test'
  unless $ENV{TEST_ONLINE};

use CHI::Driver::Rethinkdb::t::CHIDriverTests;
CHI::Driver::Rethinkdb::t::CHIDriverTests->runtests;
