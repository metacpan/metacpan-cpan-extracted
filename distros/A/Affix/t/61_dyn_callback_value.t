use strict;
use Test::More 0.98;
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
use Dyn::Callback;
$|++;
#
my $v = Dyn::Callback::Value->new();
isa_ok $v, 'Dyn::Callback::Value';
#
can_ok $v, $_ for qw[B c C s S i I j J l L f d p Z];
#
is $v->B( !0 ), !0, '->B = !0';
is $v->B,       !0, '->B == !0';
is $v->B( !1 ), !1, '->B = !1';
is $v->B,       !1, '->B == !1';
#
is $v->c('X'),  88,   '->c = X';
is $v->c,       88,   '->c == 88';     # note the internal char => int
is $v->c(-100), -100, '->c = -100';
is $v->c,       -100, '->c == -100';
#
isn't $v->C(-100), -100, '->C != -100';    # note signed => unsigned
isn't $v->C,       -100, '->C != -100';
#
isa_ok $v->p, 'Dyn::Call::Pointer';        # This actually points to nothing
#
is $v->Z('Hi'), 'Hi', '->Z = "Hi"';
is $v->Z,       'Hi', '->Z == "Hi"';
#
done_testing;
