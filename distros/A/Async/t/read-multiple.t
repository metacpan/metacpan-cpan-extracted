use strict; use warnings;

use Test::More tests => 6;

use Async;

my $expected_greeting = '1' x 8192 . 'Hello, world!';
my $proc = Async->new( sub { $expected_greeting } );
isa_ok $proc, 'Async';

is $proc->result, undef, 'async process is incomplete (no force completion requested)';

ok $proc->ready(1), 'waiting until ready';

is $proc->error, undef, 'no error encountered';

is $proc->result, $expected_greeting, 'the return value of the task';

ok $proc->ready, 'asynchronous process keeps ready';
