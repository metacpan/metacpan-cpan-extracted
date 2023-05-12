#! /usr/bin/perl -w

use strict;
use warnings;
use Test::More;

SKIP: {
	if ($^O eq 'MSWin32') {
		skip("No functions to override in Win32", 1);
	} else {
		no warnings;
		*CORE::GLOBAL::sysopen = sub { $! = POSIX::EACCES(); return };
		use warnings;
		require POSIX;
		my $required_error_message = quotemeta POSIX::strerror(POSIX::EACCES());
		require Crypt::URandom;
		my $generated = 0;
		eval {
			Crypt::URandom::urandom(1);
			$generated = 1;
		};
		chomp $@;
		ok(!$generated && $@ =~ /$required_error_message/smx, "Correct exception thrown when sysopen is overridden:$@");
		$generated = 0;
		eval {
			Crypt::URandom::urandom(1);
			$generated = 1;
		};
		chomp $@;
		ok(!$generated && $@ =~ /$required_error_message/smx, "Correct exception thrown when sysopen is overridden twice:$@");
	}
}
done_testing();
