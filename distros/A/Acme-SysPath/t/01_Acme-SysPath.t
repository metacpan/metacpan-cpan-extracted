#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 3;

use FindBin '$Bin';
use Cwd 'abs_path';

BEGIN {
	use_ok ( 'Acme::SysPath' ) or exit;
}

exit main();

sub main {
	is(
		Acme::SysPath->paths->{'sysconfdir'},
		File::Spec->catdir(
			abs_path(File::Spec->catfile($Bin, '..',)),
			'conf',
		),
		'conf/ - sysconfdir',
	);
	is(
		Acme::SysPath->paths->{'datadir'},
		File::Spec->catdir(
			abs_path(File::Spec->catfile($Bin, '..',)),
			'share',
		),
		'share/ - datadir',
	);
	
	return 0;
}

