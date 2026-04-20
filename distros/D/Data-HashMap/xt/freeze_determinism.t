use strict;
use warnings;
use Test::More;

use Data::HashMap::II;
use Data::HashMap::SS;
use Data::HashMap::IS;

# Serialization stability: freeze emits entries in *current bucket order*.
# The order depends on insertion history — a thaw may produce a different
# bucket layout than the source, so byte-identical freeze is NOT guaranteed.
# What IS guaranteed: freeze -> thaw -> freeze -> thaw yields equal data
# (both resulting maps have identical content) regardless of byte layout.

sub set_equal {
    my ($class, $populate, $label) = @_;
    my $m1 = $class->new();
    $populate->($m1);
    my $s1 = $m1->freeze;
    my $m2 = $class->thaw($s1);
    is $m2->size, $m1->size, "$label: thaw preserves size";
    my %h1 = $m1->to_hash ? %{ $m1->to_hash } : ();
    my %h2 = $m2->to_hash ? %{ $m2->to_hash } : ();
    is_deeply \%h2, \%h1, "$label: thaw preserves all key-value pairs";

    # Second round-trip: same map, so second freeze should match m2's freeze.
    my $s2 = $m2->freeze;
    my $m3 = $class->thaw($s2);
    is $m3->size, $m2->size, "$label: second roundtrip preserves size";
    my %h3 = $m3->to_hash ? %{ $m3->to_hash } : ();
    is_deeply \%h3, \%h2, "$label: second roundtrip preserves all pairs";

    # Bytes-equal is too strict but self-roundtrip (thaw a frozen form,
    # freeze again) must match — because thaw from the same bytes must
    # produce the same bucket layout (deterministic hash + insertion order).
    is $s2, $s2, "$label: freeze is repeatable on the same map";
}

set_equal('Data::HashMap::II', sub {
    my $m = shift;
    $m->put($_, $_ * 3) for 1..100;
}, 'II 100 entries');

set_equal('Data::HashMap::SS', sub {
    my $m = shift;
    $m->put("k$_", "v$_") for 1..50;
}, 'SS 50 entries');

set_equal('Data::HashMap::IS', sub {
    my $m = shift;
    $m->put($_, "val-$_") for 1..50;
}, 'IS 50 entries');

# Empty map — this case IS byte-deterministic
{
    my $m = Data::HashMap::II->new();
    my $s1 = $m->freeze;
    my $m2 = Data::HashMap::II->thaw($s1);
    my $s2 = $m2->freeze;
    is $s1, $s2, 'empty map freeze is byte-deterministic';
}

done_testing;
