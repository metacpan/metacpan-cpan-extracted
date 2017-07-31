#!perl

use strict;
use warnings;

use Test::More tests => 1;

require_ok('AnyEvent::Consul::Exec');

local $AnyEvent::Consul::Exec::VERSION = $AnyEvent::Consul::Exec::VERSION || 'from repo';
note("AnyEvent::Consul::Exec $AnyEvent::Consul::Exec::VERSION, Perl $], $^X");
