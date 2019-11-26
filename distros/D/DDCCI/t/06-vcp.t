
use strict;
use Test::More;

BEGIN { use_ok( 'DDCCI' ) };

SKIP: {
	skip 'no monitor, skipped test', 7 if (-f '.skip');

	my $devs = scan_devices();
	BAIL_OUT( "*** no monitors detected, further testing is impossible" ) if (scalar @{$devs} == 0);

	my $ddcci = DDCCI->new($devs->[0]->{'dev'});
	fail( 'object creation' ) unless (defined $ddcci && ($ddcci >= 0));

	ok( defined $ddcci->can('read_vcp'), 'function read_vcp() presence' );
	ok( defined $ddcci->can('write_vcp'), 'function write_vcp() presence' );

	my $vcp = get_vcp_addr('contrast');
	BAIL_OUT( "*** test VCP invalid or not found" ) if ($vcp < 0);

	my $d = $ddcci->read_vcp($vcp);
	ok( defined $d, 'get original vcp value' );

	my $w = $ddcci->write_vcp($vcp, 100);
	ok( defined $w && ($w == 100), 'set new vcp value' );
	select undef, undef, undef, 0.05;
	my $r = $ddcci->read_vcp($vcp);
	ok( defined $r && ($r == $w), 'check new vcp value effect');

	ok( defined $ddcci->write_vcp($vcp, $d), 'restore original vcp value' );
}

done_testing();
