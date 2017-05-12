#!perl

use strict;
use warnings;

use Test::More tests => 1;

require_ok('AnyEvent::Consul');

local $AnyEvent::Consul::VERSION = $AnyEvent::Consul::VERSION || 'from repo';
note("AnyEvent::Consul $AnyEvent::Consul::VERSION, Perl $], $^X");
