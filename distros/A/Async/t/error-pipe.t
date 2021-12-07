use strict; use warnings;

use Test::More tests => 2;
use Errno qw( EFAULT );

BEGIN { *Async::pipe = sub { $! = EFAULT; () } }

use Async;

my $proc = Async->new( sub {} );
is $proc, undef, "undefined Async instance";

my $error = "Couldn't make pipe: " . do { local $! = EFAULT };
like $Async::ERROR, qr/\A\Q$error\E/, $error;
