use Test::More;
use FileHandle();
use POSIX();
use Config;
use strict;
use warnings;

my %optional;
if ($^O eq 'MSWin32') {
} else {
	eval `cat ./check_random.inc`;
	if ($optional{DEFINE}) {
		diag("check_random.inc produced the flag of $optional{DEFINE}");
	}
}

SKIP: {
	if ($^O eq 'linux') { # LD_PRELOAD trick works here
		if (($optional{DEFINE}) && ($optional{DEFINE} eq '-DHAVE_CRYPT_URANDOM_NATIVE_GETRANDOM')) {
			my $is_covering = !!(eval 'Devel::Cover::get_coverage()');
			my @extra_args = $is_covering ? ('-MDevel::Cover') : ();
			my $correct_length = 27;
			my $failed_number_of_bytes = 13;
			my $error_number = POSIX::EINTR() + 0;
			my $c_path = 'getrandom.c';
			unlink $c_path or ($! == POSIX::ENOENT()) or die "Failed to unlink $c_path:$!";
			my $c_handle = FileHandle->new($c_path, Fcntl::O_CREAT() | Fcntl::O_WRONLY() | Fcntl::O_EXCL()) or die "Failed to open $c_path for writing:$!";
			print $c_handle <<"_OUT_";
#include <stddef.h>
#include <sys/types.h>
#include <errno.h>

int count = 0;

ssize_t getrandom(void *buf, size_t buflen, unsigned int flags) {
	count = count + 1;
        if (count <= 2) {
		errno = $error_number;
		return $failed_number_of_bytes;
	} else {
		errno = 0;
		return buflen;
	}
}
_OUT_
			my $binary_path = './getrandom.so';
			my $result = system { $Config{cc} } $Config{cc}, $Config{cccdlflags}, '-shared', '-o', $binary_path, $c_path;
			ok($result == 0, "Compiled a LD_PRELOAD binary at $binary_path:$?");
			my $handle = FileHandle->new();

			if (my $pid = $handle->open(q[-|])) {
				my $result = $handle->read(my $line, $correct_length + 5);
				chomp $line;
				my $actual_length = length $line;
				ok($actual_length == $correct_length, "getrandom hit with INT signal after $failed_number_of_bytes bytes recovers to produce correct length of $correct_length bytes:$actual_length");
				waitpid $pid, 0;
				ok($? == 0, "Successfully processed getrandom");
			} elsif (defined $pid) {
				local $ENV{LD_PRELOAD} = $binary_path;
				eval {
					exec { $^X } $^X, (map { "-I$_" } @INC), @extra_args, '-MCrypt::URandom', '-e', 'my $data = Crypt::URandom::getrandom(' . $correct_length . '); print "$data\n"; exit 0;' or die "Failed to exec $^X:$!";
				} or do {
					warn "$@";
				};
				exit 1;
			} else {
				die "Failed to fork:$!";
			}
			unlink $c_path or die "Failed to unlink $c_path:$!";
			unlink $binary_path or die "Failed to unlink $binary_path:$!";;

			$failed_number_of_bytes = -1;
			$error_number = POSIX::EAGAIN() + 0;
			$c_handle = FileHandle->new($c_path, Fcntl::O_CREAT() | Fcntl::O_WRONLY() | Fcntl::O_EXCL()) or die "Failed to open $c_path for writing:$!";
			print $c_handle <<"_OUT_";
#include <stddef.h>
#include <sys/types.h>
#include <errno.h>

ssize_t getrandom(void *buf, size_t buflen, unsigned int flags) {
	errno = $error_number;
	return $failed_number_of_bytes;
}
_OUT_
			$result = system { $Config{cc} } $Config{cc}, $Config{cccdlflags}, '-shared', '-o', $binary_path, $c_path;
			ok($result == 0, "Compiled a LD_PRELOAD binary at $binary_path:$!");
			$handle = FileHandle->new();

			if (my $pid = $handle->open(q[-|])) {
				my $result = $handle->read(my $line, 4000);
				chomp $line;
				my ($actual_error, $entire_message) = split /\t/smx, $line;
				$! = POSIX::EAGAIN();
				my $correct_error = "$!";
				ok($actual_error eq $correct_error, "Correct error caught:'$actual_error' vs '$correct_error'");
				my $correct_message = "Failed to getrandom:$actual_error";
				my $quoted_correct_message = quotemeta $correct_message;
				ok($entire_message =~ /^$quoted_correct_message/smx, "Error message is correct:$entire_message");
				waitpid $pid, 0;
				ok($? == 0, "Successfully caught exception for broken getrandom:$?");
			} elsif (defined $pid) {
				local $ENV{LD_PRELOAD} = $binary_path;
				eval {
					exec { $^X } $^X, (map { "-I$_" } @INC), @extra_args, '-MCrypt::URandom', '-e', 'eval { Crypt::URandom::getrandom(28); } or do { print "$!\t$@\n"; exit 0 }; exit 1;' or die "Failed to exec $^X:$!";
				} or do {
					warn "$@";
				};
				exit 1;
			} else {
				die "Failed to fork:$!";
			}
			unlink $c_path or die "Failed to unlink $c_path:$!";
			unlink $binary_path or die "Failed to unlink $binary_path:$!";;
		} else {
			skip("Not sure about alternative function signatures for $optional{DEFINE}", 1);
		}
	} else {
		skip("Not sure about LD_PRELOAD support in $^O", 1);
	}
}
done_testing();
