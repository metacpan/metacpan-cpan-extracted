use strict; use warnings;

use Test::More tests => 4;
use Errno qw( EFAULT );

BEGIN { # compat shim for old Test::More
	defined &note or *note = sub { local $TODO = 1; &diag };
}

BEGIN { *Async::read = sub { $! = EFAULT; () } }

use Async;

my $proc = Async->new( sub { select undef, undef, undef, 0.5; 'Hello, world!' } );
isa_ok $proc, 'Async';

my $ready;
for ( 1 .. 10 ) {
	last if $ready = $proc->ready;
	note 'next polling in 250 milliseconds';
	select undef, undef, undef, 0.25;
}
ok $ready, 'waiting until ready';

my $error = 'Read error: ' . do { local $! = EFAULT };
like $proc->error, qr/\A\Q$error\E/, $error;

ok $proc->ready, 'asynchronous process keeps ready';
