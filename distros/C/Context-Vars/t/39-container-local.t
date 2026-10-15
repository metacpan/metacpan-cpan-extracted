#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# local on whole containers and on elements, inside subs and in bare blocks
# outside any sub.
use Context::Vars qw(%seen @trail);

%seen = (k => 'outer', other => 1);
@trail = ('outer0', 'outer1');
sub look { join '|', $seen{k} // 'undef', scalar(keys %seen), $trail[0] // 'undef', scalar(@trail) }
my $outer = look();

my @r;
for my $case (
    [ 'local %seen'      => sub { local %seen = (k => 'inner'); push @r, look() } ],
    [ 'local @trail'     => sub { local @trail = ('inner'); push @r, look() } ],
    [ 'local $seen{k}'   => sub { local $seen{k} = 'inner'; push @r, look() } ],
    [ 'local $trail[0]'  => sub { local $trail[0] = 'inner'; push @r, look() } ],
) {
    my ($name, $code) = @$case;
    @r = ();
    my $ok = eval { $code->(); 1 };
    my $after = look();
    ok($ok, "S8 $name: runs") or diag $@;
    is($after, $outer, "S8 $name: the outer values are back afterwards");
}
# A whole-container local is a context local: another package, a capture and
# a callback see the local values while the block runs.
{ package L::Other; use Context::Vars qw(%seen @trail); sub look { ($seen{k} // 'undef') . '/' . ($trail[0] // 'undef') } }
{
    local %seen = (k => 'block');
    local @trail = ('block0');
    is(L::Other::look(), 'block/block0', 'S8: another package sees the local values of the whole containers');
    my $cap = Context::Vars->capture;
    is($cap->get('%seen')->{k}, 'block', 'S8: so does a capture taken in the block');
    $seen{added} = 1;
    is(L::Other::look(), 'block/block0', 'S8: and a write into the local container is the context\'s');
}
is(L::Other::look(), 'outer/outer0', 'S8: after the block, everyone sees the outer values');
ok(!exists $seen{added}, 'S8: and what was written into the local container is gone');

# The same in bare blocks outside any sub, where no sub scope does the undoing.
{ local %seen = (k => 'block'); is($seen{k}, 'block', 'S8: local %seen in a bare block'); }
is(look(), $outer, 'S8: and the outer values are back after the block');
{ local @trail = ('block'); is($trail[0], 'block', 'S8: local @trail in a bare block'); }
is(look(), $outer, 'S8: back after the block');
{ local $seen{k} = 'block'; is($seen{k}, 'block', 'S8: local $seen{k} in a bare block'); }
is(look(), $outer, 'S8: back after the block');
{ local $seen{absent} = 'x'; is($seen{absent}, 'x', 'S8: local on an element that did not exist'); }
ok(!exists $seen{absent}, 'S8: which does not exist after the block');
{ local $trail[0] = 'block'; is($trail[0], 'block', 'S8: local $trail[0] in a bare block'); }
is(look(), $outer, 'S8: back after the block');
eval { local %seen = (k => 'dying'); die "x\n" };
is(look(), $outer, 'S8: local %seen is undone by a die');
{ local %seen = (k => 'a'); { local %seen = (k => 'b'); is($seen{k}, 'b', 'S8: nested local'); } is($seen{k}, 'a', 'S8: inner undone'); }
is(look(), $outer, 'S8: both undone');

done_testing;
