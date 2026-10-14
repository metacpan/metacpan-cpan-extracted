#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Context::Vars qw($req $user);

# Two contexts used in turn: what is assigned in one is never read in the
# other. Every assertion names both values, so a test would fail if one
# context's value leaked into the other.

sub log_line { sprintf '[%s %s] %s', $req // 'no-req', $user // 'no-user', $_[0] }

my ($a_ctx, $b_ctx);
Context::Vars::_t_scope(sub { $req = 'A'; $user = 'alice'; $a_ctx = Context::Vars::_t_capture() });
Context::Vars::_t_scope(sub { $req = 'B';                  $b_ctx = Context::Vars::_t_capture() });

my @lines;
for my $round (1 .. 3) {
    Context::Vars::_t_enter($a_ctx, sub { push @lines, log_line("a$round") });
    Context::Vars::_t_enter($b_ctx, sub { push @lines, log_line("b$round") });
}
is_deeply(\@lines, [
    '[A alice] a1', '[B no-user] b1',
    '[A alice] a2', '[B no-user] b2',
    '[A alice] a3', '[B no-user] b3',
], 'each context reads its own request and user, in alternation');

# A store into B itself. An assignment written inside this callback would be
# scoped to the callback and end with it.
Context::Vars::_t_enter($b_ctx, sub { Context::Vars::_t_store(user => 'bob') });
Context::Vars::_t_enter($a_ctx, sub { is(log_line('x'), '[A alice] x', 'an assignment in B did not reach A') });
Context::Vars::_t_enter($b_ctx, sub { is(log_line('y'), '[B bob] y', 'and B keeps it') });

Context::Vars::_t_enter($a_ctx, sub {
    Context::Vars::_t_enter($b_ctx, sub { is(log_line('in'), '[B bob] in', 'B entered inside A reads B') });
    is(log_line('out'), '[A alice] out', 'and A is back after it');
});

ok(!defined $req, 'outside both, nothing is set');
ok(!Context::Vars::_has_program(), 'and no program context was made');

Context::Vars::_t_release($_) for $a_ctx, $b_ctx;
is(Context::Vars::_depth(), 0, 'nothing is left entered');
is(Context::Vars::_live_holders(), 0, 'and no holder is out');

done_testing;
