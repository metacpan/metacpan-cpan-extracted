#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 14;
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
}

exit main();

sub main {
	my $tmp_folder = tempdir( CLEANUP => 1 );
	my $ts = Data::Keys->new(
		'base_dir'    => $tmp_folder,
		'extend_with' => ['Store::Dir', 'Dir::Lock', 'Locking'],
	);

	is($ts->get('abcd'), (), 'get non-existing file');
	is($ts->set('abcd', 123), 'abcd', 'set');
	is_deeply(IO::Any->slurp([$tmp_folder, 'abcd']), 123, 'read the file directly');	
	
	TEST_FILE_LOCKING: {
		my $lock_filename = File::Spec->catfile($ts->lock_dir, 'abcd');
		my $lock_fh       = IO::Any->new([$lock_filename], '+>>', { LOCK_EX => 1 });
		
		my $locked = 1;
		local $SIG{'ALRM'} = sub {
			$locked = 2;
			unlink($lock_filename);
			close($lock_fh);
		};
		alarm(1);
		is($ts->get('abcd'), 123, 'get (should be blocked)');
		is($locked, 2, 'lock released');

		$locked  = 1;
		$lock_fh = IO::Any->new([$lock_filename], '+>>', { LOCK_EX => 1 });
		alarm(1);
		is($ts->set('abcd', 1234), 'abcd', 'set (should be blocked)');
		is($locked, 2, 'lock released');
		is($ts->get('abcd'), 1234, 'verify the value');
	}
	
	TEST_SEMAPHORE_FILE_UNLINKING: {
		my $sem_lock_filename = File::Spec->catfile($tmp_folder, '.lock', '123');
		do {
			my $ts2 = Data::Keys->new(
				'base_dir'    => $tmp_folder,
				'extend_with' => ['Store::Dir', 'Dir::Lock', 'Locking'],
			);
			$ts2->lock_ex('123');
			ok(-f $sem_lock_filename, 'semaphore lock file created');
			is(IO::Any->slurp($sem_lock_filename), $$, 'semaphore lock file should have current pid');
		};
		ok(! -f $sem_lock_filename, 'semaphore lock file gone after leaving scope');
	}
	
	return 0;
}

