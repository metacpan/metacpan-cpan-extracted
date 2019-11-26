
use strict;
use Test::More;

BEGIN { use_ok( 'DDCCI' ) };

SKIP: {
	skip 'no monitor, skipped test', 3 if (-f '.skip');

	my $devs = scan_devices();
	BAIL_OUT( "*** no monitors detected, further testing is impossible" ) if (scalar @{$devs} == 0);

	my $ddcci = DDCCI->new($devs->[0]->{'dev'});
	fail( 'object creation' ) unless (defined $ddcci && ($ddcci >= 0));

	ok( defined $ddcci->can('read_caps'), 'function read_caps() presence' );
	my $caps = $ddcci->read_caps();
	ok( defined $caps && (length $caps > 2), 'get caps' );
}

done_testing();
