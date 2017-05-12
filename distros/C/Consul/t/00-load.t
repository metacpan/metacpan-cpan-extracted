#!perl

use strict;
use warnings;

use Test::More tests => 1;

require_ok('Consul');

local $Consul::VERSION = $Consul::VERSION || 'from repo';
note("Consul $Consul::VERSION, Perl $], $^X");
