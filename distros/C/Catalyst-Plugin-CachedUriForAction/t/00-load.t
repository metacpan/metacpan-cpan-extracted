use strict; use warnings;

use Test::More;

my @module = qw(
	Catalyst::Plugin::CachedUriForAction
);

plan tests => 0+@module;

diag "Testing on Perl $] at $^X";

for my $module ( @module ) {
	use_ok( $module ) or BAIL_OUT "Cannot load module '$module'";
	no warnings 'uninitialized';
	diag "Testing $module @ " . $module->VERSION;
}
