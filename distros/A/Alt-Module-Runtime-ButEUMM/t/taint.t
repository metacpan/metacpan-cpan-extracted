#!perl -T
# above line is required to enable taint mode

use warnings;
use strict;

use Test::More tests => 5;

BEGIN {
	use_ok "Module::Runtime",
		qw(require_module use_module use_package_optimistically);
}

my $tainted_modname = substr($ENV{PATH}, 0, 0) . "Module::Runtime";
eval { require_module($tainted_modname) };
like $@, qr/\AInsecure dependency /;
eval { use_module($tainted_modname) };
like $@, qr/\AInsecure dependency /;
eval { use_package_optimistically($tainted_modname) };
like $@, qr/\AInsecure dependency /;
eval { require_module("Module::Runtime") };
is $@, "";

1;
