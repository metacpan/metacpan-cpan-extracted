#!perl -wT

use strict;
use warnings;
use Test::Most;

if($ENV{RELEASE_TESTING}) {
	use Test::Requires {
		'warnings::unused' => 0.04
	};
}

BEGIN {
	if($ENV{RELEASE_TESTING}) {
		use_ok('CHI');
		use_ok('CHI::Driver::SharedMem');
		use warnings::unused -global;
	}
}

if(not $ENV{RELEASE_TESTING}) {
	plan(skip_all => 'Author tests not required for installation');
} else {
	CHI->new(driver => 'SharedMem', shmkey => IPC::SysV::ftok($0));
	plan tests => 2;
}
