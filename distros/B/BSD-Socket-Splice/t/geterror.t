use strict;
use warnings;
use Errno;
use Fcntl;
use Socket;
use BSD::Socket::Splice 'geterror';

use Test::More tests => 7;

eval { geterror() };
like($@, qr/^Usage: BSD::Socket::Splice::geterror\(so\) /,
    "geterror function does not take 0 arguments");

eval { geterror("foo", "bar") };
like($@, qr/^Usage: BSD::Socket::Splice::geterror\(so\) /,
    "geterror function does not take 2 arguments");

eval { geterror("foo") };
like($@, qr/^Bad filehandle: foo /, "geterror function needs 1 filehandle");

ok(!defined(geterror(\*STDIN)), "geterror function needs socket");
ok($!{ENOTSOCK}, "geterror function failed: $!");

socket(my $so, AF_INET, SOCK_STREAM, PF_UNSPEC)
    or die "socket failed: $!";

ok(defined(geterror($so)), "geterror from socket succeeded");
is(geterror($so), 0, "geterror from fresh socket is 0");
