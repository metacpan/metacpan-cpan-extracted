#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Context::Vars qw($sh);

# run makes the object ITSELF current, so a change that no sub scope undoes
# stays in it for the next run. A change made in a sub is undone when the
# sub returns, as anywhere.

sub held_in { my ($ctx) = @_; $ctx->get('sh') }

my ($c1, $c2);
sub take { $sh = 'start'; $c1 = Context::Vars->capture; $c2 = Context::Vars->capture }
take();

# A write through a for alias is one the compile pass cannot see, so no
# scope undoes it. (Taking \$sh would count as a write and give the code a
# scope of its own.)
$c1->run(sub { for my $alias ($sh) { $alias = 'changed through an alias' } });
is(held_in($c1), 'changed through an alias', 'a write no sub scope undoes stays in the object');
is($c1->run(sub { $sh }), 'changed through an alias', 'and the next run sees it');
is(held_in($c2), 'start', 'another capture of the same moment does not');

$c1->run(sub { $sh = 'in a sub' });
is(held_in($c1), 'changed through an alias', 'an assignment written in the code is undone when the code returns');
$c1->run(sub { my $r = \$sh; $$r = 'through a reference' });
is(held_in($c1), 'changed through an alias', 'and so is a write through a reference the code took');

$c1->run(sub { Context::Vars::_t_store(sh => 'stored'); });
is($c1->run(sub { $sh }), 'stored', 'a store into the current context while it runs is kept');

# current: the context running now, not a copy.
{
    my @seen;
    sub outer {
        $sh = 'outer value';
        my $here = Context::Vars->current;
        my $copy = Context::Vars->capture;
        Context::Vars::_t_store(sh => 'stored later');
        push @seen, $here->get('sh'), $copy->get('sh');
    }
    outer();
    is_deeply(\@seen, ['stored later', 'outer value'],
              'current follows the context it names; capture keeps its moment');
}

is(Context::Vars::_depth(), 0, 'no context is left entered');

done_testing;
