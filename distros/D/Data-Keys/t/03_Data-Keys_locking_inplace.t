#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 13;
use Test::NoMalware;
use Test::Differences;
use Test::Exception;

use FindBin qw($Bin);
use lib "$Bin/lib";

use File::Temp qw/ tempdir /;
use JSON::Util;
use Fcntl qw(:DEFAULT :flock);

BEGIN {
	use_ok('Data::Keys') or exit;
	use_ok('Data::Keys::E::Dir::LockInPlace') or exit;
	use_ok('Data::Keys::E::Locking') or exit;
}

exit main();

sub main {
	my $tmp_folder = tempdir( CLEANUP => 1 );
	my $ts = Data::Keys->new(
		'base_dir'    => $tmp_folder,
		'extend_with' => ['Store::Dir', 'Dir::LockInPlace', 'Locking'],
	);

	is($ts->get('abcd'), (), 'get non-existing file');
	$ts->set('abcd', 123);
	is($ts->set('abcd', 123), 'abcd', 'set');
	is_deeply(IO::Any->slurp([$tmp_folder, 'abcd']), 123, 'read the file directly');

	SHARED_LOCK: {
		my $lock_fh = IO::Any->new([$tmp_folder, 'abcd'], '+>>', { LOCK_SH => 1 });
		is($ts->get('abcd'), 123, 'get shared locked file is fine');

		my $pid = fork(); die 'fork failed' if not defined $pid;
		if (not $pid) {
			sleep(1);
			close($lock_fh);
			exit;
		}
		close($lock_fh);
		throws_ok { IO::Any->new([$tmp_folder, 'abcd'], '+>>', { LOCK_EX => 1, LOCK_NB => 1 }) } qr/flock failed/, 'file locked preventing LOCK_EX';
		is($ts->set('abcd', 456), 'abcd', 'set (should be blocked)');
		lives_ok { IO::Any->new([$tmp_folder, 'abcd'], '+>>', { LOCK_EX => 1, LOCK_NB => 1 }) } 'and unlocked';
	}
	
	EXCLUSIVE_LOCK: {
		my $lock_fh = IO::Any->new([$tmp_folder, 'abcdx'], '+>>', { LOCK_EX => 1 });
		my $pid = fork(); die 'fork failed' if not defined $pid;
		if (not $pid) {
			sleep(1);
			close($lock_fh);
			exit;
		}
		close($lock_fh);
		throws_ok { IO::Any->new([$tmp_folder, 'abcdx'], '+>>', { LOCK_SH => 1, LOCK_NB => 1 }) } qr/flock failed/, 'file locked preventing LOCK_SH';;
		is($ts->set('abcdx', 456), 'abcdx', 'set (should be blocked)');
		lives_ok { IO::Any->new([$tmp_folder, 'abcdx'], '+>>', { LOCK_EX => 1, LOCK_NB => 1 }) } 'and unlocked';
	}
	
	return 0;
}
