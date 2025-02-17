#! /usr/bin/perl -w

use strict;
use warnings;
use Test::More;
use English();
use Carp();
use English qw( -no_match_vars );
use POSIX();
use Exporter();
use XSLoader();
use constant;
use overload;
BEGIN {
	if ($^O eq 'MSWin32') {
		require Win32;
		require Win32::API;
		require Win32::API::Type;
	}
}

SKIP: {
	if ($^O eq 'MSWin32') {
		no warnings;
		sub Win32::API::new { return }
		use warnings;
		my $required_error_message = quotemeta "Could not import";
		require Crypt::URandom;
		my $generated = 0;
		eval {
			Crypt::URandom::urandom(1);
			$generated = 1;
		};
		chomp $@;
		ok(!$generated && $@ =~ /$required_error_message/smx, "Correct exception thrown when Win32::API->new() is overridden:$@");
	} else {
		no warnings;
		*CORE::GLOBAL::read = sub { $! = POSIX::EACCES(); return -1 };
		*CORE::GLOBAL::sysread = sub { $! = POSIX::EACCES(); return -1 };
		use warnings;
		my $required_error_message = q[(?:] . (quotemeta POSIX::strerror(POSIX::EACCES())) . q[|Permission[ ]denied)];
		require FileHandle;
		@INC = qw(blib/lib); # making sure we're testing pure perl version
		require Crypt::URandom;
		my $generated = 0;
		eval {
			Crypt::URandom::urandom(1);
			$generated = 1;
		};
		chomp $@;
		ok(!$generated && $@ =~ /$required_error_message/smx, "Correct exception thrown when read is overridden:$@");
		$generated = 0;
		eval {
			Crypt::URandom::urandom(1);
			$generated = 1;
		};
		chomp $@;
		ok(!$generated && $@ =~ /$required_error_message/smx, "Correct exception thrown when read is overridden twice:$@");
		$generated = 0;
		eval {
			Crypt::URandom::urandom_ub(1);
			$generated = 1;
		};
		chomp $@;
		ok(!$generated && $@ =~ /$required_error_message/smx, "Correct exception thrown when sysread is overridden:$@");
		$generated = 0;
		eval {
			Crypt::URandom::urandom_ub(1);
			$generated = 1;
		};
		chomp $@;
		ok(!$generated && $@ =~ /$required_error_message/smx, "Correct exception thrown when sysread is overridden twice:$@");
	}
}
done_testing();
