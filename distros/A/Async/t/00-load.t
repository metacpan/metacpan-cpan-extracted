use strict; use warnings;

use Test::More;

BEGIN { # compat shim for old Test::More
	defined &BAIL_OUT or *BAIL_OUT = sub {
		my $t = Test::Builder->new;
		$t->_print( "Bail out!  $_[0]" );
		$t->no_ending(1);
		exit 255;
	};
}

my @module = qw( Async );

plan tests => 0+@module;

diag "Testing on Perl $] at $^X";

for my $module ( @module ) {
	use_ok( $module ) or BAIL_OUT "Cannot load module '$module'";
	no warnings 'uninitialized';
	diag "Testing $module " . $module->VERSION;
}
