use Config;

sub warn_or_diag {
	if ($INC{'Test/More.pm'}) {
		diag(@_);
	} else {
		warn @_;
	}
}
my $test_file_name = 'test.c';
my $binary_name = 'a.out';
my $output = q[];
open FOO, ">$test_file_name" or die "Failed to open $test_file_name for writing:$!";
print FOO <<'_OUT_';
#include <sys/types.h>
#include <sys/random.h>

int main(void)
{
        char buf[5];
        int l = 5;
        unsigned int o = 1;
        int r = getrandom(buf, l, o);
        return 0;
}
_OUT_
close FOO or die "Failed to close $test_file_name:$!";
$output .= `$Config{cc} -o $binary_name $test_file_name 2>&1`;
unlink $test_file_name or die "Failed to unlink $test_file_name:$!";
if ($? == 0) {
	warn_or_diag "getrandom from sys/random is AVAILABLE\n";
	unlink $binary_name or die "Failed to unlink $binary_name:$!";
	$optional{DEFINE} = '-DHAVE_CRYPT_URANDOM_NATIVE_GETRANDOM';
} else {
	warn_or_diag "getrandom from sys/random is unavailable\n";
	open FOO, ">$test_file_name" or die "Failed to open $test_file_name for writing:$!";
	print FOO <<'_OUT_';
#include <sys/syscall.h>

int main(void)
{
        char buf[5];
        int l = 5;
        unsigned int o = 1;
        int r = syscall(SYS_getrandom, buf, l, o);
        return 0;
}
_OUT_
	close FOO or die "Failed to close $test_file_name:$!";
	$output .= `$Config{cc} -o $binary_name $test_file_name 2>&1`;
	if ($? == 0) {
		warn_or_diag "SYS_getrandom from sys/syscall is AVAILABLE\n";
		unlink $binary_name or die "Failed to unlink $binary_name:$!";
		$optional{DEFINE} = '-DHAVE_CRYPT_URANDOM_SYSCALL_GETRANDOM';
	} else {
		warn_or_diag "SYS_getrandom from sys/syscall is unavailable\n";
		open FOO, ">$test_file_name" or die "Failed to open $test_file_name for writing:$!";
		print FOO <<'_OUT_';
#include <sys/types.h>
#include <sys/random.h>

int main(void)
{
        char buf[5];
        int l = 5;
        int r = getentropy(buf, l);
        return 0;
}
_OUT_
		close FOO or die "Failed to close $test_file_name:$!";
		$output .= `$Config{cc} -o $binary_name $test_file_name 2>&1`;
		if ($? == 0) {
			warn_or_diag "getentropy from sys/random is AVAILABLE\n";
			unlink $binary_name or die "Failed to unlink $binary_name:$!";
			$optional{DEFINE} = '-DHAVE_CRYPT_URANDOM_NATIVE_GETENTROPY';
		} else {
			warn_or_diag "getentropy from sys/random is unavailable\n";
			open FOO, ">$test_file_name" or die "Failed to open $test_file_name for writing:$!";
			print FOO <<'_OUT_';
#include <unistd.h>

int main(void)
{
        char buf[5];
        int l = 5;
        int r = getentropy(buf, l);
        return 0;
}
_OUT_
			close FOO or die "Failed to close $test_file_name:$!";
			$output .= `$Config{cc} -o $binary_name $test_file_name 2>&1`;
			if ($? == 0) {
				warn_or_diag "getentropy from unistd is AVAILABLE\n";
				unlink $binary_name or die "Failed to unlink $binary_name:$!";
				$optional{DEFINE} = '-DHAVE_CRYPT_URANDOM_UNISTD_GETENTROPY';
			} else {
				warn_or_diag "getentropy from unistd is unavailable\n";
				open FOO, ">$test_file_name" or die "Failed to open $test_file_name for writing:$!";
				print FOO <<'_OUT_';
int main(void)
{
        return 0;
}
_OUT_
				close FOO or die "Failed to close $test_file_name:$!";
				$output .= `$Config{cc} -o $binary_name $test_file_name 2>&1`;
				if ($? == 0) {
					warn_or_diag "C compiler is AVAILABLE\n";
					if ($ENV{CRYPT_URANDOM_BUILD_DEBUG}) {
						warn_or_diag $output;
					}
					unlink $binary_name or die "Failed to unlink $binary_name:$!";
					$optional{DEFINE} = '-DUNKNOWN_ENVIRONMENT';
				} else {
					warn_or_diag "C compiler is unavailable\n";
					$optional{DEFINE} = '-DNO_COMPILER_FOUND';
				}
			}
		}
	}
	unlink $test_file_name or die "Failed to unlink $test_file_name:$!";
}
