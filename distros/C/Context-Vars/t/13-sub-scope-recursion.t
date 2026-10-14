#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Context::Vars qw($r);

# Each level of a recursion has its own scope, and they unwind in order.

$r = 'base';
my @on_the_way_out;
sub rec {
    my ($n) = @_;
    $r = "level$n";
    rec($n - 1) if $n > 1;
    push @on_the_way_out, $r;
    return;
}
{ no warnings 'recursion'; rec(200); }
is(scalar @on_the_way_out, 200, 'two hundred levels');
is_deeply(\@on_the_way_out, [map { "level$_" } 1 .. 200], 'each read its own value after its callee returned');
is($r, 'base', 'and the caller reads its own');

# Mutual recursion, and a level that reads without assigning.
my @seen;
sub ping { my $n = shift; $r = "ping$n"; pong($n - 1) if $n; push @seen, $r }
sub pong { my $n = shift; push @seen, "pong sees $r"; ping($n - 1) if $n }
ping(3);
is_deeply(\@seen, ['pong sees ping3', 'pong sees ping1', 'ping1', 'ping3'],
          'a sub that only reads sees its caller\'s value, through mutual recursion');
is(Context::Vars::_scope_kind(\&pong), 0, 'and has no scope of its own');

is(Context::Vars::_depth(), 0, 'no scope is left open');
is(Context::Vars::_live_holders(), 0, 'and no holder is out');

done_testing;
