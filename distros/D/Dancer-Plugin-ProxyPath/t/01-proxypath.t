#/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use Dancer::Plugin::ProxyPath;

isa_ok(proxy, "Dancer::Plugin::ProxyPath::Proxy", "What proxy returns");

can_ok(proxy, qw/uri_for/);

