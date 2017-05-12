use strict;
use warnings;
use Config;
use Errno;
use BSD::Socket::Splice 'setsplice';

use Test::More tests => 115;

eval { setsplice() };
like($@, qr/^Usage: BSD::Socket::Splice::setsplice\(so, ...\) /,
    "setsplice function does not take 0 arguments");

eval { setsplice("foo") };
like($@, qr/^Bad filehandle: foo /, "setsplice function needs 1 filehandle");

eval { setsplice("foo", "bar") };
like($@, qr/^Bad filehandle: foo /, "setsplice function needs filehandles");

eval { setsplice(\*STDIN, "bar") };
like($@, qr/^Bad filehandle: bar /, "setsplice function needs 2 filehandles");

eval { setsplice(\*STDIN, \*STDOUT, "foobar") };
like($@, qr/^Non numeric max value for setsplice /,
    "setsplice function needs numeric 3rd argument");

eval { setsplice(\*STDIN, \*STDOUT, 0, "foobar") };
like($@, qr/^Non numeric idle value for setsplice /,
    "setsplice function needs numeric 4th argument");

eval { setsplice(\*STDIN, \*STDOUT, 0, 0, "foobar") };
like($@, qr/^Too many arguments for setsplice /,
    "setsplice function does not take 5 arguments");

ok(!defined(setsplice(\*STDIN)), "setsplice function needs 1 socket");
ok($!{ENOTSOCK}, "setsplice function failed: $!");

ok(!defined(setsplice(\*STDIN, \*STDOUT)), "setsplice function needs sockets");
ok($!{ENOTSOCK}, "setsplice function failed: $!");

ok(!defined(setsplice(\*STDIN, \*STDOUT, 1)),
    "setsplice function with max needs sockets");
ok($!{ENOTSOCK}, "setsplice function with max failed: $!");

ok(!defined(setsplice(\*STDIN, \*STDOUT, 1, 1)),
    "setsplice function with max and idle needs sockets");
ok($!{ENOTSOCK}, "setsplice function with max and idle failed: $!");

ok(!defined(setsplice(\*STDIN, \*STDOUT, undef, 1)),
    "setsplice function with undef max");
ok($!{ENOTSOCK}, "setsplice function with undef max failed: $!");

ok(!defined(setsplice(\*STDIN, \*STDOUT, 1, undef)),
    "setsplice function with undef idle");
ok($!{ENOTSOCK}, "setsplice function with undef idle failed: $!");

ok(!defined(setsplice(\*STDIN, \*STDOUT, undef, undef)),
    "setsplice function with undef max and idle");
ok($!{ENOTSOCK}, "setsplice function with undef max and idle failed: $!");

ok(!defined(setsplice(\*STDIN, \*STDOUT, 0, 0)),
    "setsplice function with 0 max and idle");
ok($!{ENOTSOCK}, "setsplice function with 0 max and idle failed: $!");

my @max_fail = qw(2**70 2**64
    -2**32 -4294967295 -3000000000 -2147483648 -2147483647
    -0.3 -0.8 -1.0 -1 -1.3 -2**62 -2**63+1 -2**63 -2**64);
my @max_ok = qw(2**62 2**32+1 2**32 2**32-1 4294967297 4294967296 4294967295
    3000000000 2**31+1 2**31 2**31-1 2147483649 2147483648 2147483647
    2 1.8 1.5 1.3 1.0 1 0.8 0.5 0.3 0.0 0 -0.0 -0);

if ($Config{ARCH} eq "sparc64") {
    # sparc has better conversion from double to int
    push @max_ok, qw(2**63+1 2**63 2**63-1)
} else {
    push @max_fail, qw(2**63+1 2**63 2**63-1)
}

foreach my $max (@max_fail) {
    undef $!;
    setsplice(\*STDIN, \*STDOUT, eval $max);
    ok($!{EINVAL}, "setsplice max $max failed: $!");
}

foreach my $max (@max_ok) {
    undef $!;
    setsplice(\*STDIN, \*STDOUT, eval $max);
    ok($!{ENOTSOCK}, "setsplice max $max succeeded");
}

my @idle_fail = qw(2**70 2**64
    -2**32 -4294967295 -3000000000 -2147483648 -2147483647
    -0.3 -0.8 -1.0 -1 -1.3 -2**62 -2**63+1 -2**63 -2**64);
my @idle_ok = qw(
    2**31-1
    2147483647
    2 1.8 1.5 1.3 1.0 1 0.8 0.5 0.3 0.0 0 -0.0 -0);

if ($Config{ARCH} eq "sparc64") {
    # sparc has better conversion from double to int
    push @max_ok, qw(2**63+1 2**63 2**63-1)
} else {
    push @max_fail, qw(2**63+1 2**63 2**63-1)
}
if ($Config{longsize} == 8) {
    push @idle_ok, qw(2**62 2**32+1 2**32 2**32-1
	4294967297 4294967296 4294967295 3000000000
	2**31+1 2**31 2147483649 2147483648);
} else {
    push @idle_fail, qw(2**62 2**32+1 2**32 2**32-1
	4294967297 4294967296 4294967295 3000000000
	2**31+1 2**31 2147483649 2147483648);
}

foreach my $idle (@idle_fail) {
    undef $!;
    setsplice(\*STDIN, \*STDOUT, undef, eval $idle);
    ok($!{EINVAL}, "setsplice idle $idle failed: $!");
}

foreach my $idle (@idle_ok) {
    undef $!;
    setsplice(\*STDIN, \*STDOUT, undef, eval $idle);
    ok($!{ENOTSOCK}, "setsplice idle $idle succeeded");
}

use IO::Socket::INET;
my $sl = IO::Socket::INET->new(
    Proto => "tcp",
    Listen => 5,
    LocalAddr => "127.0.0.1",
) or die "socket listen failed: $!";

my $s = IO::Socket::INET->new(
    Proto => "tcp",
    PeerAddr => $sl->sockhost(),
    PeerPort => $sl->sockport(),
) or die "socket connect failed: $!";

my $ss = IO::Socket::INET->new(
    Proto => "tcp",
    PeerAddr => $sl->sockhost(),
    PeerPort => $sl->sockport(),
) or die "socket splice connect failed: $!";

ok(!defined(setsplice($s, \*STDIN)), "setsplice function needs 2 sockets");
ok($!{ENOTSOCK}, "setsplice function failed: $!");

ok(defined(setsplice($s, $ss)), "setsplice with 2 sockets failed: $!");
