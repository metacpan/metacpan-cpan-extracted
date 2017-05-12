#!perl

use strict;
use warnings;

use Test::More tests => 3;
use Config::Hosts;

my $hosts = Config::Hosts->new();
$hosts->read_hosts('t/hosts');

my $res = $hosts->query_host("a_");
is($res, undef, "invalid query");
$res = $hosts->query_host("127.0.0.1");
ok(exists $res->{hosts}, "query by ip succeeded");
$res = $hosts->query_host("localhost");
ok(exists $res->{ip}, "query by hostname succeeded");
