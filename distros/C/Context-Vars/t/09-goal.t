#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# The owner's goal, from plan_context_vars/00-overview.md, as written: the
# warn of a Dumper is the only change, made an is().

use Context::Vars q{$thing};

$thing = 'okay';

sub change {
        $thing = 'two';
}

change();

is($thing, 'okay', 'after change() the file code reads okay');

# The same, looking inside, so that this fails if the assignment were simply
# dropped rather than scoped.
my @seen;
sub change_and_look {
    push @seen, $thing;
    $thing = 'two';
    push @seen, $thing;
}
change_and_look();
is_deeply(\@seen, ['okay', 'two'], 'inside, okay before the assignment and two after it');
is($thing, 'okay', 'and okay again once it has returned');

is(Context::Vars::_scope_kind(\&change), 1, 'change opens its scope with its first statement');
is(Context::Vars::_depth(), 0, 'no scope is left open');
is(Context::Vars::_live_holders(), 0, 'and no holder is out');

done_testing;
