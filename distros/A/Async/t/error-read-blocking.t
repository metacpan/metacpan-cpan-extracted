use strict; use warnings;

use Test::More tests => 4;
use Errno qw( EFAULT );

BEGIN { *Async::read = sub { $! = EFAULT; () } }

use Async;

my $proc = Async->new( sub { 'Hello, world!' } );
isa_ok $proc, 'Async';

ok $proc->ready(1), 'waiting until ready';

my $error = 'Read error: ' . do { local $! = EFAULT };
like $proc->error, qr/\A\Q$error\E/, $error;

ok $proc->ready, 'asynchronous process keeps ready';
