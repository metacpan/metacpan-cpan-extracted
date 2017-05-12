use strict;
use warnings;
use Errno;
use BSD::Socket::Splice 'getsplice';

use Test::More tests => 5;

eval { getsplice() };
like($@, qr/^Usage: BSD::Socket::Splice::getsplice\(so\) /,
    "getsplice function does not take 0 arguments");

eval { getsplice("foo", "bar") };
like($@, qr/^Usage: BSD::Socket::Splice::getsplice\(so\) /,
    "getsplice function does not take 2 arguments");

eval { getsplice("foo") };
like($@, qr/^Bad filehandle: foo /, "getsplice function needs 1 filehandle");

ok(!defined(getsplice(\*STDIN)), "getsplice function needs socket");
ok($!{ENOTSOCK}, "getsplice function failed: $!");
