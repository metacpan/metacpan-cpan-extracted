#! /usr/bin/perl -w

use strict;
use warnings;
use Test::More;
use English();
use Carp();
use English qw( -no_match_vars );
use Exporter();
use XSLoader();
use POSIX();
use constant;
use overload;

SKIP: {
	if ($^O eq 'MSWin32') {
		skip("No functions to override in Win32", 1);
	} else {
		no warnings;
		*CORE::GLOBAL::read = sub { $_[1] = undef; $! = POSIX::EAGAIN(); return -1 };
		*CORE::GLOBAL::sysread = sub { $_[1] = undef; $! = POSIX::EAGAIN(); return -1 };
		use warnings;
		my $required_error_message = quotemeta "Failed to read from";
		require FileHandle;
		@INC = qw(blib/lib); # making sure we're testing pure perl version
		require Crypt::URandom;
		my $generated = 0;
		eval {
			Crypt::URandom::urandom(1);
			$generated = 1;
		};
		chomp $@;
		ok(!$generated && $@ =~ /$required_error_message/smx, "Correct exception thrown when partial read returns:$@");
		$generated = 0;
		eval {
			Crypt::URandom::urandom_ub(1);
			$generated = 1;
		};
		chomp $@;
		ok(!$generated && $@ =~ /$required_error_message/smx, "Correct exception thrown when partial sysread returns:$@");
		my @sample_random_data = ('a', 'bc');
		no warnings;
		*CORE::GLOBAL::read = sub { $_[1] = shift @sample_random_data; $! = POSIX::EINTR(); return length $_[1] };
		use warnings;
		my $expected_result = join q[], @sample_random_data;
		my $actual_result = Crypt::URandom::urandom(3);
		ok($actual_result eq $expected_result, "Correctly survived an EINTR in urandom:$actual_result vs $expected_result");
		@sample_random_data = ('a', 'bc');
		no warnings;
		*CORE::GLOBAL::sysread = sub { $_[1] = shift @sample_random_data; $! = POSIX::EINTR(); return length $_[1] };
		use warnings;
		$actual_result = Crypt::URandom::urandom_ub(3);
		ok($actual_result eq $expected_result, "Correctly survived an EINTR in urandom_nb:$actual_result vs $expected_result");
		@sample_random_data = ('a', 'bc');
		my $count = 0;
		no warnings;
		*CORE::GLOBAL::sysread = sub { $count += 1; if ($count == 1 || $count == 3) { $_[1] = undef; $! == POSIX::EINTR(); return -1 } else { $_[1] = shift @sample_random_data; ($count == 2 ? $! =0 : $! = POSIX::EINTR()); return length $_[1] } };
		use warnings;
		$actual_result = Crypt::URandom::urandom_ub(3);
		ok($actual_result eq $expected_result, "Correctly survived an EINTR in urandom_nb:$actual_result vs $expected_result");
	}
}
done_testing();
