#! /usr/bin/perl -w

use strict;
use warnings;
use Test::More;
use English();
use Carp();
use English qw( -no_match_vars );
use Exporter();
use XSLoader();

SKIP: {
	if ($^O eq 'MSWin32') {
		skip("No functions to override in Win32", 1);
	} else {
		no warnings;
		*CORE::GLOBAL::read = sub { return 0 };
		*CORE::GLOBAL::sysread = sub { return 0 };
		use warnings;
		require POSIX;
		my $required_error_message = quotemeta "Only read 0 bytes from";
		@INC = grep !/blib\/arch/, @INC; # making sure we're testing pure perl version
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
	}
}
done_testing();
