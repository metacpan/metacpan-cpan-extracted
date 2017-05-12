#!/usr/bin/perl

use strict;
use warnings;

use Clutter::TestHelper tests => 1;

use Champlain;

exit tests();

sub tests {
	my $tile = Champlain::ErrorTileSource->new_full(64);
	isa_ok($tile, 'Champlain::ErrorTileSource');

	return 0;
}
