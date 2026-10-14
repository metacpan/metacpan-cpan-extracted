#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Context::Vars;
use HAMT;

# The context core, through the test doors: which context is current, that it
# is put back by every way out, and that nothing is left behind. Each group
# ends by checking the three counts a leak would move.

my $C = 'Context::Vars';
sub cur     { Context::Vars::_t_current() }
sub fetch   { (Context::Vars::_t_fetch($_[0]))[0] }
sub has     { (Context::Vars::_t_fetch($_[0]))[1] ? 1 : 0 }
sub store   { Context::Vars::_t_store(@_) }
sub scope   { Context::Vars::_t_scope($_[0]) }

my $empty   = cur();
my $holders = Context::Vars::_live_holders();
my $blocks  = HAMT::_live_blocks();

sub settled {
    my ($what) = @_;
    is(cur(), $empty, "$what: the empty context is current again");
    is(Context::Vars::_depth(), 0, "$what: nothing is entered");
    is(Context::Vars::_live_holders(), $holders, "$what: every holder was given back");
    is(HAMT::_live_blocks(), $blocks, "$what: and every node HAMT made for them");
}

ok(Context::Vars::_t_is_empty(), 'with nothing entered the empty context is current');
is($holders, 0, 'and no holder is out');

# ---- the C selftest ---------------------------------------------------------
is(Context::Vars::_selftest_core(), 0, 'the core selftest passes')
    or diag('the number is the check that failed in include/context_vars/context_vars_ctx_selftest.h');
settled('selftest');
is(Context::Vars::_selftest_core(), 0, 'and passes a second time, from the freelist');
cmp_ok(Context::Vars::_free_holders(), '>', 0, 'holders it gave back are kept for reuse');
settled('selftest again');

# ---- the empty context is never written -------------------------------------
{
    ok(!eval { store(a => 1); 1 }, 'a store with nothing entered is refused');
    like($@, qr/no context entered/, 'and says why');
    ok(!eval { Context::Vars::_t_remove('a'); 1 }, 'so is a remove');
    is(Context::Vars::_t_count(), 0, 'and the empty context holds nothing');
    ok(!has('a'), 'a name nobody set is not there');
    settled('empty');
}

# ---- a scope ----------------------------------------------------------------
{
    my @seen;
    scope(sub {
        is(cur(), $empty, 'a scope over nothing shares the empty context');
        is(Context::Vars::_live_holders(), $holders, 'and allocates nothing');
        is(Context::Vars::_depth(), 1, 'one enter is outstanding');
        store(a => 'one');
        isnt(cur(), $empty, 'the first store gives the scope a context of its own');
        is(Context::Vars::_live_holders(), $holders + 1, 'which is one holder');
        push @seen, fetch('a');
        is(Context::Vars::_t_count(), 1, 'it holds one name');
    });
    is_deeply(\@seen, ['one'], 'the code read what it stored');
    ok(!has('a'), 'and afterwards the name is not set');
    settled('scope');
}

# ---- nesting: each level starts with its parent's values and keeps its own ---
{
    my %at;
    scope(sub {
        store(a => 'outer');
        store(b => 'kept');
        my $outer = cur();
        scope(sub {
            $at{inner_start} = fetch('a');
            store(a => 'inner');
            Context::Vars::_t_remove('b');
            $at{inner_a} = fetch('a');
            $at{inner_has_b} = has('b');
            is(Context::Vars::_depth(), 2, 'two enters are outstanding');
        });
        is(cur(), $outer, 'leaving the inner scope puts the outer one back, the same holder');
        $at{outer_a} = fetch('a');
        $at{outer_b} = fetch('b');
    });
    is_deeply(\%at, { inner_start => 'outer', inner_a => 'inner', inner_has_b => 0,
                      outer_a => 'outer', outer_b => 'kept' },
              'the inner scope began with the outer values, and its changes stayed inside it');
    settled('nesting');
}

# ---- a die goes through the save stack ---------------------------------------
{
    ok(!eval { scope(sub { store(a => 1); die "out\n" }); 1 }, 'a die inside a scope propagates');
    is($@, "out\n", 'unchanged');
    settled('die in a scope');

    my $outer_after;
    scope(sub {
        store(a => 'outer');
        my $outer = cur();
        eval { scope(sub { store(a => 'inner'); scope(sub { store(a => 'innermost'); die "deep\n" }) }) };
        is($@, "deep\n", 'a die two scopes down is caught above them');
        is(cur(), $outer, 'and the scope that caught it is current, not the empty one');
        $outer_after = fetch('a');
    });
    is($outer_after, 'outer', 'with its own value');
    settled('die through two scopes');
}

# ---- values ------------------------------------------------------------------
{
    scope(sub {
        my $src = 'text';
        store(s => $src);
        $src = 'changed';
        is(fetch('s'), 'text', 'the value stored is a copy: changing the source does not change it');

        store(u => undef);
        ok(has('u'), 'an undef can be stored, and the name is then set');
        ok(!defined fetch('u'), 'and reads undef');
        is(Context::Vars::_t_count(), 2, 'which counts');
        Context::Vars::_t_remove('u');
        ok(!has('u'), 'a remove unsets it');
        Context::Vars::_t_remove('never');
        is(Context::Vars::_t_count(), 1, 'removing a name that is not set changes nothing');

        my $ref = [1, 2];
        store(r => $ref);
        push @$ref, 3;
        is_deeply(fetch('r'), [1, 2, 3], 'a stored reference shares what it refers to');

        store("k$_" => $_) for 1 .. 500;
        is(Context::Vars::_t_count(), 502, 'five hundred more names');
        is(join(',', map { fetch("k$_") } 1, 250, 500), '1,250,500', 'each reads its own');
    });
    settled('values');
}

# ---- a stored object lives as long as a context holds it ---------------------
{
    my $destroyed = 0;
    { package Probe; sub DESTROY { $destroyed++ } }
    my $kept;
    scope(sub {
        store(o => bless({}, 'Probe'));
        is($destroyed, 0, 'an object stored in a scope is alive inside it');
        $kept = Context::Vars::_t_capture();
    });
    is($destroyed, 0, 'and still alive after the scope, while a capture holds it');
    Context::Vars::_t_release($kept);
    is($destroyed, 1, 'and destroyed, once, when the last holder goes');
    settled('object lifetime');
}

# ---- capture ----------------------------------------------------------------
{
    my $c = Context::Vars::_t_capture();
    is($c, $empty, 'a capture with nothing entered is the empty context');
    is(Context::Vars::_live_holders(), $holders, 'and takes no holder');
    Context::Vars::_t_release($c);
    settled('capture of nothing');

    my ($cap, %r);
    scope(sub {
        store(a => 'at capture');
        $cap = Context::Vars::_t_capture();
        isnt($cap, cur(), 'a capture of something is a holder of its own');
        store(a => 'after capture');
        $r{scope_after} = fetch('a');
    });
    is(Context::Vars::_live_holders(), $holders + 1, 'the capture outlives the scope it was taken in');

    Context::Vars::_t_enter($cap, sub {
        is(cur(), $cap, 'entering it makes that holder current');
        $r{entered} = fetch('a');
        store(b => 'first run');
    });
    Context::Vars::_t_enter($cap, sub { $r{second_run_sees} = fetch('b') });
    Context::Vars::_t_enter_copy($cap, sub {
        isnt(cur(), $cap, 'entering a copy makes a different holder current');
        $r{copy_sees} = fetch('b');
        store(c => 'copy only');
    });
    Context::Vars::_t_enter_copy($cap, sub { $r{second_copy_has_c} = has('c') });
    Context::Vars::_t_enter($cap, sub { $r{holder_has_c} = has('c') });

    is_deeply(\%r, {
        scope_after       => 'after capture',
        entered           => 'at capture',
        second_run_sees   => 'first run',
        copy_sees         => 'first run',
        second_copy_has_c => 0,
        holder_has_c      => 0,
    }, 'a capture holds the values of its moment; enter shares the holder between runs, enter_copy does not');

    ok(!eval { Context::Vars::_t_enter($cap, sub { die "in capture\n" }); 1 }, 'a die inside an entered capture propagates');
    is(cur(), $empty, 'and the context is put back');
    Context::Vars::_t_release($cap);
    settled('capture');
}

# ---- many, interleaved --------------------------------------------------------
{
    my @caps;
    for my $n (1 .. 200) {
        scope(sub { store(id => "task$n"); push @caps, Context::Vars::_t_capture() });
    }
    is(Context::Vars::_live_holders(), $holders + 200, 'two hundred captures are held');
    my @got;
    for my $i (reverse 0 .. $#caps) {
        Context::Vars::_t_enter_copy($caps[$i], sub { push @got, fetch('id') });
    }
    is_deeply(\@got, [map { "task$_" } reverse 1 .. 200], 'each read its own id, whatever ran before it');
    Context::Vars::_t_release($_) for @caps;
    settled('two hundred captures');
}

done_testing;
