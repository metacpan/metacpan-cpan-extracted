#!perl -w

use strict;
use warnings;
use IPC::SysV qw(S_IRUSR S_IWUSR);
use IPC::SharedMem;
use CHI::Driver::SharedMem::t::CHIDriverTests;
use Test::NoWarnings;

# These variables are also used in lib/CHI/Driver/SharedMem/t/CHIDrivertests.pm
our $shm_key = 12344321;
our $shm_size = 16 * 1024;

my $do_tests = 1;
my $SIGSYS_count = 0;
eval {
	local $SIG{SYS} = sub { $SIGSYS_count++ };
	my $shm = IPC::SharedMem->new(1, $shm_size, S_IRUSR|S_IWUSR);
	$shm->remove();
};
if($@ || $SIGSYS_count) {
	if($^O eq 'cygwin') {
		warn("It may be that the cygserver service isn't running.");
		$do_tests = 0;
	}
}

if($do_tests) {
	# Remove any shared memory around from a previous failure
	my $shm;
	if(defined($shm = IPC::SharedMem->new($shm_key, $shm_size, S_IRUSR|S_IWUSR))) {
		$shm->remove();
	}
	CHI::Driver::SharedMem::t::CHIDriverTests->runtests();
	# Remove the shared memory area we've just created.
	if(defined($shm = IPC::SharedMem->new($shm_key, $shm_size, S_IRUSR|S_IWUSR))) {
		$shm->remove();
	}
} else {
	print "1..1\nok 1\n";
}
