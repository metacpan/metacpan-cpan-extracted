#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 7;
use Test::NoMalware;
use Test::Differences;
use Test::Exception;

use FindBin qw($Bin);
use lib "$Bin/lib";

use File::Temp qw/ tempdir /;
use JSON::Util;

BEGIN {
	use_ok('Data::Keys') or exit;
	use_ok('Data::Keys::E::Dir::Lock') or exit;
	use_ok('Data::Keys::E::Locking') or exit;
	use_ok('Data::Keys::E::Key::AutoLock') or exit;
}

exit main();

sub main {
	my $tmp_folder = tempdir( CLEANUP => 1 );
	my $ts = Data::Keys->new(
		'base_dir'    => $tmp_folder,
		'extend_with' => ['Store::Dir', 'Dir::Lock', 'Locking', 'Key::AutoLock'],
	);

	is($ts->get('abcd'), undef, 'get non-existing file');
	is($ts->set('abcd', 123), 'abcd', 'set');
	is_deeply(IO::Any->slurp([$tmp_folder, 'abcd']), 123, 'read the file directly');	
		
	return 0;
}

