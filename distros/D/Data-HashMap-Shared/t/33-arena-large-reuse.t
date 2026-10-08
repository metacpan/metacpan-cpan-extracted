use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Data::HashMap::Shared::IS;

# The >512 KiB free list must match sizes exactly: a first-fit larger block
# refiled at the smaller size would leak the surplus on every alternation.

my $dir = tempdir(CLEANUP => 1);
my $m = Data::HashMap::Shared::IS->new("$dir/arena.hm", 1000, 0, 0, 0, 64 * 1024 * 1024);

my $big   = "X" x (1_200 * 1024);   # rounds up to 2 MiB
my $small = "Y" x (700 * 1024);     # rounds up to 1 MiB

sub cycle { $m->put(1, $big); $m->remove(1); $m->put(2, $small); $m->remove(2) }

cycle() for 1 .. 3;
my $after_3 = $m->arena_used;

cycle() for 1 .. 15;
my $after_18 = $m->arena_used;

ok( $after_3 > 0, "arena in use after warm-up ($after_3 bytes)" );
is( $after_18, $after_3,
    'alternating large sizes reach a steady state -- no surplus lost per cycle' )
    or diag "grew from $after_3 to $after_18 bytes over 15 further cycles";

$m->put(3, $big);
is( length($m->get(3)), length($big), 'a large value still stores and reads back' );

done_testing;
