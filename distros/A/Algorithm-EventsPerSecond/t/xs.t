#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use lib 't/lib';
use AEPS_TestSuite;

if ( Algorithm::EventsPerSecond->backend ne 'XS' ) {
	plan skip_all => 'XS backend not available; pure Perl fallback covered by t/02';
}

my $simd = Algorithm::EventsPerSecond->simd;
ok( defined $simd && $simd =~ /^(AVX2|SSE4\.2|scalar)$/, "simd reports the compiled flavor ($simd)" );

# large counts survive the round trip through the int64_t buffers
my $meter = Algorithm::EventsPerSecond->new( window => 4 );
$meter->mark(2_000_000_000);
$meter->mark(2_000_000_000);
is( $meter->count, 4_000_000_000, 'counts beyond 32 bits are exact' );
is( $meter->total, 4_000_000_000, 'total beyond 32 bits is exact' );

# a copied buffer string (potential copy-on-write sharing) must not be
# affected when the meter writes into its ring buffer
my $snapshot = $meter->{buckets};
my $before   = unpack 'H*', $snapshot;
$meter->mark(123);
is( unpack( 'H*', $snapshot ), $before, 'marking does not modify copy-on-write snapshots of the buffer' );

# a corrupted (truncated) ring buffer must croak cleanly, not walk off
# the end of the string and segfault
{
	my $m = Algorithm::EventsPerSecond->new( window => 4 );
	$m->{buckets} = 'short';
	ok( !eval { $m->count; 1 }, 'truncated bucket buffer croaks on count' );
	like( $@, qr/ring buffer smaller than window/, 'count croak names the guard' );
	ok( !eval { $m->mark; 1 }, 'truncated bucket buffer croaks on mark' );

	my $m2 = Algorithm::EventsPerSecond->new( window => 4 );
	$m2->{stamps} = 'x';
	ok( !eval { $m2->count; 1 }, 'truncated stamp buffer croaks on count' );
	ok( !eval { $m2->mark;  1 }, 'truncated stamp buffer croaks on mark' );
}

done_testing();
