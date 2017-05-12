#!perl

use strict;
use warnings;

use Test::More tests => 1;

require_ok('Atto');

local $Atto::VERSION = $Etcd::VERSION || 'from repo';
note("Atto $Atto::VERSION, Perl $], $^X");
