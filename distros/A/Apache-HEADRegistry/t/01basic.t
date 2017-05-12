use strict;
use warnings FATAL => 'all';

use Apache::Test;

plan tests => 4, have_module('mod_perl.c');

ok require 5.005;
ok require mod_perl;
ok $mod_perl::VERSION >= 1.21;

ok require Apache::HEADRegistry;
