#!/usr/bin/perl

my @modules = qw(Business::ISBN::Data);

use Test::More;

subtest 'compile' => sub {
	foreach my $module ( @modules ) {
		BAIL_OUT( "Could not load $module" ) unless use_ok( $module );
		}
	diag( "Business::ISBN::Data " . Business::ISBN::Data->VERSION );
	};

done_testing();
