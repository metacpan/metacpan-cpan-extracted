use lib './lib', '../lib', '../blib/arch/', 'blib/arch', '../', '.';
use Affix qw[:all];
use Test2::V0 -no_srand => 1;
use v5.36;

# Regression test for the pin-tree refcount cycle that leaked memory on every
# Affix::cast() of an aggregate. The rope.pl SDL3 demo grows ~5.4KB/iter
# whenever a mouse-move event is polled (every event runs Affix::cast()):
# the per-cast parse arena (4096B) plus ~290B per struct member was never
# reclaimed because member pins strongly referenced the freshly created parent
# HV/AV, forming an uncollectable cycle. Member pins now borrow the external
# lifeline instead, so free_v2_pin() runs on drop.
#
# Valgrind cannot see this (infix allocations route through Perl's allocator
# and the loss is a Perl SV cycle), so we assert flat RSS instead.
plan skip_all => '/proc/self/status is not available' unless -r '/proc/self/status';

sub rss_kb {
    open my $f, '<', '/proc/self/status' or die "open /proc/self/status: $!";
    my ($rss) = map { /^VmRSS:\s+(\d+)/ ? $1 : () } <$f>;
    close $f;
    return $rss;
}
typedef 'RopeCommonEvent' => Struct [ type => UInt32, timestamp => UInt64, windowID => UInt32 ];
my $buf = Affix::malloc(128);
my $ev  = Affix::cast( $buf, RopeCommonEvent() );
$ev->{type} = 0x400;
my $warmup = 10_000;
my $loops  = 200_000;
my $limit  = 100_000;    # kB of growth allowed (the bug leaked >1GB here)

# Warm the interpreter (op slabs, arenas, regexes) before taking a baseline.
my $warmed;
for my $i ( 1 .. $warmup ) { $warmed = Affix::cast( $buf, RopeCommonEvent() )->{type} }
my $base = rss_kb();
ok $warmed == 0x400, 'warmup casts read correctly';
for my $i ( 1 .. $loops ) {
    my $h = Affix::cast( $buf, RopeCommonEvent() );
    is( $h->{type}, 0x400, 'cast member read stays correct' ) if $i == $loops;
}
my $growth = rss_kb() - $base;
ok $growth < $limit, "RSS growth across $loops casts is $growth kB (limit ${limit} kB)";
done_testing;
