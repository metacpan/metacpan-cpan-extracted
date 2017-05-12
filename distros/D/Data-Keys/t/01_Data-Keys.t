#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 4;
use Test::Exception;

BEGIN {
	use_ok('Data::Keys') or exit;
}

exit main();

sub main {
	# unknown attrs
	throws_ok { Data::Keys->new('nonExisting' => 1); } qr/unknown attributes - nonExisting/, 'die on unknown attributes';
	
	# must have set/get
	throws_ok { my $ts = Data::Keys->new(); } qr{role with set/get is mandatory}, 'role with set/get is mandatory';
			
	# fail loading
	throws_ok { my $ts = Data::Keys->new('extend_with' => 'abc987'); } qr{failed to load Data::Keys::E::abc}, 'extend with non-existing module';
			
	return 0;
}

