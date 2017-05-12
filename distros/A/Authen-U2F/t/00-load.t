#!perl

use strict;
use warnings;

use Test::More tests => 1;

require_ok('Authen::U2F');

local $Authen::U2F::VERSION = $Authen::U2F::VERSION || 'from repo';
note("Authen::U2F $Authen::U2F::VERSION, Perl $], $^X");
