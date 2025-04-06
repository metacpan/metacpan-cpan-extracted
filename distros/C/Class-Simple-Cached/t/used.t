#!perl -w

use strict;
use Test::Most;

unless($ENV{RELEASE_TESTING}) {
	plan(skip_all => "Author tests not required for installation");
}

eval 'use Test::Module::Used';
if($@) {
	plan(skip_all => 'Test::Module::Used required for testing all modules needed');
} else {
	my $used = Test::Module::Used->new(meta_file => 'MYMETA.yml');
	$used->ok();
}
