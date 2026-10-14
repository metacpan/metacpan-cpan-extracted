#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Context::Vars qw($e);

# However a sub with an assignment is left, the caller gets its own value
# back, and nothing stays entered or allocated.

$e = 'base';
sub settled {
    my ($what) = @_;
    is($e, 'base', "$what: the caller's value is back");
    is(Context::Vars::_depth(), 0, "$what: no scope is left open");
    is(Context::Vars::_live_holders(), 0, "$what: no holder is out");
}

sub falls_off { $e = 'x'; 1 }
falls_off(); settled('falling off the end');

sub returns { $e = 'x'; return 1; }
returns(); settled('return');

sub returns_nested { $e = 'x'; if (1) { for my $i (1 .. 3) { return $i if $i == 2 } } 0 }
is(returns_nested(), 2, 'return from inside a loop inside an if');
settled('return from a nested block');

sub dies { $e = 'x'; die "boom\n" }
eval { dies() };
is($@, "boom\n", 'die propagates unchanged');
settled('die caught by an outer eval');

sub dies_deep { $e = 'x'; inner_die() }
sub inner_die { $e = 'y'; die "deep\n" }
eval { dies_deep() };
settled('die through two subs that each assigned');

sub last_out { $e = 'x'; no warnings 'exiting'; last }
for my $i (1 .. 3) { last_out() }
settled('last out of the caller\'s loop');

sub next_out { $e = 'x'; no warnings 'exiting'; next }
for my $i (1 .. 3) { next_out() }
settled('next in the caller\'s loop');

my $target_saw;
sub target { $target_saw = $e; 'from target' }
sub jumper { $e = 'x'; goto &target }
is(jumper(), 'from target', 'goto &other returns the target\'s value');
is($target_saw, 'base', 'the jumping sub\'s scope closed before the target ran');
settled('goto &other');

sub evals_inside { $e = 'x'; eval { $e = 'y'; die "in\n" }; $e }
is(evals_inside(), 'y', 'an eval block inside the sub is part of the sub\'s scope');
settled('eval block inside');

sub sorts { $e = 'x'; my @s = sort { $a <=> $b } 3, 1, 2; "@s" }
is(sorts(), '1 2 3', 'a sort block inside');
settled('sort inside');

sub wants { $e = 'x'; wantarray ? 'list' : 'scalar' }
my @l = wants(); my $s = wants();
is("$l[0] $s", 'list scalar', 'context reaches the sub');
settled('called in list and scalar context');

# A goto back to a label. On the first statement, the label means the scope
# cannot be opened by that statement, or each jump would open another.
our $jumps;
sub jumps_to_first { FIRST: $e = 'j' . $jumps--; goto FIRST if $jumps > 0; $e }
sub jumps_to_later { my $n = shift; my $i = 0; AGAIN: $e = 'k' . ++$i; goto AGAIN if $i < $n; $e }
{
    my $before = Context::Vars::_scopes();
    is(Context::Vars::_scope_kind(\&jumps_to_first), 2, 'a sub whose first statement has a label gets an op of its own');
    $jumps = 50;
    is(jumps_to_first(), 'j1', 'a goto back to a label on the first statement');
    is(Context::Vars::_scopes() - $before, 1, 'opens the scope once, not once a jump');
    $before = Context::Vars::_scopes();
    is(jumps_to_later(50), 'k50', 'a goto back to a label later in the sub');
    is(Context::Vars::_scopes() - $before, 1, 'opens it once too');
}
settled('goto LABEL');
sub labelled_first { FIRST: $e = 'labelled'; $e }
is(labelled_first(), 'labelled', 'a sub with a label on its first statement sees its own write');
settled('a label on the first statement');

# Under op debugging every statement is a debugger statement, and the scope
# is opened by that instead.
{
    my $r = system($^X, (map { "-I$_" } grep { !ref } @INC), '-e', q{
        BEGIN { $^P = 0x33f; sub DB::DB {} }
        use Context::Vars qw($e);
        $e = 'base';
        sub change { $e = 'two'; $e }
        my $in = change();
        exit(($in eq 'two' && $e eq 'base' && Context::Vars::_scope_kind(\&change) == 1
              && Context::Vars::_depth() == 0) ? 0 : 1);
    });
    is($r >> 8, 0, 'a sub compiled under op debugging is scoped by its debugger statement');
}

# An uncaught die unwinds the save stack before END blocks run, so an END
# block in the dying process sees the scope closed.
{
    my $r = system($^X, (map { "-I$_" } grep { !ref } @INC), '-e', q{
        use Context::Vars qw($e);
        $e = 'base';
        END { $? = ($e eq 'base' && Context::Vars::_depth() == 0) ? 0 : 3 }
        sub dies_uncaught { $e = 'x'; die "uncaught\n" }
        close STDERR;
        dies_uncaught();
    });
    is($r >> 8, 0, 'a die nobody catches still closes the scope before END blocks run');
}

done_testing;
