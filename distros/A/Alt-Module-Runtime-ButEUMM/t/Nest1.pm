package t::Nest1;

{ use 5.006; }
use warnings;
use strict;
use Module::Runtime qw(require_module);

our $VERSION = 1;

require_module("t::Nested");

"t::Nest1 return";
