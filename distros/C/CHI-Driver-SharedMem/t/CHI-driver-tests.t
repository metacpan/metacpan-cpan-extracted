#!perl -w

use strict;
use warnings;
use IPC::SysV qw(S_IRUSR S_IWUSR);
use IPC::SharedMem;
use CHI::Driver::SharedMem::t::CHIDriverTests;

my $do_tests = 1;
my $SIGSYS_count = 0;
eval {
	local $SIG{SYS} = sub { $SIGSYS_count++ };
	my $shm = IPC::SharedMem->new(1, 8 * 1024, S_IRUSR|S_IWUSR);
	$shm->remove();
};
if($@ || $SIGSYS_count) {
	if($^O eq 'cygwin') {
		warn("It may be that the cygserver service isn't running.");
		$do_tests = 0;
	}
}

if($do_tests) {
	CHI::Driver::SharedMem::t::CHIDriverTests->runtests();
} else {
	print "1..1\nok 1\n";
}
