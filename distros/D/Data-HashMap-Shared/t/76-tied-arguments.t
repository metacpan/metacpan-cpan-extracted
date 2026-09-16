use strict;
use warnings;
use Test::More;

use Data::HashMap::Shared::II;
use Data::HashMap::Shared::IS;
use Data::HashMap::Shared::SI;
use Data::HashMap::Shared::SS;
use Data::HashMap::Shared::I16;
use Data::HashMap::Shared::I32;
use Data::HashMap::Shared::I16S;
use Data::HashMap::Shared::I32S;
use Data::HashMap::Shared::SI16;
use Data::HashMap::Shared::SI32;

# A tied argument runs FETCH on every read.  get_multi must read each key once,
# since a second FETCH may return something else.  A call given one tied scalar
# in two string positions must copy the first string before reading the second.
# SameTie's FETCHes are all one length, into a scalar made to own its buffer
# (perl 5.42 shares a folded constant's, so the 4-arg substr un-shares it first),
# so each is written over the last and a kept pointer reads the later value;
# GrowTie's longer second FETCH frees the first buffer instead, which
# xt/valgrind.t, running this file, also sees.  Both go blind if the buffer is
# left shared, so the premise -- that the substr un-shares it -- is checked once.

use B ();

package CountTie { sub TIESCALAR { bless [$_[1], 0] } sub FETCH { $_[0][1]++; $_[0][0] } }
package CycleTie { sub TIESCALAR { my ($c, @v) = @_; bless [0, @v] } sub FETCH { my $s = shift; $s->[1 + $s->[0]++ % (@$s - 1)] } }
package SameTie  { sub TIESCALAR { my $n = 0; bless \$n } sub FETCH { my $s = shift; main::v($$s++) } }
package GrowTie  { sub TIESCALAR { my $n = 0; bless \$n } sub FETCH { my $s = shift; my $n = $$s++; "k$n" . ('x' x (8 + 4000 * $n)) } }
package main;

use File::Temp qw(tempdir);
my $shdir = tempdir(CLEANUP => 1);
sub v { 'k' . shift() . ('x' x 8) }
# A scalar that owns a private 64-byte buffer before it is tied, so a FETCH is
# copied into it rather than made to share the FETCH result's buffer.  The
# 4-arg substr un-shares the folded constant's buffer, which perl 5.42 shares.
sub tied_own { my $t = 'y' x 64; substr($t, 0, 1, 'y'); tie $t, shift; \$t }
sub same_tied { tied_own('SameTie') }

{   # the premise every SameTie/GrowTie case rests on: a build-visible copy is
    # only tested if a kept pointer can read the later FETCH, which needs a
    # private buffer.  Perl 5.42 shares a folded constant's; substr un-shares.
    my $t = 'y' x 64;
    substr($t, 0, 1, 'y');
    ok !(B::svref_2object(\$t)->FLAGS & B::SVf_IsCOW()),
        'tied_own premise: the substr leaves the buffer private, not shared copy-on-write';
}

for my $v (qw(II IS I16 I32 I16S I32S SS SI SI16 SI32)) {
    for my $sh (0, 1) {   # single map, then a 2-shard set: different read paths
        my $m = $sh
            ? "Data::HashMap::Shared::$v"->new_sharded("$shdir/$v", 2, 64)
            : "Data::HashMap::Shared::$v"->new(undef, 64);
        my @k = $v =~ /^S/ ? qw(a b) : (2, 3);
        $m->put($_, 7) for @k;
        tie my $t1, 'CountTie', $k[0];
        tie my $t2, 'CountTie', $k[1];
        my $tag = $sh ? 'sharded' : 'single';
        is_deeply [ $m->get_multi($t1, $t2) ], [7, 7], "$v/$tag: get_multi finds tied keys";
        is tied($t1)->[1] + tied($t2)->[1], 2, "$v/$tag:   ... reading each once";
    }
}

{
    my $m = Data::HashMap::Shared::II->new(undef, 64);
    $m->put(4, 40);
    tie my $c, 'CycleTie', 4, 99;
    is +($m->get_multi($c))[0], 40, 'get_multi looks a tied key up by the one value it read';
}

for my $meth (qw(put add get_or_set put_ttl add_ttl update update_ttl swap)) {
    my $m = Data::HashMap::Shared::SS->new(undef, 64, 0, 60);
    $m->put(v(0), 'old') if $meth =~ /^(?:update|swap)/;
    my $t = same_tied();
    $meth =~ /_ttl$/ ? $m->$meth($$t, $$t, 30) : $m->$meth($$t, $$t);
    is_deeply $m->to_hash, { v(0) => v(1) }, "SS $meth: one tied scalar as key and value stores what each read gave";
}

for my $sh (0, 1) {   # set_multi's key/value copy has a separate sharded branch
    my $m = $sh ? Data::HashMap::Shared::SS->new_sharded("$shdir/sm", 2, 64)
                : Data::HashMap::Shared::SS->new(undef, 64);
    my $t = same_tied();
    $m->set_multi($$t, $$t);
    is_deeply $m->to_hash, { v(1) => v(0) },
        'SS set_multi (' . ($sh ? 'sharded' : 'single') . '): ... reading the value first';
}

{
    my $m = Data::HashMap::Shared::SS->new(undef, 64);
    $m->put(v(0), v(1));
    my $t = same_tied();
    ok $m->cas($$t, $$t, $$t), 'SS cas: ... as key, expected and desired';
    is $m->get(v(0)), v(2), '  ... and stores the desired value';
}

{
    my $m = Data::HashMap::Shared::SS->new(undef, 64);
    $m->put(v(0), v(1));
    my $t = same_tied();
    ok $m->cas_take($$t, $$t), 'SS cas_take: ... as key and expected';
    is $m->size, 0, '  ... and takes the entry';
}

for my $c (qw(IS I16S I32S)) {
    my $m = "Data::HashMap::Shared::$c"->new(undef, 64);
    $m->put(5, v(0));
    my $t = same_tied();
    ok $m->cas(5, $$t, $$t), "$c cas: ... as expected and desired";
    is $m->get(5), v(1), '  ... and stores the desired value';
}

for my $meth (qw(add get_or_set)) {
    my $m = Data::HashMap::Shared::SS->new(undef, 64, 0, 0, 0, 1 << 16);
    my $t = tied_own('GrowTie');
    $m->$meth($$t, $$t);
    my ($k) = keys %{ $m->to_hash };
    ok defined $k && $k eq v(0), "SS $meth: a longer second FETCH does not lose the key read first";
}

done_testing;
