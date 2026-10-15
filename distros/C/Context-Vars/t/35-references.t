#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Context::Vars qw($ref $other);

# A variable can hold a plain hash or array, at any depth, and all of it
# belongs to the context: a change at any level, made in a sub, is undone
# when the sub returns. (0.01 had the referent shared; 0.02 changed that.)
# Objects and code are kept as references and shared, as their classes
# expect.

$ref = { a => 1, list => [1, 2] };

# ---- replacing it is scoped ------------------------------------------------
sub replace_hash { $ref = { a => 2 }; return $ref->{a} }
is(replace_hash(), 2, 'a sub that assigns a new hash reads it');
is_deeply($ref, { a => 1, list => [1, 2] }, 'and when it returns the caller has its own again');

sub replace_array { $ref = [9, 8]; return "@$ref" }
is(replace_array(), '9 8', 'the same for an array');
is($ref->{a}, 1, 'and the caller has its own afterwards');

{
    local $ref = [3, 4];
    is_deeply($ref, [3, 4], 'local with an array');
}
is($ref->{a}, 1, 'and the caller\'s hash is back after the block');

# ---- changing it at any depth is scoped too ---------------------------------
my @inside;
sub mutate {
    $ref->{a} = 'changed';
    push @{ $ref->{list} }, 3;
    push @inside, $ref->{a}, scalar @{ $ref->{list} };
    return;
}
mutate();
is_deeply(\@inside, ['changed', 3], 'inside the sub its changes are read');
is($ref->{a}, 1, 'a change made at the first level is undone when the sub returns');
is_deeply($ref->{list}, [1, 2], 'and so is a push one level down');
ok(Context::Vars::_scope_kind(\&mutate), 'a sub that changes what the variable holds has a scope');

sub reads_deep { my $x = $ref->{list}[0]; scalar keys %$ref }
reads_deep();
is(Context::Vars::_scope_kind(\&reads_deep), 0, 'a sub that only reads deep has none');

# ---- a capture keeps its moment, at every level -------------------------------
my $cap = Context::Vars->capture;
sub change_after { $ref->{a} = 'later'; $cap->run(sub { $ref->{a} }) }
is(change_after(), 1, 'a capture does not see a later change, even one made through the same variable');
is_deeply($cap->get('ref'), { a => 1, list => [1, 2] }, 'get gives a plain copy of what it holds');

# ---- the copy idiom still works -----------------------------------------------
sub change_a_copy { $ref = { %$ref, a => 'only here' }; return $ref->{a} }
is(change_a_copy(), 'only here', 'assigning a changed copy is read inside');
is($ref->{a}, 1, 'and undone after');

# ---- a stored structure is the variable's own --------------------------------
Context::Vars::_t_scope(sub {
    my %src = (k => [1]);
    $other = \%src;
    push @{ $src{k} }, 2;
    is_deeply($other, { k => [1] }, 'changing the structure that was assigned does not change the variable');
    push @{ $other->{k} }, 3;
    is_deeply(\%src, { k => [1, 2] }, 'and changing the variable does not change the structure that was assigned');
});

# ---- objects and code are shared ---------------------------------------------
{
    my $obj = bless { n => 1 }, 'R::Obj';
    my $code = sub { 'code' };
    Context::Vars::_t_scope(sub {
        $other = { obj => $obj, code => $code, deep => [$obj] };
        is($other->{obj}, $obj, 'an object comes back as the same reference');
        is($other->{deep}[0], $obj, 'at any depth');
        is($other->{code}->(), 'code', 'code can be called');
        $other->{obj}{n} = 2;
        is($obj->{n}, 2, 'and an object\'s insides are shared, as with any reference');
    });
    my $destroyed = 0;
    { package R::Probe; sub DESTROY { $destroyed++ } }
    sub hold_object { $ref = { probe => bless({}, 'R::Probe') }; 1 }
    hold_object();
    is($destroyed, 1, 'an object only a returned sub\'s scope held is destroyed when it returns');
    is($ref->{a}, 1, 'and the caller still has its own hash');
}

# ---- autovivification -------------------------------------------------------
{
    sub vivify { $other->{made}{deeper} = 1; return ref $other }
    my $seen;
    Context::Vars::_t_scope(sub { $seen = vivify(); });
    is($seen, 'HASH', 'vivifying through an unset variable inside a sub reads as a hash there');
    my $after;
    Context::Vars::_t_scope(sub { vivify(); $after = $other; });
    ok(!defined $after, 'and, being a change made in that sub, it is undone when the sub returns');
    Context::Vars::_t_scope(sub {
        $other->{x}{y} = 'kept';
        is($other->{x}{y}, 'kept', 'vivifying two levels at once keeps the value');
    });
}

# ---- two contexts, two structures ---------------------------------------------
{
    my ($a_ctx, $b_ctx);
    sub take_a { $ref = { who => 'A' }; $a_ctx = Context::Vars->capture }
    sub take_b { $ref = { who => 'B' }; $b_ctx = Context::Vars->capture }
    take_a(); take_b();
    is($a_ctx->run(sub { $ref->{who} }), 'A', 'one context holds its hash');
    is($b_ctx->run(sub { $ref->{who} }), 'B', 'the other holds its own');
    is($ref->{a}, 1, 'and the top level its own');
}

is(Context::Vars::_depth(), 0, 'no context is left entered');

done_testing;
