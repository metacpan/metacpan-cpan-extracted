#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Context::Vars qw($ref $other);

# A variable can hold a reference to a hash, an array, code or an object. The
# reference is the value: sub scope covers WHICH reference the variable
# holds, not what that reference points at. What it points at is shared by
# every context holding the same reference, as with any Perl reference.

$ref = { a => 1, list => [1, 2] };
my $original = $ref;

# ---- replacing the reference is scoped ----------------------------------
sub replace_hash { $ref = { a => 2 }; return $ref->{a} }
is(replace_hash(), 2, 'a sub that assigns a new hash reference reads it');
is($ref, $original, 'and when it returns the caller holds its own reference again');
is_deeply($ref, { a => 1, list => [1, 2] }, 'with its contents untouched');

sub replace_array { $ref = [9, 8]; return "@$ref" }
is(replace_array(), '9 8', 'the same for an array reference');
is($ref, $original, 'and the caller holds its own afterwards');

{
    local $ref = [3, 4];
    is_deeply($ref, [3, 4], 'local with an array reference');
}
is($ref, $original, 'and the caller\'s hash reference is back after the block');

# The case that was broken: the reference the sub assigned is freed when the
# sub returns, which must not disturb the caller's.
{
    my $destroyed = 0;
    { package R::Probe; sub DESTROY { $destroyed++ } }
    sub replace_with_object { $ref = bless {}, 'R::Probe'; 1 }
    replace_with_object();
    is($destroyed, 1, 'an object only a returned sub\'s scope held is destroyed when it returns');
    is($ref, $original, 'and the caller still holds its own reference');
}

# ---- changing what it points at is shared --------------------------------
sub mutate { $ref->{a} = 'changed'; push @{ $ref->{list} }, 3; return }
mutate();
is($ref->{a}, 'changed', 'a change made through the reference in a sub is seen after it returns');
is_deeply($ref->{list}, [1, 2, 3], 'so is a push into a nested array');
is(Context::Vars::_scope_kind(\&mutate), 0, 'a sub that only changes what the reference points at has no scope');

my $cap = Context::Vars->capture;
$ref->{a} = 'after capture';
is($cap->get('ref')->{a}, 'after capture', 'a capture holds the same reference, so it sees a later change through it');
is($cap->get('ref'), $original, 'it is the very same reference');

# To change a structure for one sub only, assign a changed copy.
sub change_a_copy { $ref = { %$ref, a => 'only here' }; return $ref->{a} }
is(change_a_copy(), 'only here', 'a changed copy, assigned, is read inside the sub');
is($ref->{a}, 'after capture', 'and the caller\'s structure is not touched');

# ---- autovivification ------------------------------------------------------
# Vivifying through an unset variable assigns it, by a way the compile pass
# does not see: the new reference lands in whatever context is current.
{
    my @seen;
    Context::Vars::_t_scope(sub {
        sub vivify { $other->{made} = 1; return }
        vivify();
        push @seen, ref $other;
    });
    is_deeply(\@seen, ['HASH'], 'vivifying an unset variable inside a sub is seen by its caller');
    ok(!defined $other, 'outside the context that was current, it is not set');
}

# ---- every kind of reference round-trips ------------------------------------
Context::Vars::_t_scope(sub {
    my $deep = { a => [1, { b => [2, 3] }], c => \'scalar', d => sub { 'code' } };
    $other = $deep;
    is($other, $deep, 'a nested structure comes back as the same reference');
    is_deeply($other->{a}, [1, { b => [2, 3] }], 'with its nesting');
    is(${ $other->{c} }, 'scalar', 'a scalar reference inside it');
    is($other->{d}->(), 'code', 'and a code reference');
    $other = \my @arr;
    push @$other, 'x';
    is_deeply(\@arr, ['x'], 'a reference to a lexical array writes through');
});

# ---- two contexts, two references ------------------------------------------
{
    my ($a_ctx, $b_ctx);
    sub take_a { $ref = { who => 'A' }; $a_ctx = Context::Vars->capture }
    sub take_b { $ref = { who => 'B' }; $b_ctx = Context::Vars->capture }
    take_a(); take_b();
    is($a_ctx->run(sub { $ref->{who} }), 'A', 'one context holds its hash');
    is($b_ctx->run(sub { $ref->{who} }), 'B', 'the other holds its own');
    is($ref, $original, 'and the top level holds the first one still');
}

is(Context::Vars::_depth(), 0, 'no context is left entered');

done_testing;
