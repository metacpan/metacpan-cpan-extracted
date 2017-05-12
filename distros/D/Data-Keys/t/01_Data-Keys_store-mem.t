#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 10;
use Test::Differences;
use Test::Exception;

use FindBin qw($Bin);
use lib "$Bin/lib";

use File::Temp qw/ tempdir /;
use IO::Any;

BEGIN {
	use_ok('Data::Keys') or exit;
	use_ok('Data::Keys::E::Store::Mem') or exit;
}

exit main();

sub main {
	my $tmp_folder = tempdir( CLEANUP => 1 );

	# unknown attrs
	throws_ok {
		Data::Keys->new(
			'base_dir'    => $tmp_folder,
			'extend_with' => ['Store::Dir'],
			'nonExisting' => 1
			);
	}
	qr/unknown attributes - nonExisting/, 'die on unknown attributes';

	my $ts = Data::Keys->new(
		'extend_with' => ['Store::Mem',],
	);

	# set
	is($ts->set('a/b/c/d', 123), 'a/b/c/d', 'set');
	is($ts->get('a/b/c/d'), '123', 'get back');
	
	# delete via undef
	is($ts->set('abcd', 123), 'abcd', 'add with set');
	is($ts->get('abcd'), 123, 'get back');
	is($ts->set('abcd', undef), 'abcd', 'set undef value');
	ok(!exists $ts->mem_store->{'abcd'}, 'removed from the hash');
	is($ts->get('abcd'), undef, 'get back');

	return 0;
}

