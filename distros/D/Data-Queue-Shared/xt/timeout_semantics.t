use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);

# Timeout semantics:
#   pop_wait(0)    == try_pop (immediate, never blocks)
#   pop_wait(-1)   == blocks forever (we'd deadlock — skip that)
#   pop_wait(0.5)  == blocks up to 500ms

use Data::Queue::Shared::Int;

my $q = Data::Queue::Shared::Int->new_memfd("to", 8);

# timeout=0 on empty: immediate undef
my $t0 = time;
my $r = $q->pop_wait(0);
my $el = time - $t0;
ok !defined $r, "pop_wait(0) on empty returns undef";
cmp_ok $el, '<', 0.05, "pop_wait(0) returns in <50ms (${\sprintf '%.3fms', $el*1000})";

# timeout=0 equivalent to try_pop
$q->push(7);
$r = $q->pop_wait(0);
is $r, 7, "pop_wait(0) returns available item";

# timeout=0.3: blocks up to 300ms
$t0 = time;
$r = $q->pop_wait(0.3);
$el = time - $t0;
ok !defined $r, "pop_wait(0.3) on empty returns undef after timeout";
cmp_ok $el, '>=', 0.25, "pop_wait(0.3) waited at least 250ms (${\sprintf '%.3f', $el}s)";
cmp_ok $el, '<=', 1.0, "pop_wait(0.3) returned before 1s";

# Very small timeout: sub-second precision
$t0 = time;
$q->pop_wait(0.05);
$el = time - $t0;
cmp_ok $el, '>=', 0.03, "pop_wait(0.05) ~= 30-500ms (${\sprintf '%.3f', $el}s)";
cmp_ok $el, '<=', 0.5, "pop_wait(0.05) returned within 500ms";

done_testing;
