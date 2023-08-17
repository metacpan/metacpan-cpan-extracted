#!/usr/bin/perl -w

use strict;
use warnings;
use IPC::SysV qw(S_IRUSR S_IWUSR);
use IPC::SharedMem;
use Test::Most tests => 4;
use Test::Carp;

use_ok('CHI');

my $shm_key = 44334433;
my $shm_size = 256;	# 256 bytes to allow for CHI metadata
my $max_size = 40;

my $shm;
if(defined($shm = IPC::SharedMem->new($shm_key, $shm_size, S_IRUSR|S_IWUSR))) {
	$shm->remove();
}

{
	my $s = CHI->new(driver => 'SharedMem', shm_size => $shm_size, shm_key => $shm_key, max_size => $max_size);

	my $error_called = 0;
	$s->on_set_error(sub {
		diag($_[2]);
		if($_[0] =~ /^error during cache set for namespace/) {
			$error_called++;
		}
	});

	$s->set('xyzzy', 'x' x 10, '5 mins');
	ok($s->get('xyzzy') eq 'x' x 10);

	$s->set('xyzzy', 'x' x 1000, '5 mins');
	cmp_ok($error_called, '==', 1, 'exactly one error');
	ok(!defined($s->get('xyzzy')));
}

# Remove the shared memory area we've just created.
if(defined($shm = IPC::SharedMem->new($shm_key, $shm_size, S_IRUSR|S_IWUSR))) {
	$shm->remove();
}
