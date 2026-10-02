use strict;
use warnings;
use Test::More;
use Clone qw(clone);
use Scalar::Util qw(weaken isweak blessed refaddr);

# ---------------------------------------------------------------
# UTF-8 hash key preservation
#
# Clone.xs uses HeKUTF8() to detect UTF-8 keys and negates klen
# when calling hv_store (Perl API convention).  These tests verify
# that unicode keys survive the clone with correct flag and value.
# ---------------------------------------------------------------

{
    my $latin1 = "caf\xe9";         # latin-1 byte string
    my $wide   = "\x{65E5}\x{672C}"; # 日本 (kanji)
    my $mixed  = "abc\x{263A}def";   # ASCII + smiley

    my %orig = (
        $latin1 => 'latin1',
        $wide   => 'wide',
        $mixed  => 'mixed',
        ascii   => 'plain',
    );
    my $c = clone(\%orig);

    is($c->{$latin1}, 'latin1', 'UTF-8: latin-1 key value preserved');
    is($c->{$wide},   'wide',   'UTF-8: wide-char key value preserved');
    is($c->{$mixed},  'mixed',  'UTF-8: mixed key value preserved');
    is($c->{ascii},   'plain',  'UTF-8: ASCII key value preserved');

    # Verify the UTF-8 flag itself is preserved on keys.
    # Use value-based lookup to match keys across original and clone
    # (avoids wide characters in test descriptions).
    my %desc_for_val = (latin1 => 'latin-1', wide => 'kanji',
                        mixed => 'mixed', plain => 'ascii');
    for my $v (sort values %orig) {
        my ($ok) = grep { defined $orig{$_} && $orig{$_} eq $v } keys %orig;
        my ($cc) = grep { defined $c->{$_}  && $c->{$_}  eq $v } keys %$c;
        ok(defined $cc, "UTF-8: $desc_for_val{$v} key exists in clone");
        SKIP: {
            skip "key not found in clone", 1 unless defined $cc;
            is(utf8::is_utf8($cc), utf8::is_utf8($ok),
               "UTF-8: flag preserved for $desc_for_val{$v} key");
        }
    }

    # Independence: mutating clone keys should not affect original
    $c->{$wide} = 'changed';
    is($orig{$wide}, 'wide', 'UTF-8: clone mutation does not affect original');
}

# ---------------------------------------------------------------
# Regex (qr//) cloning with modifiers
#
# Clone.xs shares the REGEXP via SvREFCNT_inc (not deep-copied)
# and nulls the vtable for qr magic.  These tests verify that
# all standard modifiers survive the clone and remain functional.
# ---------------------------------------------------------------

{
    my @cases = (
        [qr/hello/,     'hello',        1, 'HELLO',        0, 'bare'],
        [qr/hello/i,    'HELLO',        1, undef,          0, '/i'],
        [qr/^world/m,   "foo\nworld",   1, "foo world",    0, '/m'],
        [qr/foo.bar/s,  "foo\nbar",     1, undef,          0, '/s'],
        [qr/ he llo /x, 'hello',        1, undef,          0, '/x'],
        [qr/hello/ims,  "FOO\nhello",   1, undef,          0, '/ims'],
    );

    for my $case (@cases) {
        my ($qr, $match_str, $should_match, $nomatch_str, $should_nomatch, $desc) = @$case;
        my $c = clone($qr);

        ok("$c" eq "$qr", "regex $desc: stringification preserved");
        if ($should_match) {
            ok($match_str =~ $c, "regex $desc: positive match works");
        }
        if (defined $nomatch_str) {
            ok($nomatch_str !~ $c, "regex $desc: negative match works");
        }
    }

    # Nested regex in data structure
    my $data = { pattern => qr/\d+/i, name => 'test' };
    my $dc = clone($data);
    ok('123' =~ $dc->{pattern}, 'regex in hash: match works');
    is($dc->{name}, 'test', 'regex in hash: sibling value preserved');
}

# ---------------------------------------------------------------
# Mixed-type hash values
#
# Exercises the full sv_clone type switch in a single structure.
# Verifies that each type is handled correctly and independently.
# ---------------------------------------------------------------

{
    my $code = sub { return 42 };
    my $qr   = qr/test/;
    my $data = {
        sv_null  => undef,
        sv_iv    => 42,
        sv_nv    => 3.14,
        sv_pv    => "hello",
        sv_rv    => \42,
        sv_av    => [1, 2, 3],
        sv_hv    => { a => 1 },
        sv_cv    => $code,
        sv_re    => $qr,
        nested   => { deep => [{ leaf => "value" }] },
    };

    my $c = clone($data);

    ok(!defined $c->{sv_null}, 'mixed: undef preserved');
    is($c->{sv_iv},    42,      'mixed: integer preserved');
    is($c->{sv_nv},    3.14,    'mixed: float preserved');
    is($c->{sv_pv},    "hello", 'mixed: string preserved');
    is(${$c->{sv_rv}}, 42,      'mixed: scalar ref preserved');
    is_deeply($c->{sv_av}, [1, 2, 3], 'mixed: array preserved');
    is_deeply($c->{sv_hv}, { a => 1 }, 'mixed: hash preserved');
    is(ref $c->{sv_cv}, 'CODE',  'mixed: code ref type preserved');
    is($c->{sv_cv}->(), 42,     'mixed: code ref works');
    ok('test' =~ $c->{sv_re},   'mixed: regex works');
    is($c->{nested}{deep}[0]{leaf}, "value", 'mixed: deep nesting preserved');

    # Code refs are shared (same ref), not deep-copied
    ok($c->{sv_cv} == $data->{sv_cv}, 'mixed: code ref is shared');

    # Containers are independent
    push @{$c->{sv_av}}, 4;
    is(scalar @{$data->{sv_av}}, 3, 'mixed: array independence');

    $c->{sv_hv}{b} = 2;
    ok(!exists $data->{sv_hv}{b}, 'mixed: hash independence');
}

# ---------------------------------------------------------------
# Large hash correctness (exercises hv_ksplit pre-sizing)
#
# Clone.xs pre-sizes the target HV with hv_ksplit(clone, HvKEYS(self))
# to avoid incremental resizing.  This test verifies correctness
# for non-trivial hash sizes with mixed key types.
# ---------------------------------------------------------------

{
    my %big;
    for my $i (1 .. 500) {
        $big{"ascii_$i"}         = $i;
        $big{"utf8_\x{263A}_$i"} = $i * 2;  # smiley key
    }
    is(scalar keys %big, 1000, 'large hash: original has 1000 keys');

    my $c = clone(\%big);
    is(scalar keys %$c, 1000, 'large hash: clone has 1000 keys');

    # Spot-check values
    is($c->{ascii_250},         250,  'large hash: ascii value correct');
    is($c->{"utf8_\x{263A}_250"}, 500, 'large hash: utf8 value correct');

    # Verify independence
    $c->{ascii_1} = 'changed';
    is($big{ascii_1}, 1, 'large hash: clone is independent');
}

# ---------------------------------------------------------------
# Nested blessed objects at multiple levels
#
# Verifies that sv_bless is correctly applied through multiple
# levels of reference traversal in the recursive clone path.
# ---------------------------------------------------------------

{
    package Outer;
    sub new { my ($class, $v) = @_; bless { inner => Inner->new($v) }, $class }

    package Inner;
    sub new { my ($class, $v) = @_; bless { val => $v }, $class }

    package BArray;
    sub new { my ($class, @v) = @_; bless [@v], $class }

    package BScalar;
    sub new { my ($class, $v) = @_; bless \$v, $class }

    package main;

    # Nested blessed hashrefs
    my $outer = Outer->new("test");
    my $co = clone($outer);
    is(blessed($co),          'Outer', 'blessed: outer class preserved');
    is(blessed($co->{inner}), 'Inner', 'blessed: inner class preserved');
    is($co->{inner}{val},     'test',  'blessed: deep value preserved');
    $co->{inner}{val} = 'changed';
    is($outer->{inner}{val},  'test',  'blessed: independence preserved');

    # Blessed arrayref
    my $ba = BArray->new(10, 20, 30);
    my $cba = clone($ba);
    is(blessed($cba), 'BArray', 'blessed array: class preserved');
    is_deeply($cba, [10, 20, 30], 'blessed array: values preserved');
    push @$cba, 40;
    is(scalar @$ba, 3, 'blessed array: independence');

    # Blessed scalar ref
    my $bs = BScalar->new(99);
    my $cbs = clone($bs);
    is(blessed($cbs), 'BScalar', 'blessed scalar: class preserved');
    is($$cbs, 99, 'blessed scalar: value preserved');
    $$cbs = 0;
    is($$bs, 99, 'blessed scalar: independence');

    # Re-blessed object (class changed)
    my $obj = bless {}, 'ClassA';
    bless $obj, 'ClassB';
    my $crb = clone($obj);
    is(blessed($crb), 'ClassB', 'rebless: final class preserved');
}

# ---------------------------------------------------------------
# Shared references within a structure
#
# When the same referent appears at multiple positions in a data
# structure, the clone should preserve that sharing: all positions
# in the clone should point to the same cloned referent.
# ---------------------------------------------------------------

{
    my $shared = { val => 'shared' };
    my $data = {
        first  => $shared,
        second => $shared,
        nested => [ $shared, { deep => $shared } ],
    };

    my $c = clone($data);

    # All positions should reference the same clone
    my $r1 = refaddr($c->{first});
    my $r2 = refaddr($c->{second});
    my $r3 = refaddr($c->{nested}[0]);
    my $r4 = refaddr($c->{nested}[1]{deep});

    ok($r1 == $r2, 'shared ref: first == second');
    ok($r2 == $r3, 'shared ref: second == nested[0]');
    ok($r3 == $r4, 'shared ref: nested[0] == nested.deep');

    # Clone referent should differ from original
    ok($r1 != refaddr($shared), 'shared ref: clone differs from original');

    # Independence
    $c->{first}{val} = 'changed';
    is($shared->{val}, 'shared', 'shared ref: original unaffected');
    is($c->{second}{val}, 'changed', 'shared ref: sharing preserved in clone');
}

# ---------------------------------------------------------------
# Weak + strong references to the same target
#
# Verifies deferred weakening: all strong refs are established
# before any weakening occurs. (fixes GH #15)
# ---------------------------------------------------------------

{
    my $target = { data => 'important' };
    my $container = {
        strong => $target,
        weak   => $target,
    };
    weaken($container->{weak});

    my $c = clone($container);

    ok(!isweak($c->{strong}), 'weakref: strong ref stays strong');
    ok(isweak($c->{weak}),    'weakref: weak ref stays weak');

    # Both should point to the same cloned target
    is(refaddr($c->{strong}), refaddr($c->{weak}),
       'weakref: strong and weak point to same clone');

    # Clone target differs from original
    isnt(refaddr($c->{strong}), refaddr($target),
         'weakref: clone target differs from original');
}

done_testing;
