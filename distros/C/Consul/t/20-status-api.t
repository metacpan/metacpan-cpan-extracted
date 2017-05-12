#!perl

use warnings;
use strict;

use Test::More;
use Test::Exception;
use Test::Consul 0.005;

use Consul;

Test::Consul->skip_all_if_no_bin;

my $tc = Test::Consul->start;

skip "consul test environment not available", 3 unless $tc;

my $status = Consul->status(port => $tc->port);
ok $status, "got status API object";

lives_ok { $status->leader } "call to 'leader' succeeded";
lives_ok { $status->peers } "call to 'peers' succeeded";

done_testing;
