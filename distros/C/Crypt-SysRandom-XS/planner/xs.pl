#! perl

use strict;
use warnings;

load_extension('Dist::Build::XS');
load_extension('Dist::Build::XS::Conf');

my %options;

my @possibilities = (
	[ 'getrandom in sys/random.h', 'SYS_RANDOM_GETRANDOM', {}, <<EOF ],
#include <sys/types.h>
#include <sys/random.h>

int main(void)
{
        char buf[16];
        int r = getrandom(buf, sizeof(buf), 0);
        return 0;
}
EOF
	['getrandom in sys/syscall.h', 'SYSCALL_GETRANDOM', {}, <<EOF],
#define _GNU_SOURCE
#include <sys/syscall.h>
#include <unistd.h>

int main(void)
{
        char buf[16];
        int r = syscall(SYS_getrandom, buf, sizeof(buf), 0);
        return 0;
}
EOF
	['arc4random in sys/random.h', 'SYS_RANDOM_ARC4RANDOM', {}, <<EOF ],
#include <sys/types.h>
#include <sys/random.h>

int main(void)
{
        char buf[16];
        arc4random_buf(buf, sizeof(buf));
        return 0;
}
EOF
	['arc4random in unistd.h', 'UNISTD_ARC4RANDOM', {}, <<EOF ],
#include <unistd.h>

int main(void)
{
        char buf[16];
        arc4random_buf(buf, sizeof(buf));
        return 0;
}
EOF
	['arc4random in stdlib.h', 'STDLIB_ARC4RANDOM', {}, <<EOF ],
#include <stdlib.h>

int main(void)
{
        char buf[16];
        arc4random_buf(buf, sizeof(buf));
        return 0;
}
EOF
	['Microsoft BcryptGenRandom', 'BCRYPT_GENRANDOM', { libraries => ['Bcrypt'] }, <<EOF ],
#define WIN32_NO_STATUS
#include <windows.h>
#undef WIN32_NO_STATUS

#include <winternl.h>
#include <ntstatus.h>
#include <bcrypt.h>

int main(void)
{
        char buf[16];
        int r = BCryptGenRandom(NULL, buf, sizeof(buf), BCRYPT_USE_SYSTEM_PREFERRED_RNG);
        return 0;
}
EOF
	[ 'rdrandom64 in immintrin.h', 'RDRAND64', { extra_compiler_flags => [ '-mrdrnd' ] }, <<EOF ],
#include <immintrin.h>

int main(void) {
	char buf[16];
	int i;
	for (i = 0; i < sizeof buf; i+= sizeof(unsigned long long))
		_rdrand64_step((unsigned long long*)(buf + i));
}
EOF
	[ 'rdrandom32 in immintrin.h', 'RDRAND32', { extra_compiler_flags => [ '-mrdrnd' ] }, <<EOF ],
#include <immintrin.h>

int main(void) {
	char buf[16];
	int i;
	for (i = 0; i < sizeof buf; i+= sizeof(unsigned long))
		_rdrand32_step((unsigned *)(buf + i));
}
EOF
);

for my $possibility (@possibilities) {
	my ($name, $define, $options, $code) = @{ $possibility };
	if (try_compile_run(source => $code, define => "HAVE_\U$define", %$options, quiet => 1, push_args => 1)) {
		print "Found $name\n";
		last;
	}
}

die "No suitable implementation found" unless defines() > 0;

add_xs(%options);
