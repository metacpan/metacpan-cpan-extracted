
use strict;
use Test::More;

BEGIN { use_ok('DDCCI') };

SKIP: {
	skip 'no monitor, skipped test', 3 if (-f '.skip');

	my $devs = scan_devices();
	BAIL_OUT("*** no monitors detected, further testing is impossible") if (scalar @{$devs} == 0);

	ok( defined &DDCCI::new, 'function new() presence');
	my $ddcci = DDCCI->new($devs->[0]->{'dev'});
	fail('object creation') unless (defined $ddcci && ($ddcci >= 0));

	my $fn = readlink '/proc/self/fd/' . ($ddcci->{'fd'}+0);
	ok($fn eq $devs->[0]->{'dev'}, 'verify dev name');
}

done_testing();
