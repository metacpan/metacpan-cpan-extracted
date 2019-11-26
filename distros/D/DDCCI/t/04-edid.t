
use strict;
use Test::More;

BEGIN { use_ok( 'DDCCI' ) };

SKIP: {
	skip 'no monitor, skipped test', 4 if (-f '.skip');

	my $devs = scan_devices();
	BAIL_OUT( "*** no monitors detected, further testing is impossible" ) if (scalar @{$devs} == 0);

	my $ddcci = DDCCI->new($devs->[0]->{'dev'});
	fail( 'object creation' ) unless (defined $ddcci && ($ddcci >= 0));

	ok( defined $ddcci->can('read_edid'), 'function read_edid() presence' );
	my $edid = $ddcci->read_edid();
	ok( defined $edid && (length $edid == 128), 'get edid' );

	my $de = decode_edid $edid;
	ok( ($de->{'id'} eq $devs->[0]->{'id'}) && ($de->{'sn'} == $devs->[0]->{'sn'}), 'decode edid' );
}

done_testing();
