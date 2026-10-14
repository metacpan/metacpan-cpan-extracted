#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Context::Vars qw($wr);

# wrap: a callback that runs with the values of the moment it was wrapped,
# afresh on every call.

my @queue;
sub later { push @queue, Context::Vars->wrap($_[0]) }

sub request {
    my ($id) = @_;
    $wr = $id;
    later(sub { "callback for $id reads $wr, args @_" });
}
request('A');
request('B');
$wr = 'top';
is($queue[1]->('x'), 'callback for B reads B, args x', 'the second callback reads B');
is($queue[0]->('y'), 'callback for A reads A, args y', 'the first reads A, whatever ran before it');
is($wr, 'top', 'and the caller reads its own afterwards');

# Each call is fresh.
my $count_cb;
sub make_counter { $wr = 0; $count_cb = Context::Vars->wrap(sub { for my $x ($wr) { $x = $x + 1 } $wr }) }
make_counter();
is($count_cb->(), 1, 'the first call');
is($count_cb->(), 1, 'the second does not see the first call\'s change');

# Contexts and return values pass through.
my $w = Context::Vars->wrap(sub { wantarray ? 'list' : 'scalar' });
my @l = $w->(); my $s = $w->();
is("@l $s", 'list scalar', 'the caller\'s context reaches the wrapped code');
is_deeply([Context::Vars->wrap(sub { @_ })->(1, 2, 3)], [1, 2, 3], 'all arguments pass through');

# A die.
my $dier = Context::Vars->wrap(sub { die "wrapped\n" });
ok(!eval { $dier->(); 1 }, 'a die in wrapped code propagates');
is($@, "wrapped\n", 'unchanged');
is(Context::Vars::_depth(), 0, 'and nothing is left entered');

# Refusals and lifetime.
ok(!eval { Context::Vars->wrap('not code'); 1 }, 'wrap refuses something that is not code');
like($@, qr/^Context::Vars::wrap: not a code reference/, 'by name');
{
    my $destroyed = 0;
    { package W::Probe; sub DESTROY { $destroyed++ } }
    my $cb;
    {
        my $probe = bless {}, 'W::Probe';
        sub keep { $wr = $_[0]; $cb = Context::Vars->wrap(sub { 1 }) }
        keep($probe);
    }
    is($destroyed, 0, 'a wrapped callback keeps the values it captured alive');
    undef $cb;
    is($destroyed, 1, 'and lets them go when it is freed');
}
cmp_ok(Context::Vars::_live_holders(), '>', 0, 'the callbacks still held keep their captures');
@queue = ();
undef $_ for $count_cb, $w, $dier;
is(Context::Vars::_live_holders(), 0, 'and once they go no holder is out');

done_testing;
