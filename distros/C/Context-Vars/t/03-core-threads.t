#!perl
use 5.010;
use strict;
use warnings;
use Config;
BEGIN {
    unless ($Config{useithreads} && eval { require threads; 1 }) {
        require Test::More;
        Test::More::plan(skip_all => 'this perl has no ithreads');
    }
}
use threads;
use Test::More;
use Context::Vars qw($tv);

# A new thread has its own empty context and nothing of its parent's. The
# threads here run one at a time: the parent waits in join.

sub fetch { (Context::Vars::_t_fetch($_[0]))[0] }

my $parent_empty = Context::Vars::_t_current();

Context::Vars::_t_scope(sub {
    Context::Vars::_t_store(who => 'parent');

    my @got = threads->create({ context => 'list' }, sub {
        my @r;
        push @r, Context::Vars::_t_is_empty() ? 1 : 0;
        push @r, Context::Vars::_depth();
        push @r, Context::Vars::_live_holders();
        push @r, defined fetch('who') ? 'saw the parent' : 'saw nothing';
        Context::Vars::_t_scope(sub {
            Context::Vars::_t_store(who => 'child');
            push @r, fetch('who');
        });
        push @r, Context::Vars::_t_is_empty() ? 1 : 0;
        push @r, Context::Vars::_selftest_core();
        push @r, Context::Vars::_live_holders();
        return @r;
    })->join;

    is($got[0], 1, 'a new thread starts in its own empty context, though its parent was inside a scope');
    is($got[1], 0, 'with nothing entered');
    is($got[2], 0, 'and no holder out');
    is($got[3], 'saw nothing', 'it does not see the parent\'s value');
    is($got[4], 'child', 'it stores and reads its own');
    is($got[5], 1, 'and is back in its empty context afterwards');
    is($got[6], 0, 'the core selftest passes in the thread');
    is($got[7], 0, 'and leaves no holder out there');

    is(fetch('who'), 'parent', 'the parent still reads its own value');
    is(Context::Vars::_depth(), 1, 'and is still inside its scope');
});

# ---- the variables ----------------------------------------------------------------
Context::Vars::_t_scope(sub {
    $tv = 'parent value';
    local $tv = 'parent local';
    is(Context::Vars::_locals(), 1, 'the parent has a local outstanding when the thread starts');
    my @got = threads->create({ context => 'list' }, sub {
        my @r;
        push @r, Context::Vars::_locals();
        push @r, defined $tv ? $tv : 'undef';
        push @r, Context::Vars::_is_var(\$tv) ? 1 : 0;
        Context::Vars::_t_scope(sub { $tv = 'child value'; push @r, $tv });
        {
            package T::Late;
            Context::Vars->import('$tv', '$fresh_in_thread');
            no strict 'vars';
            no warnings 'once';
            Context::Vars::_t_scope(sub {
                $T::Late::fresh_in_thread = 'new';
                $T::Late::tv = 'through T::Late';
                push @r, $T::Late::fresh_in_thread . '/' . $main::tv;
            });
        }
        { local $tv = 'top local'; push @r, $tv }
        push @r, Context::Vars::_locals();
        return @r;
    })->join;
    shift(@got) == 0
        ? pass('a new thread starts with nothing displaced by local, whatever its parent had')
        : fail('a new thread starts with nothing displaced by local, whatever its parent had');
    is($got[0], 'undef', 'a variable in a new thread reads nothing of the parent\'s');
    is($got[1], 1, 'and is still a variable there');
    is($got[2], 'child value', 'it is assigned and read in the thread');
    is($got[3], 'new/through T::Late', 'a name imported in the thread works, and an old name imported there is the same variable');
    is($got[4], 'top local', 'local works in the thread');
    is($got[5], 0, 'and leaves nothing displaced there');
    is($tv, 'parent local', 'the parent reads its own local value afterwards');
});

is(Context::Vars::_t_current(), $parent_empty, 'the parent is back in its empty context');
is(Context::Vars::_live_holders(), 0, 'with no holder out');

done_testing;
