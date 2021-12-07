use strict; use warnings;

use Test::More tests => 2;
use Errno qw( ENOSYS );

BEGIN { *Async::fork = sub { $! = ENOSYS; () } }

use Async;

my $proc = Async->new( sub {} );
is $proc, undef, "undefined Async instance";

my $error = "Couldn't fork: " . do { local $! = ENOSYS };
like $Async::ERROR, qr/\A\Q$error\E/, $error;
