#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Context::Vars qw($v $w);

# Every way of reading a variable reads the current context, and every way
# of assigning one stores into it. All inside one entered context, so that
# nothing here touches the program's own.

sub count { Context::Vars::_t_count() }
sub held  { (Context::Vars::_t_fetch($_[0]))[0] }
sub has   { (Context::Vars::_t_fetch($_[0]))[1] ? 1 : 0 }
sub arg   { $_[0] }
sub alter { $_[0] = 'altered' }

Context::Vars::_t_scope(sub {
    ok(!defined $v, 'a variable nobody assigned reads undef');
    is(count(), 0, 'and reading it stores nothing');

    # ---- reads ----
    $v = 'abc';
    is(held('v'), 'abc', 'an assignment is in the context, under the name without its sigil');
    is($v, 'abc', 'a plain read');
    is("<$v>", '<abc>', 'interpolation');
    my $copy = $v;
    is($copy, 'abc', 'my $y = $x');
    is(arg($v), 'abc', 'passed as an argument');
    is(length($v), 3, 'a builtin');
    is(join('-', $v, $v), 'abc-abc', 'twice in a list');
    ok($v eq 'abc', 'string comparison');
    like($v, qr/^a.c$/, 'a match');
    my %h = ($v => 1);
    ok(exists $h{abc}, 'as a hash key');
    $v = 20;
    is($v + 1, 21, 'numeric use');
    ok($v == 20, 'numeric comparison');
    is((sort { $a <=> $b } 30, $v, 10)[1], 20, 'inside a sort');

    # ---- a read sees a change made behind the scalar ----
    Context::Vars::_t_store(v => 'changed underneath');
    is($v, 'changed underneath', 'every read fetches: a store that did not go through the scalar is seen');
    Context::Vars::_t_remove('v');
    ok(!defined $v, 'and so is a remove');

    # ---- assignments ----
    $v = 'x';      is(held('v'), 'x', 'scalar assignment');
    ($v, $w) = ('lv', 'lw');
    is(held('v') . held('w'), 'lvlw', 'list assignment');
    $v .= '!';     is(held('v'), 'lv!', '.=');
    $v = 5; $v += 2;   is(held('v'), 7, '+=');
    $v -= 1;           is(held('v'), 6, '-=');
    $v *= 3;           is(held('v'), 18, '*=');
    $v x= 2;           is(held('v'), '1818', 'x=');
    $v = 0;  $v ||= 'dflt';  is(held('v'), 'dflt', '||=');
    $v &&= 'and';      is(held('v'), 'and', '&&=');
    $v = undef; $v //= 'dd';  is(held('v'), 'dd', '//=');
    $v = 1; $v++;      is(held('v'), 2, 'post ++');
    ++$v;              is(held('v'), 3, 'pre ++');
    $v--;              is(held('v'), 2, '--');
    $v = "line\n"; chomp $v;   is(held('v'), 'line', 'chomp');
    chop $v;           is(held('v'), 'lin', 'chop');
    $v = 'aXb'; $v =~ s/X/-/;  is(held('v'), 'a-b', 's///');
    $v =~ tr/a-z/A-Z/; is(held('v'), 'A-B', 'tr///');
    substr($v, 0, 1) = 'Z';    is(held('v'), 'Z-B', 'an lvalue substr');
    $v = 'abc'; ($v) = $v =~ /(b)/;  is(held('v'), 'b', 'assignment from a match on itself');
    my $swap = 'other'; ($v, $swap) = ($swap, $v);
    is(held('v') . $swap, 'otherb', 'a swap');
    alter($v);         is(held('v'), 'altered', 'assignment through @_');
    for my $alias ($v) { $alias = 'via for' }
    is(held('v'), 'via for', 'assignment through a for alias');
    ${\$v} = 'via ref'; is(held('v'), 'via ref', 'assignment through a reference');
    my $r = \$v; $$r = 'via kept ref';
    is($v, 'via kept ref', 'a kept reference is a way to the variable, not to one value');
    $v = sprintf '%03d', 7;  is($v, '007', 'a string that looks like a number stays a string');
    read_into($v);     is(held('v'), 'read', 'a builtin that writes its argument');

    # ---- undef unsets ----
    $v = 'set'; $w = 'set';
    is(count(), 2, 'two names are set');
    $v = undef;
    is(count(), 1, 'assigning undef unsets the name: the count goes down');
    ok(!has('v'), 'and the name is not there');
    undef $w;
    is(count(), 0, 'undef $x does the same');
    $v = undef;
    is(count(), 0, 'unsetting a name that is not set changes nothing');
    $v = 0;   ok(has('v'), 'zero is a value');
    $v = '';  ok(has('v'), 'the empty string is a value');
    is(count(), 1, 'and each is stored');

    # ---- local ----
    $v = 'outer';
    {
        local $v = 'inner';
        is($v, 'inner', 'local: the block sees the local value');
        is(held('v'), 'inner', 'and it is in the context');
        is(Context::Vars::_locals(), 1, 'one value is displaced');
    }
    is($v, 'outer', 'local: the earlier value is back afterwards');
    is(Context::Vars::_locals(), 0, 'and nothing is left displaced');
    {
        local $v;
        ok(!defined $v, 'local with no value reads undef');
        ok(!has('v'), 'and unsets the name for the block');
    }
    is($v, 'outer', 'and puts it back');
    undef $v;
    {
        local $v = 'was unset';
        is($v, 'was unset', 'local on a name that was not set');
    }
    ok(!has('v'), 'leaves it not set afterwards');
    $v = 'outer';
    eval { local $v = 'dying'; die "x\n" };
    is($v, 'outer', 'local is undone by a die');
    { local $v = 'a'; { local $v = 'b'; is($v, 'b', 'nested local'); } is($v, 'a', 'unwinds one level'); }
    is($v, 'outer', 'then the other');
    is(Context::Vars::_locals(), 0, 'with nothing left displaced');

    # The end of a local must put back the CONTEXT's value. perl hands it the
    # scalar it saved, refreshed when the local began - but another package
    # holds that same scalar, and a read there during the block leaves the
    # local value in it.
    $v = 'outer';
    {
        local $v = 'local';
        is(RA::Other::look(), 'local', 'another package reads the local value during the block');
    }
    is($v, 'outer', 'the end of a local puts back the context\'s value, not what the scalar last held');
});

sub read_into { $_[0] = 'read' }

{ package RA::Other; use Context::Vars qw($v); sub look { $v } }

is(Context::Vars::_depth(), 0, 'nothing is left entered');
is(Context::Vars::_live_holders(), 0, 'and no holder is out');
ok(!Context::Vars::_has_program(), 'none of this touched the program\'s own context');

done_testing;
